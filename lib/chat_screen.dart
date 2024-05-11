import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String conversationId;

  ChatScreen({Key? key, required this.userId, required this.conversationId})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> _getUserDocument(String username) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get()
        .then((querySnapshot) => querySnapshot.docs.first);
  }

  Future<void> sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      String currentUser = FirebaseAuth.instance.currentUser?.uid ?? "";
      String currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? "";

      DocumentSnapshot userDocument = await _getUserDocument(widget.userId);
      if (!userDocument.exists) {
        print('User with username ${widget.userId} not found.');
        return; // Abort sending message if user not found
      }
      String otherUser = userDocument.id;

      // Sort the user IDs alphabetically to ensure consistency
      List<String> participantIds = [currentUser, otherUser]..sort();

      // Concatenate user IDs to generate conversation ID
      String conversationId = "${participantIds.join("_")}";

      // Ensure the conversation document exists
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
        'created_at': FieldValue.serverTimestamp(), // Setting a field to ensure the document exists
        'participants': participantIds, // Optionally store participant IDs for further reference
        'last_message': messageText, // Optionally track the last message
        'last_message_time': FieldValue.serverTimestamp() // Optionally track the last message time
      }, SetOptions(merge: true)); // Merge true to not overwrite existing data

      // Add the new message to the 'messages' subcollection
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser,
        'receiverId': otherUser,
        'senderUsername': currentUserName,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userId}")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: _getUserDocument(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text("User not found."));
                }
                String otherUser = snapshot.data!.id;
                String currentUser = FirebaseAuth.instance.currentUser?.uid ?? "";

                // Sort the user IDs alphabetically to ensure consistency
                List<String> participantIds = [currentUser, otherUser]..sort();

                // Concatenate user IDs to generate conversation ID
                String conversationId = "${participantIds.join("_")}";

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No messages yet."));
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var message =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        bool isCurrentUser = message['senderId'] == currentUser;
                        return Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Text(
                              message['text'],
                              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background color
                      borderRadius: BorderRadius.circular(20.0), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.black), // Set text color to black
                      decoration: InputDecoration(
                        border: InputBorder.none, // Remove the border
                        hintText: "Type your message here...",
                        hintStyle: TextStyle(color: Colors.grey), // Set hint text color
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
