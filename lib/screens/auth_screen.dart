import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/enums/legacity_enum.dart';
import 'package:postnow/screens/privacy_policy.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _boxDecoration = BoxDecoration(
      color: Colors.white70,
      border: Border.all(width: 0.4, color: const Color(0x99000000)),
      borderRadius: BorderRadius.circular(4)
  );
  final _formKey = GlobalKey<FormState>();
  String _countryCode, _phoneNo, _verificationId, _smsCode;
  bool _isInitialized = false;
  bool _codeSent = false;
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration(milliseconds: 1400), () =>
        setState(() {
          _isInitialized = true;
        })
    );
  }

  Future<void> _sendSms(phoneNo) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) async {
      AuthService().signIn(authResult);
    };

    final PhoneVerificationFailed verificationFailed = (FirebaseAuthException authException) {
      print('${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this._verificationId = verId;
      setState(() {
        print('_codeSent = true');
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
      body: Container(
        color: Color.fromARGB(255, 41, 171, 226),
          padding: EdgeInsets.all(20),
        child: _content()
      ),
      floatingActionButton: !_isInitialized || !_isInputValid ? null : FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          FocusScope.of(context).unfocus();
          if (_formKey.currentState.validate()) {
            print(_codeSent);
            if(_codeSent) {
              AuthService().signInWithOTP(_smsCode, _verificationId);
            } else {
              _sendSms(_countryCode + _phoneNo);
              setState(() {
                _isInputValid = false;
              });
            }
          }
        },
        child: Icon(Icons.arrow_forward, color: Colors.blueAccent,),
      ),
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
              Image.asset("assets/postnow_icon.png", width: MediaQuery.of(context).size.width*0.4,),
              Container(height: 20,),
              Container(
                decoration: _boxDecoration,
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      child: CountryCodePicker(
                        searchDecoration: InputDecoration(
                          hintText: "LOGIN.COUNTRY_NAME_EXAMPLE".tr()
                        ),
                        onInit: (value) { _countryCode = value.dialCode; },
                        onChanged: (value) { _countryCode = value.dialCode; },
                        initialSelection: 'AT',
                        showCountryOnly: true,
                      ),
                    ),
                    Expanded( // wrap your Column in Expanded
                      child: Container(
                        child: TextFormField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            //icon: Icon(Icons.smartphone),
                            hintText: "LOGIN.PHONE_FIELD_HINT".tr(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              RegExp regExp = new RegExp(
                                r"^[0-9]{8,12}$",
                              );
                              _isInputValid = regExp.hasMatch(val);
                              _phoneNo = val;
                              if (_codeSent)
                                _clearCode();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 10,),
              Visibility(
                visible: _codeSent,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: _boxDecoration,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          icon: Icon(Icons.verified_user),
                          hintText: "LOGIN.SMS_CODE_FIELD_HINT".tr(),
                          border: InputBorder.none
                      ),
                      validator: (value) {
                        if (value.length < 2) {
                          return "LOGIN.SMS_CODE_FIELD_VALIDATOR_ENTER_NAME".tr();
                        }
                        return null;
                      },
                      onChanged: (val) {
                        if (_smsCode == null && val.length == 6) {
                          AuthService().signInWithOTP(val, _verificationId);
                          FocusScope.of(context).unfocus();
                        }
                        setState(() {
                          RegExp regExp = new RegExp(
                            r"^[0-9]{6,10}$",
                          );
                          _isInputValid = regExp.hasMatch(val);
                          _smsCode = val;
                        });
                      },
                    )
                ),
              ),
              Container(height: 10,),
              FlatButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PrivacyPolicy(LegalTyp.PRIVACY_POLICY)),
                    );
                  },
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 50),
                  child: Text(
                    "LOGIN.AGREE_TERMS_AND_POLICY".tr(),
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,)
              ),
              Container(height: 10),
            ],
          ),
        ),
      ],
    )
  );

  _clearCode() {
    print('clear');
    _codeSent = false;
    _smsCode = null;
    _verificationId = null;
  }
}