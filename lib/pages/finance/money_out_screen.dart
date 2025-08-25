import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/money_out.dart';

class MoneyOutScreen extends StatefulWidget {
	const MoneyOutScreen({super.key});

	@override
	State<MoneyOutScreen> createState() => _MoneyOutScreenState();
}

class _MoneyOutScreenState extends State<MoneyOutScreen> {
	final _formKey = GlobalKey<FormState>();
	final TextEditingController _receiptNoController = TextEditingController();
	final TextEditingController _partyNameController = TextEditingController();
	final TextEditingController _amountPaidController = TextEditingController();
	final TextEditingController _noteController = TextEditingController();
	DateTime _moneyOutDate = DateTime.now();
	String? _paymentMode;
	bool _submitting = false;

	@override
	void dispose() {
		_receiptNoController.dispose();
		_partyNameController.dispose();
		_amountPaidController.dispose();
		_noteController.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _moneyOutDate,
			firstDate: DateTime(2000),
			lastDate: DateTime(2100),
		);
		if (picked != null) {
			setState(() => _moneyOutDate = picked);
		}
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;
		if (_paymentMode == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select payment mode')),
			);
			return;
		}

		setState(() => _submitting = true);
		try {
			final entry = MoneyOutEntry(
				id: null,
				userId: '', // set by service
				receiptNo: _receiptNoController.text.trim(),
				moneyOutDate: _moneyOutDate,
				partyName: _partyNameController.text.trim(),
				amountPaid: double.tryParse(_amountPaidController.text.trim()) ?? 0,
				paymentMode: _paymentMode!,
				note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
				createdAt: DateTime.now(),
				updatedAt: DateTime.now(),
			);

			await FirestoreService.instance.createMoneyOutEntry(entry);

			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Money Out recorded successfully')),
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
				title: const Text('Money Out'),
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
							TextFormField(
								controller: _receiptNoController,
								decoration: const InputDecoration(
									labelText: 'Receipt No.',
									border: OutlineInputBorder(),
								),
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter receipt number' : null,
							),
							const SizedBox(height: 12),

							InkWell(
								onTap: _pickDate,
								child: InputDecorator(
									decoration: const InputDecoration(
										labelText: 'Money Out Date',
										border: OutlineInputBorder(),
									),
									child: Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Text(DateFormat('yyyy-MM-dd').format(_moneyOutDate)),
											const Icon(Icons.calendar_today, size: 18),
										],
									),
								),
							),
							const SizedBox(height: 12),

							TextFormField(
								controller: _partyNameController,
								decoration: const InputDecoration(
									labelText: 'Customer / Supplier Name',
									border: OutlineInputBorder(),
								),
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
							),
							const SizedBox(height: 12),

							TextFormField(
								controller: _amountPaidController,
								decoration: const InputDecoration(
									labelText: 'Amount Paid (₹)',
									border: OutlineInputBorder(),
								),
								keyboardType: TextInputType.number,
								validator: (v) {
									final value = double.tryParse(v?.trim() ?? '');
									if (value == null || value <= 0) return 'Enter valid amount';
									return null;
								},
							),
							const SizedBox(height: 12),

							DropdownButtonFormField<String>(
								value: _paymentMode,
								decoration: const InputDecoration(
									labelText: 'Mode of Payment',
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
								controller: _noteController,
								decoration: const InputDecoration(
									labelText: 'Note (optional)',
									border: OutlineInputBorder(),
								),
								maxLines: 2,
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
									label: const Text('Save'),
								),
							),
						],
					),
				),
			),
		);
	}
} 