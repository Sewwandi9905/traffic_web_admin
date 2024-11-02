import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cleared_fines.dart'; // Import the new screen

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
  List<Map<String, dynamic>> filteredData = []; // For displaying filtered results
  bool isLoading = false; // Loading state
  final TextEditingController searchController = TextEditingController(); // Search controller

  Future<void> fetchGotFineData() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Fetch only the documents where cleared is false
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('GotFine')
          .where('cleared', isEqualTo: false) // Filtering by cleared field
          .get();

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        var docData = doc.data() as Map<String, dynamic>;
        docData['id'] = doc.id; // Include document ID for updates
        return docData;
      }).toList();

      setState(() {
        gotFineData = data;
        filteredData = data; // Initialize filtered data
        isLoading = false; // Stop loading
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching data: $e"),
      ));
    }
  }

  void filterData(String query) {
    if (query.isEmpty) {
      // If the search query is empty, show all data
      setState(() {
        filteredData = gotFineData;
      });
    } else {
      // Filter the data based on the search query
      setState(() {
        filteredData = gotFineData.where((item) {
          return (item['fullName'] ?? '').toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void openPDF(String url) async {
    // Check if the URL can be launched
    if (await canLaunch(url)) {
      await launch(url); // Launch the PDF URL
    } else {
      // If URL cannot be launched, show an error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not launch $url'),
      ));
    }
  }

  Future<void> clearFine(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('GotFine').doc(documentId).update({'cleared': true}); // Update cleared to true
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fine cleared successfully.'),
      ));
      fetchGotFineData(); // Refresh the data after clearing
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error clearing fine: $e"),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGotFineData(); // Fetch data on init
    searchController.addListener(() {
      filterData(searchController.text); // Filter data on search input change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outstanding Fines"),
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            fetchGotFineData();
          },
        ),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Show loading indicator
            : Column(
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
              child: filteredData.isEmpty
                  ? ElevatedButton(
                onPressed: () {
                  fetchGotFineData(); // Load data
                },
                child: const Text("Press to Load GotFine Data"),
              )
                  : ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  var item = filteredData[index];
                  String status = item.containsKey('pdfUrl')
                      ? (item['pdfUrl'].isNotEmpty ? "Paid" : "Not Paid")
                      : "Not Shown";

                  return ListTile(
                    title: Text(item['fullName'] ?? 'No Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vehicle No: ${item['vehicleNo'] ?? 'N/A'}"),
                        Text("Status: $status"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        item.containsKey('pdfUrl') && item['pdfUrl'].isNotEmpty
                            ? ElevatedButton(
                          onPressed: () {
                            openPDF(item['pdfUrl']); // Open PDF link
                          },
                          child: const Text("View"),
                        )
                            : Container(),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            clearFine(item['id']); // Clear the fine
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClearedFinesScreen()), // Navigate to cleared fines screen
              );
            },
            child: const Text("View Cleared Fines"),
          ),
        ),
      ),
    );
  }
}
