import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Import the LoginScreen

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String username = 'Loading...'; // Initialize as loading
  String email = 'Loading...';    // Initialize as loading

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? "No email available"; // Set email from Firebase Auth
      });

      // Assuming 'users' collection where user document ID is user.uid
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] as String; // Set username from Firestore
        });
      } else {
        setState(() {
          username = 'No username available'; // Fallback if no username found
        });
      }
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false, // Clear all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://media.istockphoto.com/id/1325882158/vector/red-gradient-background-vector-illustration-eps-10.jpg?s=612x612&w=0&k=20&c=Rv3b3J1gNSULW_obdbGvULQHszlQ_h80cw9XphZ-kbI=',
              ),
            ),
          ),
          ListTile(
            title: Text('Username'),
            subtitle: Text(username),
            leading: Icon(Icons.person_2),
          ),
          ListTile(
            title: Text('Email'),
            subtitle: Text(email),
            leading: Icon(Icons.email),
          ),
          ElevatedButton(
            child: Text('Sign Out'),
            onPressed: signOut,
          ),
        ],
      ),
    );
  }
}
