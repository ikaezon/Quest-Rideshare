import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  Map<String, List<String>> _messagesMap = {};

  void addMessageForUser(String username, String message) {
    if (!_messagesMap.containsKey(username)) {
      _messagesMap[username] = [];
    }
    _messagesMap[username]!.add(message);
    notifyListeners();
  }

  List<String> messagesForUser(String username) {
    return _messagesMap.containsKey(username) ? _messagesMap[username]! : [];
  }
}
