import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:postnow/models/user.dart' as myUser;

class SignUpService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  sendUserInfo(User u, email) async {
    String token = await _firebaseMessaging.getToken();
    myUser.User user = new myUser.User(name: u.displayName, phone: u.phoneNumber, email: email, token: token);
    FirebaseDatabase.instance.reference().child('users').child(u.uid).update(user.toJson());
  }
}