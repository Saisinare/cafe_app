import 'package:flutter/material.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _currentStep = 0;
  List<String> items = ["Item A", "Item B", "Item C"];
  List<String> selectedItems = [];

  // Step 2 form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountReceivedController =
      TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool paymentReceived = false;
  String? paymentMode;
  String? billingTerm;
  DateTime? billDueDate;
  String? deliveryState;
  double discount = 0;
  double serviceCharge = 0;
  double totalAmount = 1000; // Example fixed value for now
  String? parcelMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales"),
        backgroundColor: Colors.blue,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 1) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Submit logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sales entry submitted!")),
            );
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          // Step 1 - Item Selection
          Step(
            title: const Text("Items"),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Items:"),
                ...items.map((item) {
                  return CheckboxListTile(
                    title: Text(item),
                    value: selectedItems.contains(item),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedItems.add(item);
                        } else {
                          selectedItems.remove(item);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 10),
                Text("Selected: ${selectedItems.join(", ")}"),
              ],
            ),
          ),

          // Step 2 - Customer & Billing Details
          Step(
            title: const Text("Details"),
            isActive: _currentStep >= 1,
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Customer/Supplier Name"),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone Number"),
                  ),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(labelText: "Date of Birth"),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Billing Address"),
                  ),

                  const SizedBox(height: 10),
                  const Text("Payment Mode"),
                  DropdownButton<String>(
                    value: paymentMode,
                    hint: const Text("Select Payment Mode"),
                    items: ["Bank", "Cash", "Check"]
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        paymentMode = val;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text("Payment Received"),
                    value: paymentReceived,
                    onChanged: (val) {
                      setState(() {
                        paymentReceived = val ?? false;
                      });
                    },
                  ),

                  if (!paymentReceived) ...[
                    DropdownButton<String>(
                      value: billingTerm,
                      hint: const Text("Billing Term"),
                      items: ["Net 0", "Net 1", "Net 7", "Net 30", "Net 90"]
                          .map((term) => DropdownMenuItem(
                                value: term,
                                child: Text(term),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          billingTerm = val;
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            billDueDate = picked;
                          });
                        }
                      },
                      child: Text(billDueDate == null
                          ? "Select Bill Due Date"
                          : "Due Date: ${billDueDate.toString().split(' ')[0]}"),
                    ),
                  ],

                  TextField(
                    decoration: const InputDecoration(labelText: "Delivery State"),
                    onChanged: (val) => deliveryState = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Cash Discount (%)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => discount = double.tryParse(val) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Service Charges"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => serviceCharge = double.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 10),
                  Text("Total Amount: ₹${(totalAmount - (totalAmount * discount / 100) + serviceCharge).toStringAsFixed(2)}"),
                  TextField(
                    controller: amountReceivedController,
                    decoration: const InputDecoration(labelText: "Amount Received"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: "Note"),
                  ),

                  const SizedBox(height: 10),
                  const Text("Item Mode"),
                  DropdownButton<String>(
                    value: parcelMode,
                    hint: const Text("Select Mode"),
                    items: ["Hold", "Parcel"]
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        parcelMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
