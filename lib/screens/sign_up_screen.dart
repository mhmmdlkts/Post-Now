import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postnow/services/sign_up_service.dart';

import 'maps_screen.dart';

class SignUpScreen extends StatefulWidget {
  final User _user;
  const SignUpScreen(this._user, {
    Key key
  }) : super(key: key);

  @override
  _SignUpScreen createState() => _SignUpScreen(_user);
}

class _SignUpScreen extends State<SignUpScreen> {
  final _signUpService = SignUpService();
  final GlobalKey _formKey = new GlobalKey();
  final _boxDecoration = BoxDecoration(
      color: Colors.white70,
      border: Border.all(width: 0.4, color: const Color(0x99000000)),
      borderRadius: BorderRadius.circular(4)
  );
  bool _isInputValid = false;
  User _user;
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
      body: Container(
          color: Color.fromARGB(255, 41, 171, 226),
          padding: EdgeInsets.all(20),
          child: _content()
      ),
      floatingActionButton: !_isInputValid? null : FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _onNextPressed,
        child: Icon(Icons.arrow_forward, color: Colors.blueAccent,),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _content() => Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 20),
                  width: MediaQuery.of(context).size.width*0.6,
                  child: FittedBox(
                      fit:BoxFit.fitWidth,
                      child: Text("APP_NAME".tr(),style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: _boxDecoration,
                  child: TextFormField(
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.person),
                      hintText: "SIGN_UP.NAME_FIELD_HINT".tr(),
                    ),
                    onChanged: (val) {
                      _name = val;
                      _checkIsValid();
                    },
                  ),
                ),
                Container(height: 10,),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: _boxDecoration,
                  child: TextFormField(
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.email),
                      hintText: "SIGN_UP.EMAIL_FIELD_HINT".tr(),
                    ),
                    onChanged: (val) {
                      _email = val;
                      _checkIsValid();
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      )
  );

  void _checkIsValid() {
    RegExp regExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    setState(() {
      _isInputValid = regExp.hasMatch(_email) && _name.length > 3;
    });
  }

  void _onNextPressed() async {
    if (!_isInputValid) {
      return;
    }
    await _user.updateProfile(displayName: _name);
    _user.reload();
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
      _signUpService.sendUserInfo(_user, _email);
    });
  }
}