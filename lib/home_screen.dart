import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cleared_fines.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Police Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> gotFineData = [];
  List<Map<String, dynamic>> filteredData = [];
  List<String> clearHistory = [];  // To store the last 3 cleared fine document IDs
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  Future<void> fetchGotFineData() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('GotFine')
          .where('cleared', isEqualTo: false)
          .get();

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        var docData = doc.data() as Map<String, dynamic>;
        docData['id'] = doc.id;
        return docData;
      }).toList();

      setState(() {
        gotFineData = data;
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
          ? gotFineData
          : gotFineData.where((item) {
        return (item['dlNo'] ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void openPDF(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not launch $url'),
      ));
    }
  }

  Future<void> clearFine(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('GotFine').doc(documentId).update({'cleared': true});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fine cleared successfully.'),
      ));

      // Add to the clear history, keeping only the last 3 entries
      setState(() {
        clearHistory.insert(0, documentId);
        if (clearHistory.length > 3) {
          clearHistory.removeLast();
        }
      });

      fetchGotFineData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error clearing fine: $e"),
      ));
    }
  }

  Future<void> undoClear() async {
    if (clearHistory.isNotEmpty) {
      String documentId = clearHistory.removeAt(0);
      try {
        await FirebaseFirestore.instance.collection('GotFine').doc(documentId).update({'cleared': false});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Last clear action undone.'),
        ));
        fetchGotFineData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error undoing clear action: $e"),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No actions to undo.'),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGotFineData();
    searchController.addListener(() {
      filterData(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outstanding Fines", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: undoClear,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchGotFineData,
          ),
        ],
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
                ? Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: fetchGotFineData,
                child: const Text("Press to Load GotFine Data"),
              ),
            )
                : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                var item = filteredData[index];
                String status = item.containsKey('pdfUrl') && item['pdfUrl'].isNotEmpty
                    ? "Paid"
                    : "Not Paid";

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
                        Text("DL No: ${item['dlNo'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54)),
                        Text("Status: $status", style: const TextStyle(color: Colors.lightBlueAccent)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.containsKey('pdfUrl') && item['pdfUrl'].isNotEmpty)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () {
                              openPDF(item['pdfUrl']);
                            },
                            child: const Text("View", style: TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                          ),
                          onPressed: () {
                            clearFine(item['id']);
                          },
                          child: const Text("Clear", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClearedFinesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "View Cleared Fines",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
