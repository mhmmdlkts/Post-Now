import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postnow/services/sign_up_service.dart';

import 'maps_screen.dart';

class SignUpScreen extends StatefulWidget {
  final FirebaseUser _user;
  const SignUpScreen(this._user, {
    Key key
  }) : super(key: key);

  @override
  _SignUpScreen createState() => _SignUpScreen(_user);
}

class _SignUpScreen extends State<SignUpScreen> {
  final _signUpService = SignUpService();
  final GlobalKey _formKey = new GlobalKey();
  FirebaseUser _user;
  String _name, _email;

  _SignUpScreen(this._user);

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    if (_user.displayName != null)
      return GoogleMapsView(_user);
    return Scaffold(
      appBar: AppBar(
        title: Text("APP_NAME".tr()),
        brightness: Brightness.dark,
      ),
      body: Container(
          padding: EdgeInsets.all(20),
          child: _content()
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _user.updateProfile(displayName: _name);
          _user.reload();
          setState(() {
            _user = FirebaseAuth.instance.currentUser;
            _signUpService.sendUserInfo(_user, _email);
          });
        },
        child: Icon(Icons.arrow_forward, color: Colors.white,),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _content() => Center(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("APP_NAME".tr()),
            TextFormField(
              decoration: InputDecoration(
                icon: Icon(Icons.person),
                hintText: "SIGN_UP.NAME_FIELD_HINT".tr(),
              ),
              validator: (value) {
                if (value.length < 3) {
                  return "SIGN_UP.NAME_FIELD_VALIDATOR_ENTER_NAME".tr();
                }
                return null;
              },
              onChanged: (val) {
                _name = val;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                icon: Icon(Icons.email),
                hintText: "SIGN_UP.EMAIL_FIELD_HINT".tr(),
              ),
              validator: (value) {
                RegExp regExp = new RegExp(
                  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
                );
                if (!regExp.hasMatch(value)) {
                  return "SIGN_UP.EMAIL_FIELD_VALIDATOR_ENTER_NAME".tr();
                }
                return null;
              },
              onChanged: (val) {
                _email = val;
              },
            ),
          ],
        ),
      )
  );
}