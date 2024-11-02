import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool isLoading = false; // Loading state

  Future<void> fetchGotFineData() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('GotFine').get();
      List<Map<String, dynamic>> data = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      setState(() {
        gotFineData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
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
            : gotFineData.isEmpty
            ? ElevatedButton(
          onPressed: () {
            fetchGotFineData(); // Load data
          },
          child: const Text("Press to Load GotFine Data"),
        )
            : ListView.builder(
          itemCount: gotFineData.length,
          itemBuilder: (context, index) {
            var item = gotFineData[index];
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
              trailing: item.containsKey('pdfUrl') && item['pdfUrl'].isNotEmpty
                  ? ElevatedButton(
                onPressed: () {
                  openPDF(item['pdfUrl']); // Open PDF link
                },
                child: const Text("View"),
              )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
