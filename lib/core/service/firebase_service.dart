import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:postnow/maps/google_maps_view.dart';

import '../../main.dart';

class FirebaseService {

  handleAuth() => StreamBuilder(
    stream: FirebaseAuth.instance.onAuthStateChanged,
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData) {
        return GoogleMapsView(snapshot.data.uid);
      } else {
        return MyHomePage(title: 'Post Now');
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