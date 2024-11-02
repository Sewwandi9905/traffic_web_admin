import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:traffic_web_admin/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String adminEmail = "";
  String adminPassword = "";

  allowAdminToLogin() async
  {
    SnackBar snackBar = const SnackBar(
      content: Text(
        "Please wait",
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      backgroundColor: Colors.blueGrey,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    User? currentAdmin;
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password:adminPassword,
    ).then((fAuth)
    {
      currentAdmin = fAuth.user;
    }).catchError((onError)
    {
      //display error
      final snackBar = SnackBar(
          content: Text(
            "Error Occured: " + onError.toString(),
            style: const TextStyle(
              fontSize: 36,
            ),
          ),
          backgroundColor: Colors.pinkAccent,
        duration: const Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    if(currentAdmin != null)
      {
        await FirebaseFirestore.instance
            .collection("Admin")
            .doc(currentAdmin!.uid)
            .get().then((snap)
        {
          if(snap.exists)
            {
              Navigator.push(context, MaterialPageRoute(builder: (c)=>const HomeScreen()));
            }
          else
            {
              SnackBar snackBar = const SnackBar(
                content: Text(
                  "No record found. You are not admin",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                backgroundColor: Colors.yellowAccent,
                duration: Duration(seconds: 5),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
        });
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * .5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //email text field
                  TextField(
                    onChanged: (value){
                      adminEmail = value;
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.white),

                  ),
                  //password field
                  TextField(
                    onChanged: (value){
                      adminPassword = value;
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.white),

                  ),

                  //button login
                  ElevatedButton(
                      onPressed: ()
                      {
                        allowAdminToLogin();
                      },
                      child: const Text(
                      "Login",
                      style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 2,
                      fontSize: 16,
                      ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
