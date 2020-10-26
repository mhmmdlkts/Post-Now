import 'package:cloud_firestore/cloud_firestore.dart' as cloud;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:package_info/package_info.dart';

import 'global_service.dart';

class ContactFormService {
  final cloud.Query query = cloud.FirebaseFirestore.instance.collection('contact');
  final batch = cloud.FirebaseFirestore.instance.batch();
  final cloud.FirebaseFirestore _firestore = cloud.FirebaseFirestore.instance;
  final User user;
  String phone;
  String email;
  String packageName;

  ContactFormService(this.user);

  Future<void> init() async {
    packageName = (await PackageInfo.fromPlatform()).packageName;
    await FirebaseDatabase.instance.reference().child(packageName==POSTNOW_PACKAGE_NAME?'users':'drivers').child(user.uid).once().then((DataSnapshot snapshot){
      phone = snapshot.value["phone"];
      email = snapshot.value["email"];
    });
  }

  Future<void> createRequest({name, email, phone, subject, content, jobId}) async {
    final cloud.DocumentReference postRef = _firestore.collection('contact').doc();
    cloud.WriteBatch writeBatch = _firestore.batch();

    writeBatch.set(postRef, {
      'uid' : user.uid,
      'app_package' : packageName,
      'name' : name,
      'email' : email,
      'phone' : phone,
      'time' : DateTime.now(),
      'jobId' : jobId,
      'subject' : subject,
      'content' : content,
    });
    await writeBatch.commit();
    await Future.delayed(Duration(milliseconds: 300));
  }
}