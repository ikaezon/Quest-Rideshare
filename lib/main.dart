import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'message_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
    fetchDataFromFirestore();  // Call to fetch data right after initialization
  } catch (e) {
    print("Firebase Error: $e"); // Print the error message
    print("Firebase Error Details: ${e.toString()}"); // Print detailed error information
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => MessageProvider(),
      child: MyApp(),
    ),
  );
}

void fetchDataFromFirestore() {
  FirebaseFirestore.instance
      .collection('conversations')
      .get()
      .then((QuerySnapshot conversationSnapshot) {
    if (conversationSnapshot.docs.isEmpty) {
      print("No conversations found.");
    } else {
      print("Fetched ${conversationSnapshot.docs.length} conversations:");
      for (var conversationDoc in conversationSnapshot.docs) {
        print("Conversation ID: ${conversationDoc.id}, Data: ${conversationDoc.data()}");
        // Now fetch messages from each conversation's subcollection
        conversationDoc.reference
            .collection('messages')
            .get()
            .then((QuerySnapshot messageSnapshot) {
          if (messageSnapshot.docs.isEmpty) {
            print("No messages found in conversation ${conversationDoc.id}.");
          } else {
            print("Fetched ${messageSnapshot.docs.length} messages from conversation ${conversationDoc.id}:");
            for (var messageDoc in messageSnapshot.docs) {
              print("Message ID: ${messageDoc.id}, Data: ${messageDoc.data()}");
            }
          }
        }).catchError((error) {
          print("Error fetching messages for conversation ${conversationDoc.id}: $error");
        });
      }
    }
  }).catchError((error) {
    print("Error fetching conversations: $error");
  });
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rideshare App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
      ),
      home: LoginScreen(),
    );
  }
}
