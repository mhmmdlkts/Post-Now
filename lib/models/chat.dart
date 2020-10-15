import 'package:firebase_database/firebase_database.dart';

import 'message.dart';

class Chat {
  String key;
  List<Message> messages = List();
  final bool _isDriverApp;
  int unreadMessages;

  Chat(this._isDriverApp);

  setChat(DataSnapshot snapshot) {
    unreadMessages = null;
    messages = List();
    key = snapshot.key;
    for (final msg_key in snapshot.value.keys)
      messages.add(Message.fromJson(snapshot.value[msg_key], key: msg_key));
    messages.sort(); // TODO slow
  }

  int getUnreadMessageCount() {
    if (unreadMessages != null)
      return unreadMessages;
    int count = 0;
    messages.forEach((element) {
      if (!element.read && _isDriverApp != element.from_driver)
        count++;
    });
    unreadMessages = count;
    return count;
  }

  clear() {
    messages.clear();
  }
}