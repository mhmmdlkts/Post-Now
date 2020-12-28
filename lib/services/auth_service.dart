import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/models/user.dart' as myUser;
import 'package:postnow/screens/first_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String phone;

  handleAuth(connectionState) {
    if (connectionState == ConnectionState.done) {
      return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
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
      myUser.User user = new myUser.User(token: token, phone: u.phoneNumber);
      FirebaseDatabase.instance.reference().child('users').child(u.uid).update(user.toJson());
    }

    Future<String> getToken() async {
      return await _firebaseMessaging.getToken();
    }

    void setMyToken(String uid) {
    print(uid);
      getToken().then((value) => {
        FirebaseDatabase.instance.reference().child('users').child(uid).child("token").set(value)
      });
    }

}