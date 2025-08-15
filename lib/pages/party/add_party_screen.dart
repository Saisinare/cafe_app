import 'package:flutter/material.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, String> partyData = {
    "name": "",
    "phone": "",
    "email": "",
    "type": "",
    "address": "",
    "billingState": "",
    "billingPostal": "",
    "deliveryState": "",
    "deliveryPostal": "",
    "gstNo": "",
    "billingType": "",
    "dob": "",
  };

  final List<String> partyTypes = ["Customer", "Supplier", "Partner"];
  final List<String> billingTypes = ["Prepaid", "Postpaid", "Credit"];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6F4E37);
    const lightBg = Color(0xFFF5EFE6);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          "Add Party",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInputCard(
                icon: Icons.person,
                label: "Name",
                hint: "Enter full name",
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Please enter a name" : null,
                onSaved: (v) => partyData["name"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.phone,
                label: "Phone",
                hint: "Enter phone number",
                keyboard: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Please enter a phone number" : null,
                onSaved: (v) => partyData["phone"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.email,
                label: "Email",
                hint: "Enter email address",
                keyboard: TextInputType.emailAddress,
                onSaved: (v) => partyData["email"] = v!.trim(),
              ),
              _buildDropdownCard(
                icon: Icons.category,
                label: "Type",
                items: partyTypes,
                onChanged: (v) => partyData["type"] = v ?? "",
              ),
              _buildInputCard(
                icon: Icons.home,
                label: "Address",
                hint: "Enter address",
                maxLines: 2,
                onSaved: (v) => partyData["address"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.location_city,
                label: "Billing State",
                hint: "Enter billing state",
                onSaved: (v) => partyData["billingState"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.markunread_mailbox,
                label: "Billing Postal Code",
                hint: "Enter postal code",
                keyboard: TextInputType.number,
                onSaved: (v) => partyData["billingPostal"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.local_shipping,
                label: "Delivery State",
                hint: "Enter delivery state",
                onSaved: (v) => partyData["deliveryState"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.local_post_office,
                label: "Delivery Postal Code",
                hint: "Enter postal code",
                keyboard: TextInputType.number,
                onSaved: (v) => partyData["deliveryPostal"] = v!.trim(),
              ),
              _buildInputCard(
                icon: Icons.numbers,
                label: "GST No.",
                hint: "Enter GST number",
                onSaved: (v) => partyData["gstNo"] = v!.trim(),
              ),
              _buildDropdownCard(
                icon: Icons.payment,
                label: "Billing Type",
                items: billingTypes,
                onChanged: (v) => partyData["billingType"] = v ?? "",
              ),
              _buildInputCard(
                icon: Icons.cake,
                label: "Date of Birth",
                hint: "DD/MM/YYYY",
                keyboard: TextInputType.datetime,
                onSaved: (v) => partyData["dob"] = v!.trim(),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, Map<String, String>.from(partyData));
                  }
                },
                child: const Text(
                  "Save Party",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    required void Function(String?) onSaved,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6F4E37)),
            border: InputBorder.none,
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required IconData icon,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: const Color(0xFF6F4E37)),
            border: InputBorder.none,
          ),
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
