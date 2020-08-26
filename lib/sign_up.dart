import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class SignUp extends StatefulWidget {
  final String uid, phone;
  SignUp(this.uid, this.phone);

  @override
  _SignUp createState() => _SignUp(uid, phone);
}

class _SignUp extends State<SignUp> {
  final String uid, phone;

  _SignUp(this.uid, this.phone);

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: Text("APP_NAME".tr(), style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
        brightness: Brightness.dark,
      ),
      body: Column(
        children: <Widget>[

        ],
      ),
    );
  }
}
