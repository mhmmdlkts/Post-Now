import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/services/legal_service.dart';
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
      color: Colors.black12,
      borderRadius: BorderRadius.circular(30)
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
      return MapsScreen(_user);
    return Scaffold(
      body: Container(
          color: primaryBlue,
          child: _content()
      ),
    );
  }

  Widget _content() => Stack(
    children: [
      Positioned(
        top: 100,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/postnow_icon.png", width: MediaQuery.of(context).size.width*0.4,),
            Container(
              width: MediaQuery.of(context).size.width*0.6,
              child: FittedBox(
                  fit:BoxFit.fitWidth,
                  child: Text("APP_NAME".tr(),style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ),
          ],
        ),
      ),
      Positioned(
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(padding: EdgeInsets.all(20), child: Text("Get Start...", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),),),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 5, blurRadius: 10)]
                ),
                padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 5),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SIGN_UP.TITLE".tr(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
                    Text("SIGN_UP.SUBTITLE".tr(), style: TextStyle(color: Colors.black54),),
                    Container(height: 30,),
                    Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("SIGN_UP.NAME_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                            Container(height: 10,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: _boxDecoration,
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
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
                            Container(height: 20,),
                            Text("SIGN_UP.EMAIL_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                            Container(height: 10,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
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
                            Container(height: 15,),
                            ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                ButtonTheme(
                                  height: 56,
                                  child: RaisedButton (
                                    color: primaryBlue,
                                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                                    child: Text("SIGN_UP.CONTINUE_BUTTON".tr(), style: TextStyle(color: Colors.white),),
                                    onPressed: !_isInputValid? null:_onNextPressed,
                                  ),
                                ),
                              ],
                            ),
                            Container(height: 15,),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: double.infinity),
                              child: FlatButton(
                                  onPressed: () async {
                                    LegalService.openPrivacyPolicy();
                                  },
                                  child: Text(
                                    "LOGIN.AGREE_TERMS_AND_POLICY".tr(),
                                    style: TextStyle(color: Colors.black26),
                                    textAlign: TextAlign.center,)
                              ),
                            ),
                          ],
                        )
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
    ],
  );

  void _checkIsValid() {
    RegExp regExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    setState(() {
      _isInputValid = regExp.hasMatch(_email) && _name.length >= 3;
    });
  }

  void _onNextPressed() async {
    FocusScope.of(context).unfocus();
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