// check-receipt.dart
import 'package:flutter/material.dart';

class CheckReceipt extends StatelessWidget {
  const CheckReceipt({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Receipt"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Receipt Details",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // You can add more widgets here to display receipt details
            ElevatedButton(
              onPressed: () {
                // You can add logic here to go back or to another page
                Navigator.pop(context);
              },
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
