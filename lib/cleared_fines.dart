import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClearedFinesScreen extends StatefulWidget {
  const ClearedFinesScreen({super.key});

  @override
  State<ClearedFinesScreen> createState() => _ClearedFinesScreenState();
}

class _ClearedFinesScreenState extends State<ClearedFinesScreen> {
  List<Map<String, dynamic>> clearedFineData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  Future<void> fetchClearedFineData() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('GotFine')
          .where('cleared', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        var docData = doc.data() as Map<String, dynamic>;
        docData['id'] = doc.id;
        return docData;
      }).toList();

      setState(() {
        clearedFineData = data;
        filteredData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching data: $e"),
      ));
    }
  }

  void filterData(String query) {
    setState(() {
      filteredData = query.isEmpty
          ? clearedFineData
          : clearedFineData.where((item) {
        return (item['dlNo'] ?? '').toLowerCase().contains(query.toLowerCase()); // Search by dlNo
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchClearedFineData();
    searchController.addListener(() {
      filterData(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleared Fines", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by DL No',
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: filteredData.isEmpty
                ? const Center(child: Text("No cleared fines found.", style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                var item = filteredData[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueGrey, Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(item['fullName'] ?? 'No Name', style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vehicle No: ${item['vehicleNo'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54)),
                        Text("DL No: ${item['dlNo'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54)), // Show dlNo
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey, // Set background to black
    );
  }
}
