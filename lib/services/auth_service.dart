import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:postnow/models/user.dart';
import 'package:postnow/screens/auth_screen.dart';
import 'package:postnow/screens/maps_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/screens/sign_up_screen.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'dart:ui' as ui;

import '../main.dart';

class AuthService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String phone;

  handleAuth() => StreamBuilder(
    stream: FirebaseAuth.instance.onAuthStateChanged,
    builder: (BuildContext context, snapshot) {
      print(snapshot.connectionState);
      if (snapshot.connectionState == ConnectionState.waiting)
        return SplashScreen();
      if (snapshot.hasData) {
        FirebaseUser u = snapshot.data;
        print(u.displayName);
        if (snapshot.data.displayName == null)
          return SignUpScreen(snapshot.data);
        return GoogleMapsView(snapshot.data);
      } else {
        return AuthScreen();
      }
    },
  );

  signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<AuthResult> signIn(AuthCredential authCredential) async {
    AuthResult authResult = await FirebaseAuth.instance.signInWithCredential(authCredential);
    sendUserInfo(authResult.user);
    return authResult;
  }

  Future<AuthResult> signInWithOTP(smsCode, verId) async {
    AuthCredential authCredential = PhoneAuthProvider.getCredential(
        verificationId: verId, smsCode: smsCode);
    return await signIn(authCredential);
  }


  sendUserInfo(FirebaseUser u) async {
    String token = await _firebaseMessaging.getToken();
    User user = new User(token: token, languageCode: ui.window.locale.languageCode, phone: u.phoneNumber);
    FirebaseDatabase.instance.reference().child('users').child(u.uid).update(user.toJson());
  }
}