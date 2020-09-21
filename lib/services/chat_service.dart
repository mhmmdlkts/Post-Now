import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as i;

import 'package:postnow/models/message.dart';

class ChatService {
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://post-now-f3c53.appspot.com');
  DatabaseReference _chatRef;
  List<Message> messages = [];
  final String _jobId;
  final VoidCallback _onNewMessage;

  ChatService(this._jobId, this._onNewMessage) {
    _chatRef = FirebaseDatabase.instance.reference().child('jobs_chat').child(_jobId);
    _chatRef.onChildAdded.listen(_newMessage);
  }

  Future<String> startUpload(imagePath) async {
    assert(!!imagePath);
    final dbImagePath = 'chat/images/$_jobId/${DateTime.now()}.png';
    final StorageUploadTask _uploadTask = _storage.ref().child(dbImagePath).putFile(i.File(imagePath));
    final snapshot = await _uploadTask.onComplete;
    return await snapshot.ref.getDownloadURL();
  }

  int getUnreadMessageCount() {
    int count = 0;
    messages.forEach((element) {
      if (!element.read)
        count++;
    });
    return count;
  }

  void sendMessage(Message message) {
    _chatRef.push().set(message.toMap());
  }

  _newMessage(event) {
    Message message = Message.fromSnapshot(event.snapshot);
    messages.add(message);
    _onNewMessage.call();
  }
}