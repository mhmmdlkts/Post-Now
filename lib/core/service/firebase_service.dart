import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/core/service/model/user.dart';
import 'package:postnow/ui/view/fire_home_view.dart';

import '../../main.dart';

class FirebaseService {

  static const String FIREBASE_URL = "https://post-now-f3c53.firebaseio.com/";

  Future<List<User>> getUsers() async {
    final response = await http.get("$FIREBASE_URL/users.json");
    switch (response.statusCode) {
      case HttpStatus.ok:
        final jsonUser = json.decode(response.body);
        final userList = jsonUser
            .map((e) => User.fromJson(e as Map<String,dynamic>))
            .toList().cast<User>();
        return userList;
      default:
        return Future.error(response.statusCode);
    }
  }

  handleAuth() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return FireHomeView();
        } else {
          return MyHomePage(title: 'Post Now');
        }
      },
    );
  }

  signOut() {
    FirebaseAuth.instance.signOut();
  }

  signIn(AuthCredential authCredential) {
    FirebaseAuth.instance.signInWithCredential(authCredential);
  }

  signInWithOTP(smsCode, verId) {
    AuthCredential authCredential = PhoneAuthProvider.getCredential(
        verificationId: verId, smsCode: smsCode);
    signIn(authCredential);
  }
}