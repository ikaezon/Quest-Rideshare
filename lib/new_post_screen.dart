import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _controller = TextEditingController();

  // Function to create a post in Firestore
  Future<void> createPost(String postContent) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("No user logged in."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Optionally fetch username from Firestore if it's not included in the user's profile
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String username = userDoc.exists ? userDoc['username'] : "Anonymous";  // Assuming 'username' field exists

    // Create the post
    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user.uid,
      'username': username,
      'text': postContent,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your post',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                createPost(_controller.text).then((_) {
                  Navigator.pop(context); // Close the screen after submitting the post
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create post: $error'))
                  );
                });
              }
            },
            child: Text('Submit'),
          )
        ],
      ),
    );
  }
}
