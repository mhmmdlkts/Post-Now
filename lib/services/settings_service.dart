import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:postnow/models/global_settings.dart';

class SettingsService {
  final TextEditingController accountNameCtrl = TextEditingController(text: '');
  final TextEditingController accountPhoneCtrl = TextEditingController(text: '');
  final TextEditingController accountEmailCtrl = TextEditingController(text: '');
  final String uid;
  bool enableCustomAddress = false;
  GlobalSettings settings;
  DatabaseReference userRef;
  VoidCallback saved;

  SettingsService(this.uid, this.saved) {
    userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
  }

  toggleCustomAddress() {
    settings.enableCustomInvoiceAddress = !settings.enableCustomInvoiceAddress;
    commitSettings();
  }

  commitSettings() async {
    await userRef.child("settings").update(settings.toJson());
    saved.call();
  }

  Future<bool> existAddressInfo() async {
    final val = await userRef.child("settings").once();
    return GlobalSettings.fromSnapshot(val).existAddressInfo();
  }
}