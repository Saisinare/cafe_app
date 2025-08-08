import 'package:flutter/material.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = "";
  String phone = "";
  String email = "";
  String category = "Supplier";
  String address = "";
  String billingState = "";
  String billingPostal = "";
  String deliveryState = "";
  String deliveryPostal = "";
  String gstNo = "";
  String billingType = "Prepaid";
  DateTime? dob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Party")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Party Name
              TextFormField(
                decoration: const InputDecoration(labelText: "Party Name *"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
                onSaved: (value) => name = value!,
              ),
              // Phone Number
              TextFormField(
                decoration: const InputDecoration(labelText: "Phone Number *"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
                onSaved: (value) => phone = value!,
              ),
              // Email
              TextFormField(
                decoration: const InputDecoration(labelText: "Email ID *"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
                onSaved: (value) => email = value!,
              ),
              // Party Category
              DropdownButtonFormField<String>(
                value: category,
                items: ["Supplier", "Customer"]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => category = value!,
                decoration: const InputDecoration(labelText: "Party Category *"),
              ),
              // Address (Optional)
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "Address (Optional)"),
                onSaved: (value) => address = value ?? "",
              ),
              // Billing State
              TextFormField(
                decoration: const InputDecoration(labelText: "Billing State"),
                onSaved: (value) => billingState = value ?? "",
              ),
              // Billing Postal Code
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "Billing Postal Code"),
                onSaved: (value) => billingPostal = value ?? "",
              ),
              // Delivery State
              TextFormField(
                decoration: const InputDecoration(labelText: "Delivery State"),
                onSaved: (value) => deliveryState = value ?? "",
              ),
              // Delivery Postal Code
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "Delivery Postal Code"),
                onSaved: (value) => deliveryPostal = value ?? "",
              ),
              // GST No. (Optional)
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "GST No. (Optional)"),
                onSaved: (value) => gstNo = value ?? "",
              ),
              // Billing Type
              DropdownButtonFormField<String>(
                value: billingType,
                items: ["Prepaid", "Postpaid"]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => billingType = value!,
                decoration: const InputDecoration(labelText: "Billing Type *"),
              ),
              // Date of Birth
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dob == null
                          ? "Date of Birth: Not Selected"
                          : "Date of Birth: ${dob!.day}/${dob!.month}/${dob!.year}",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dob = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, {
                      "name": name,
                      "phone": phone,
                      "email": email,
                      "type": category,
                      "address": address,
                      "billingState": billingState,
                      "billingPostal": billingPostal,
                      "deliveryState": deliveryState,
                      "deliveryPostal": deliveryPostal,
                      "gstNo": gstNo,
                      "billingType": billingType,
                      "dob": dob != null ? dob!.toIso8601String() : ""
                    });
                  }
                },
                child: const Text("Add Party"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
