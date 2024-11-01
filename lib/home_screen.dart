import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> gotFineData = [];

  Future<void> fetchGotFineData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('GotFine').get();
      List<Map<String, dynamic>> data = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      setState(() {
        gotFineData = data;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
      ),
      body: Center(
        child: gotFineData.isEmpty
            ? ElevatedButton(
          onPressed: () {
            fetchGotFineData();
          },
          child: const Text("Press to Load GotFine Data"),
        )
            : ListView.builder(
          itemCount: gotFineData.length,
          itemBuilder: (context, index) {
            var item = gotFineData[index];
            return ListTile(
              title: Text(item['fullName'] ?? 'No Name'),
              subtitle: Text("Vehicle No: ${item['vehicleNo']}"),
            );
          },
        ),
      ),
    );
  }
}
