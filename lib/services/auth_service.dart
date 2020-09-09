import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/models/user.dart' as myUser;
import 'package:postnow/screens/first_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AuthService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String phone;

  handleAuth(connectionState) {
    if (connectionState == ConnectionState.done) {
      return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          print(snapshot.connectionState);
          if (snapshot.connectionState == ConnectionState.waiting)
            return SplashScreen();
          return FirstScreen(snapshot);
        },
      );
    }
    return SplashScreen();
  }

    signOut() {
      FirebaseAuth.instance.signOut();
    }

    Future<UserCredential> signIn(AuthCredential authCredential) async {
      UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(authCredential);
      sendUserInfo(authResult.user);
      return authResult;
    }

    Future<UserCredential> signInWithOTP(smsCode, verId) async {
      AuthCredential authCredential = PhoneAuthProvider.credential(
          verificationId: verId, smsCode: smsCode);
      return await signIn(authCredential);
    }


    sendUserInfo(User u) async {
      String token = await _firebaseMessaging.getToken();
      myUser.User user = new myUser.User(token: token, languageCode: ui.window.locale.languageCode, phone: u.phoneNumber);
      FirebaseDatabase.instance.reference().child('users').child(u.uid).update(user.toJson());
    }

}