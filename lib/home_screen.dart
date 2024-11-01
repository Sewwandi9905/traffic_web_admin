import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Add action here (e.g., navigate to another page, fetch data, etc.)
            print("Button Pressed!");
          },
          child: const Text("Press Me"),
        ),
      ),
    );
  }
}
