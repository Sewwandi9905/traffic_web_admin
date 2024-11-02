import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClearedFinesScreen extends StatefulWidget {
  const ClearedFinesScreen({Key? key}) : super(key: key);

  @override
  _ClearedFinesScreenState createState() => _ClearedFinesScreenState();
}

class _ClearedFinesScreenState extends State<ClearedFinesScreen> {
  final TextEditingController searchController = TextEditingController(); // Search controller
  List<Map<String, dynamic>> clearedFines = []; // List to hold cleared fines
  List<Map<String, dynamic>> filteredFines = []; // List to hold filtered fines

  Future<void> fetchClearedFines() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('GotFine')
          .where('cleared', isEqualTo: true) // Filter for cleared fines
          .get();

      clearedFines = snapshot.docs.map((doc) {
        var docData = doc.data() as Map<String, dynamic>;
        docData['id'] = doc.id; // Include document ID for reference
        return docData;
      }).toList();
      filteredFines = clearedFines; // Initialize filtered fines
    } catch (e) {
      throw Exception("Error fetching cleared fines: $e");
    }
  }

  void filterFines(String query) {
    if (query.isEmpty) {
      // If the search query is empty, show all cleared fines
      setState(() {
        filteredFines = clearedFines;
      });
    } else {
      // Filter the fines based on the search query
      setState(() {
        filteredFines = clearedFines.where((item) {
          return (item['fullName'] ?? '').toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClearedFines().then((_) {
      setState(() {
        filteredFines = clearedFines; // Set the filtered fines after fetching
      });
    });
    searchController.addListener(() {
      filterFines(searchController.text); // Filter fines on input change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleared Fines"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filteredFines.isEmpty
                ? Center(child: Text("No cleared fines found."))
                : ListView.builder(
              itemCount: filteredFines.length,
              itemBuilder: (context, index) {
                var item = filteredFines[index];
                return ListTile(
                  title: Text(item['fullName'] ?? 'No Name'),
                  subtitle: Text("Vehicle No: ${item['vehicleNo'] ?? 'N/A'}"),
                  trailing: const Text("Status: Cleared"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
