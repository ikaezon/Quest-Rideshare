import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // Import ChatScreen
import 'new_post_screen.dart';
import 'messages_screen.dart';
import 'account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _appBarTitles = ['Home', 'Messages', 'Account'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshPosts() async {
    setState(() {});
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Something went wrong');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _refreshPosts,
              child: ListView.separated(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      "${post['username']}",
                      style: TextStyle(fontWeight: FontWeight.bold), // Make username bold
                    ),
                    subtitle: Text("${post['text']}"), // Keep subtitle as text
                    onTap: () {
                      String currentUser = FirebaseAuth.instance.currentUser?.uid ?? "";
                      String currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? "";
                      String otherUser = post['username'];
                      String otherUserName = ""; // Get the other user's username from Firestore or other source


                      // Sort the user IDs alphabetically to ensure consistency
                      List<String> participantIds = [currentUser, otherUser]..sort();

                      // Concatenate user IDs to generate conversation ID
                      String conversationId = "${participantIds.join("_")}";

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userId: otherUser,
                            conversationId: conversationId,
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => Divider(),
                physics: AlwaysScrollableScrollPhysics(),
              ),
            );
          },
        );
      case 1:
        return MessagesScreen();
      case 2:
        return AccountScreen();
      default:
        return Center(child: Text('No page found for index $index'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: TextStyle(fontWeight: FontWeight.bold), // Make app bar title bold
        ),
      ),
      body: _buildPageContent(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewPostScreen()),
          ).then((_) => setState(() {})); // Forces a rebuild of the UI when coming back to refresh the state
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
