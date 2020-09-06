import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:postnow/screens/maps_screen.dart';
import 'package:easy_localization/easy_localization.dart';

import '../main.dart';
import '../screens/auth_screen.dart';

class FirebaseService {
  String phone;

  handleAuth(ValueChanged<bool> isInitialized) => StreamBuilder(
    stream: FirebaseAuth.instance.onAuthStateChanged,
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData) {
        /*if (phone)
          return SignUp(snapshot.data.uid, phone);
        else*/
          return GoogleMapsView(isInitialized, snapshot.data.uid);
      } else {
        return MyHomePage(isInitialized, title: "APP_NAME".tr());
      }
    },
  );

  signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<AuthResult> signIn(AuthCredential authCredential) async {
    return await FirebaseAuth.instance.signInWithCredential(authCredential);
  }

  Future<AuthResult> signInWithOTP(smsCode, verId) async {
    AuthCredential authCredential = PhoneAuthProvider.getCredential(
        verificationId: verId, smsCode: smsCode);
    return await signIn(authCredential);
  }
}