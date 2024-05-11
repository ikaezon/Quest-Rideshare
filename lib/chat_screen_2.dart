import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen2 extends StatefulWidget {
  final String otherUser;
  final String conversationId;

  ChatScreen2({Key? key, required this.otherUser, required this.conversationId})
      : super(key: key);

  @override
  _ChatScreen2State createState() => _ChatScreen2State();
}

class _ChatScreen2State extends State<ChatScreen2> {
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

  Future<void> sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      String currentUser = FirebaseAuth.instance.currentUser?.uid ?? "";
      String currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? "";

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser,
        'receiverId': widget.otherUser,
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
      appBar: AppBar(title: Text(widget.otherUser)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
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
                    var message = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isCurrentUser = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
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
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type your message here...",
                        hintStyle: TextStyle(color: Colors.grey),
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
