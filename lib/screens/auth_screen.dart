import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _phoneNo, _verificationId, _smsCode;
  bool _isInitialized = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration(milliseconds: 2000), () =>
        setState(() {
          _isInitialized = true;
        })
    );
  }

  Future<void> _nextClick(phoneNo) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) async {
      AuthService().signIn(authResult);
    };

    final PhoneVerificationFailed verificationFailed = (AuthException authException) {
      print('${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this._verificationId = verId;
      setState(() {
        this._codeSent = true;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this._verificationId = verId;
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNo,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verified,
        verificationFailed: verificationFailed,
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return SplashScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text("APP_NAME".tr()),
        brightness: Brightness.dark,
      ),
      body: Container(
          padding: EdgeInsets.all(20),
          child: _content()
      ),
      floatingActionButton: !_isInitialized? null : FloatingActionButton(
        onPressed: () async {
          if (_formKey.currentState.validate()) {
            if(_codeSent) {
              AuthService().signInWithOTP(_smsCode, _verificationId);
            } else {
              _nextClick(_phoneNo);
            }
          }
        },
        child: Icon(Icons.arrow_forward, color: Colors.white,),
      ),
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
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                icon: Icon(Icons.smartphone),
                hintText: "LOGIN.PHONE_FIELD_HINT".tr(),
              ),
              validator: (value) {
                RegExp regExp = new RegExp(
                  r"^[+]{1}[0-9]{8,14}$",
                );
                if (!regExp.hasMatch(value)) {
                  return "LOGIN.PHONE_FIELD_VALIDATOR_ENTER_NAME".tr();
                }
                return null;
              },
              onChanged: (val) {
                setState(() {
                  _phoneNo = val;
                });
              },
            ),
            _codeSent? TextFormField(
              maxLength: 6,
              decoration: InputDecoration(
                icon: Icon(Icons.verified_user),
                hintText: "LOGIN.SMS_CODE_FIELD_HINT".tr(),
              ),
              validator: (value) {
                if (value.length < 2) {
                  return "LOGIN.SMS_CODE_FIELD_VALIDATOR_ENTER_NAME".tr();
                }
                return null;
              },
              onChanged: (val) {
                setState(() {
                  _smsCode = val;
                });
              },
            ) : Container(),
          ],
        ),
      )
  );
}