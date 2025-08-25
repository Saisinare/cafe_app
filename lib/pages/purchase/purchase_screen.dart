import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/purchase.dart';

class PurchaseScreen extends StatefulWidget {
	const PurchaseScreen({super.key});

	@override
	State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
	final _formKey = GlobalKey<FormState>();
	final TextEditingController _supplierController = TextEditingController();
	final TextEditingController _invoiceNoController = TextEditingController();
	final TextEditingController _amountPaidController = TextEditingController();
	final TextEditingController _discountController = TextEditingController(text: '0');
	final TextEditingController _taxController = TextEditingController(text: '0');
	final TextEditingController _shippingController = TextEditingController(text: '0');
	final TextEditingController _noteController = TextEditingController();

	DateTime _purchaseDate = DateTime.now();
	String? _paymentMode;
	bool _submitting = false;

	final List<PurchaseItem> _items = [];
	String _searchQuery = '';

	@override
	void dispose() {
		_supplierController.dispose();
		_invoiceNoController.dispose();
		_amountPaidController.dispose();
		_discountController.dispose();
		_taxController.dispose();
		_shippingController.dispose();
		_noteController.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _purchaseDate,
			firstDate: DateTime(2000),
			lastDate: DateTime(2100),
		);
		if (picked != null) {
			setState(() => _purchaseDate = picked);
		}
	}

	void _addItemDialog() {
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
			),
			builder: (ctx) {
				return Padding(
					padding: EdgeInsets.only(
						left: 16,
						right: 16,
						bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
						top: 16,
					),
					child: _ItemPicker(
						onAdd: (itemId, name, category, unitCost, qty) {
							final existingIndex = _items.indexWhere((i) => i.itemId == itemId);
							if (existingIndex != -1) {
								final existing = _items[existingIndex];
								final newQty = existing.quantity + qty;
								final newTotal = unitCost * newQty;
								setState(() {
									_items[existingIndex] = PurchaseItem(
										itemId: itemId,
										itemName: name,
										category: category,
										unitCost: unitCost,
										quantity: newQty,
										totalCost: newTotal,
									);
								});
							} else {
								setState(() {
									_items.add(PurchaseItem(
										itemId: itemId,
										itemName: name,
										category: category,
										unitCost: unitCost,
										quantity: qty,
										totalCost: unitCost * qty,
									));
								});
							}
							Navigator.pop(ctx);
						},
					),
				);
			},
		);
	}

	double get _subtotal => _items.fold(0, (sum, i) => sum + i.totalCost);
	double get _discountPct => double.tryParse(_discountController.text.trim()) ?? 0;
	double get _tax => double.tryParse(_taxController.text.trim()) ?? 0;
	double get _shipping => double.tryParse(_shippingController.text.trim()) ?? 0;
	double get _totalAmount => _subtotal - (_subtotal * (_discountPct / 100)) + _tax + _shipping;

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;
		if (_items.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Add at least one item')),
			);
			return;
		}
		if (_paymentMode == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select payment mode')),
			);
			return;
		}

		setState(() => _submitting = true);
		try {
			final order = PurchaseOrder(
				userId: FirebaseAuth.instance.currentUser!.uid,
				supplierName: _supplierController.text.trim(),
				invoiceNo: _invoiceNoController.text.trim(),
				purchaseDate: _purchaseDate,
				items: _items,
				subtotal: _subtotal,
				discount: _discountPct,
				tax: _tax,
				shipping: _shipping,
				totalAmount: _totalAmount,
				amountPaid: double.tryParse(_amountPaidController.text.trim()) ?? 0,
				paymentMode: _paymentMode!,
				note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
				createdAt: DateTime.now(),
				updatedAt: DateTime.now(),
			);

			await FirestoreService.instance.createPurchaseOrder(order);

			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Purchase saved successfully')),
			);
			Navigator.pop(context);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error: $e')),
			);
		} finally {
			if (mounted) setState(() => _submitting = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Purchase'),
				backgroundColor: const Color(0xFF6F4E37),
				foregroundColor: Colors.white,
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Expanded(
										child: TextFormField(
											controller: _invoiceNoController,
											decoration: const InputDecoration(
												labelText: 'Invoice No.',
												border: OutlineInputBorder(),
											),
											validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter invoice no.' : null,
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: InkWell(
											onTap: _pickDate,
											child: InputDecorator(
												decoration: const InputDecoration(
													labelText: 'Purchase Date',
													border: OutlineInputBorder(),
												),
												child: Row(
													mainAxisAlignment: MainAxisAlignment.spaceBetween,
													children: [
														Text(DateFormat('yyyy-MM-dd').format(_purchaseDate)),
														const Icon(Icons.calendar_today, size: 18),
													],
												),
											),
										),
									),
								],
							),
							const SizedBox(height: 12),

							TextFormField(
								controller: _supplierController,
								decoration: const InputDecoration(
									labelText: 'Supplier / Party Name',
									border: OutlineInputBorder(),
								),
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter supplier name' : null,
							),
							const SizedBox(height: 12),

							// Items section
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
									TextButton.icon(
										onPressed: _addItemDialog,
										icon: const Icon(Icons.add),
										label: const Text('Add Item'),
									),
								],
							),

							if (_items.isEmpty)
								const Text('No items added yet', style: TextStyle(color: Colors.grey))
							else
								Column(
									children: _items.asMap().entries.map((entry) {
										final index = entry.key;
										final item = entry.value;
										return Card(
											child: ListTile(
												title: Text(item.itemName),
												subtitle: Text('${item.category} • ₹${item.unitCost} × ${item.quantity}'),
												trailing: Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														IconButton(
															icon: const Icon(Icons.remove),
															onPressed: () {
																final newQty = item.quantity - 1;
																setState(() {
																	if (newQty <= 0) {
																		_items.removeAt(index);
																	} else {
																		_items[index] = PurchaseItem(
																			itemId: item.itemId,
																			itemName: item.itemName,
																			category: item.category,
																			unitCost: item.unitCost,
																			quantity: newQty,
																			totalCost: item.unitCost * newQty,
																		);
																	}
																});
															},
														),
														Text('${item.quantity}'),
														IconButton(
															icon: const Icon(Icons.add),
															onPressed: () {
																final newQty = item.quantity + 1;
																setState(() {
																	_items[index] = PurchaseItem(
																		itemId: item.itemId,
																		itemName: item.itemName,
																		category: item.category,
																		unitCost: item.unitCost,
																		quantity: newQty,
																		totalCost: item.unitCost * newQty,
																	);
																});
															},
														),
														IconButton(
															icon: const Icon(Icons.delete, color: Colors.red),
															onPressed: () {
																setState(() => _items.removeAt(index));
															},
														),
													],
												),
											),
										);
									}).toList(),
								),

							const SizedBox(height: 12),

							Row(
								children: [
									Expanded(
										child: TextFormField(
											controller: _discountController,
											decoration: const InputDecoration(
												labelText: 'Discount (%)',
												border: OutlineInputBorder(),
											),
											keyboardType: TextInputType.number,
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											controller: _taxController,
											decoration: const InputDecoration(
												labelText: 'Tax (₹)',
												border: OutlineInputBorder(),
											),
											keyboardType: TextInputType.number,
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											controller: _shippingController,
											decoration: const InputDecoration(
												labelText: 'Shipping (₹)',
												border: OutlineInputBorder(),
											),
											keyboardType: TextInputType.number,
										),
									),
							],
							),

							const SizedBox(height: 12),

							DropdownButtonFormField<String>(
								value: _paymentMode,
								decoration: const InputDecoration(
									labelText: 'Payment Mode *',
									border: OutlineInputBorder(),
								),
								items: const [
									DropdownMenuItem(value: 'Cash', child: Text('Cash')),
									DropdownMenuItem(value: 'Card', child: Text('Card')),
									DropdownMenuItem(value: 'UPI', child: Text('UPI')),
									DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
									DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
								],
								onChanged: (val) => setState(() => _paymentMode = val),
							),
							const SizedBox(height: 12),

							TextFormField(
								controller: _amountPaidController,
								decoration: const InputDecoration(
									labelText: 'Amount Paid (₹)',
									border: OutlineInputBorder(),
								),
								keyboardType: TextInputType.number,
							),
							const SizedBox(height: 12),

							TextFormField(
								controller: _noteController,
								decoration: const InputDecoration(
									labelText: 'Note (optional)',
									border: OutlineInputBorder(),
								),
								maxLines: 2,
							),

							const SizedBox(height: 16),

							Card(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
											const SizedBox(height: 12),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text('Subtotal'),
													Text('₹${_subtotal.toStringAsFixed(2)}'),
												],
											),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text('Discount'),
													Text('-₹${(_subtotal * (_discountPct / 100)).toStringAsFixed(2)}'),
												],
											),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text('Tax'),
													Text('+₹${_tax.toStringAsFixed(2)}'),
												],
											),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text('Shipping'),
													Text('+₹${_shipping.toStringAsFixed(2)}'),
												],
											),
											const Divider(),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
													Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
												],
											),
										],
									),
								),
							),

							const SizedBox(height: 20),

							SizedBox(
								width: double.infinity,
								height: 48,
								child: ElevatedButton.icon(
									onPressed: _submitting ? null : _submit,
									style: ElevatedButton.styleFrom(
										backgroundColor: const Color(0xFF6F4E37),
										foregroundColor: Colors.white,
									),
									icon: _submitting
										? const SizedBox(
											width: 20,
											height: 20,
											child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
										)
										: const Icon(Icons.save),
									label: const Text('Save Purchase'),
								),
							),
						],
					),
				),
			),
		);
	}
}

