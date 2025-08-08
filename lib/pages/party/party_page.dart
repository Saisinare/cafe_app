import 'package:flutter/material.dart';
import 'add_party_screen.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  List<Map<String, String>> parties = [];
  String searchQuery = "";
  String selectedFilter = "All";

  final List<String> filters = ["All", "Supplier", "Customer"];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredParties = parties.where((party) {
      final matchesSearch =
          party["name"]!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter =
          selectedFilter == "All" || party["type"] == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parties"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: selectedFilter,
              underline: const SizedBox(),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
              items: filters
                  .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                  .toList(),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search parties...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Party list
          Expanded(
            child: filteredParties.isEmpty
                ? const Center(child: Text("No parties found"))
                : ListView.builder(
                    itemCount: filteredParties.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(filteredParties[index]["name"]!),
                        subtitle: Text(filteredParties[index]["type"]!),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Add party button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newParty = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPartyScreen(),
            ),
          );
          if (newParty != null && newParty is Map<String, String>) {
            setState(() {
              parties.add(newParty);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
