import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:postnow/models/chat.dart';
import 'dart:io' as i;

import 'package:postnow/models/message.dart';
import 'package:postnow/services/global_service.dart';

class ChatService {
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://post-now-f3c53.appspot.com');
  DatabaseReference _chatRef;

  Chat chat;
  final String _jobId;
  final VoidCallback _onNewMessage;
  bool _isDriverApp;
  var currentListener;

  ChatService(this._jobId, this._onNewMessage) {
    GlobalService.isDriverApp().then((value) => {
      _isDriverApp = value,
      chat = Chat(_isDriverApp),
      _chatRef = FirebaseDatabase.instance.reference().child('jobs_chat').child(_jobId),
      refreshMessages(),
    });
  }

  Future<void> refreshMessages() async {
    chat.clear();
    currentListener?.cancel();
    currentListener = _chatRef.onValue.listen(_newMessage);
  }

  Future<String> startUpload(imagePath) async {
    assert(!!imagePath);
    final dbImagePath = 'chat/images/$_jobId/${DateTime.now()}.png';
    final UploadTask _uploadTask = _storage.ref().child(dbImagePath).putFile(i.File(imagePath));
    return await _uploadTask.snapshot.ref.getDownloadURL();
  }

  int getUnreadMessageCount() {
    if (chat == null)
      return 0;
    return chat.getUnreadMessageCount();
  }

  void sendMessage(Message message) {
    _chatRef.push().set(message.toMap());
  }

  static sendMessageStatic(String jobId, Message message) {
    FirebaseDatabase.instance.reference().child('jobs_chat').child(jobId).push().set(message.toMap());
  }

  readMessage(int index) {
    Message msg = chat.messages[index];
    if (msg.from_driver != _isDriverApp){
      _chatRef.child(msg.key).update({"read": true});
    }
    return msg;
  }

  _newMessage(event) {
    chat.setChat(event.snapshot);
    _onNewMessage.call();
  }

  int messageCount() {
    if (chat == null)
      return 0;
    return chat.messages.length;
  }
}