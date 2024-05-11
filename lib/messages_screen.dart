import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen_2.dart'; // Ensure you have this import to navigate to ChatScreen

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUserID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No conversations found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var participants = List.from(doc['participants']);
              var otherUserID = participants.firstWhere((id) => id != currentUserID, orElse: () => null);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserID).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
                    return SizedBox.shrink(); // Don't display anything until user data is loaded
                  }
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  var username = userData['username'] ?? 'Unknown User';  // Assuming 'username' is stored in user documents

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(doc.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      if (messageSnapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox.shrink(); // Don't display anything until message data is loaded
                      }
                      var lastMessage = messageSnapshot.data!.docs.first;
                      var messageText = lastMessage['text'] ?? '';
                      return InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ChatScreen2(otherUser: username, conversationId: doc.id)
                          ));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28.0,
                                backgroundImage: NetworkImage(userData['profileImageUrl'] ?? ''), // Assuming profile image URL is stored in user documents
                              ),
                              SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    messageText,
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add functionality to start a new conversation
        },
        child: Icon(Icons.message),
      ),
    );
  }
}
