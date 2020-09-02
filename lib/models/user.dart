import 'package:firebase_database/firebase_database.dart';

class User {
  String key;
  String name;
  String phone;
  String token;

  User({this.name, this.phone, this.token});

  User.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    phone = snapshot.value["phone"];
    token = snapshot.value["token"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (name != null) data['name'] = this.name;
    if (phone != null) data['phone'] = this.phone;
    if (token != null) data['token'] = this.token;
    return data;
  }

  String getName() {
    return name == null? "Name" : name;
  }
}