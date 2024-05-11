import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    fetchDataFromFirestore();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Firestore Data Fetch")),
        body: Center(child: Text("Check your console for output.")),
      ),
    );
  }

  void fetchDataFromFirestore() async {
    FirebaseFirestore.instance
        .collection('conversations')
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        print("No conversations found!");
      } else {
        print("Fetched ${querySnapshot.docs.length} conversations:");
        for (var doc in querySnapshot.docs) {
          print("Document ID: ${doc.id}, Data: ${doc.data()}");
        }
      }
    }).catchError((error) {
      print("Error fetching conversations: $error");
    });
  }
}
