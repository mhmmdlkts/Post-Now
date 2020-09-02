import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as i;

class ChatService {
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://post-now-f3c53.appspot.com');
  final _jobId;

  ChatService(this._jobId);
  Future<String> startUpload(imagePath) async {
    assert(!!imagePath);
    final dbImagePath = 'chat/images/$_jobId/${DateTime.now()}.png';
    final StorageUploadTask _uploadTask = _storage.ref().child(dbImagePath).putFile(i.File(imagePath));
    final snapshot = await _uploadTask.onComplete;
    return await snapshot.ref.getDownloadURL();
  }
}