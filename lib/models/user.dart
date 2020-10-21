import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/global_settings.dart';

class User {
  String key;
  String name;
  String phone;
  String email;
  String token;
  GlobalSettings settings;

  User({this.name, this.phone, this.token, this.email}) {
    settings = GlobalSettings();
  }

  User.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    phone = snapshot.value["phone"];
    email = snapshot.value["email"];
    token = snapshot.value["token"];
    if (snapshot.value["settings"] != null)
      settings = GlobalSettings.fromJson(snapshot.value["settings"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (name != null) data['name'] = this.name;
    if (phone != null) data['phone'] = this.phone;
    if (email != null) data['email'] = this.email;
    if (token != null) data['token'] = this.token;
    if (settings != null) data['settings'] = this.settings.toJson();
    return data;
  }
}