class _ItemPicker extends StatefulWidget {
	final void Function(String itemId, String name, String category, double unitCost, int quantity) onAdd;
	const _ItemPicker({required this.onAdd});

	@override
	State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
	String _query = '';
	double _unitCost = 0;
	int _quantity = 1;

	@override
	Widget build(BuildContext context) {
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				TextField(
					decoration: const InputDecoration(
						hintText: 'Search items by name or category...',
						prefixIcon: Icon(Icons.search),
						border: OutlineInputBorder(),
					),
					onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
				),
				const SizedBox(height: 12),
				SizedBox(
					height: 220,
					child: StreamBuilder<List<Map<String, String>>>(
						stream: FirestoreService.instance.streamItems(),
						builder: (context, snapshot) {
							if (!snapshot.hasData) {
								return const Center(child: CircularProgressIndicator());
							}
							final items = (snapshot.data ?? []).where((item) {
								final name = (item['name'] ?? '').toLowerCase();
								final category = (item['category'] ?? '').toLowerCase();
								return _query.isEmpty || name.contains(_query) || category.contains(_query);
							}).toList();
							if (items.isEmpty) {
								return const Center(child: Text('No items found'));
							}
							return ListView.builder(
								itemCount: items.length,
								itemBuilder: (context, index) {
									final item = items[index];
									return ListTile(
										title: Text(item['name'] ?? ''),
										subtitle: Text(item['category'] ?? ''),
										onTap: () {
											_showConfigureDialog(item);
										},
									);
								},
							);
					},
					),
				),
			],
		);
	}

	void _showConfigureDialog(Map<String, String> item) {
		showDialog(
			context: context,
			builder: (ctx) {
				return AlertDialog(
					title: Text(item['name'] ?? ''),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							TextField(
								decoration: const InputDecoration(labelText: 'Unit Cost (₹)'),
								keyboardType: TextInputType.number,
								onChanged: (v) => _unitCost = double.tryParse(v.trim()) ?? 0,
							),
							TextField(
								decoration: const InputDecoration(labelText: 'Quantity'),
								keyboardType: TextInputType.number,
								onChanged: (v) => _quantity = int.tryParse(v.trim()) ?? 1,
							),
						],
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(ctx),
							child: const Text('Cancel'),
						),
						TextButton(
							onPressed: () {
								if (_unitCost <= 0 || _quantity <= 0) return;
								widget.onAdd(
									item['id'] ?? '',
									item['name'] ?? '',
									item['category'] ?? '',
									_unitCost,
									_quantity,
								);
								Navigator.pop(ctx);
							},
							child: const Text('Add'),
						),
					],
				);
			},
		);
	}
} 