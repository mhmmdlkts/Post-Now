import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/services/legal_service.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const DEFAULT_COUNTRY_CODE = "+43";
  final AuthService _authService = AuthService();
  final FocusNode _smsFocusNode = FocusNode();
  final _boxDecoration = BoxDecoration(
    color: Colors.black12,
    borderRadius: BorderRadius.circular(30)
  );
  final _formKey = GlobalKey<FormState>();
  String _countryCode = DEFAULT_COUNTRY_CODE, _phoneNo, _verificationId, _smsCode;
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
        this._codeSent = true;
        _smsFocusNode.requestFocus();
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this._verificationId = verId;
    };

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNo,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verified,
        verificationFailed: verificationFailed,
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout,
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return SplashScreen();
    return Scaffold(
      backgroundColor: primaryBlue,
      body: _content(),
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
                  Text("LOGIN.TITLE".tr(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
                  Text("LOGIN.SUBTITLE".tr(), style: TextStyle(color: Colors.black54),),
                  Container(height: 30,),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("LOGIN.PHONE_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                        Container(height: 10,),
                        Container(
                          decoration: _boxDecoration,
                          child: Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 10),
                                child: CountryCodePicker(
                                  searchDecoration: InputDecoration(
                                      hintText: "LOGIN.COUNTRY_NAME_EXAMPLE".tr(namedArgs: {'countryCode': DEFAULT_COUNTRY_CODE})
                                  ),
                                  onInit: (value) { _countryCode = value.dialCode; },
                                  onChanged: (value) { _countryCode = value.dialCode; },
                                  initialSelection: DEFAULT_COUNTRY_CODE,
                                  showCountryOnly: true,
                                  showFlagMain: true,
                                  favorite: [DEFAULT_COUNTRY_CODE],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: TextFormField(
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "LOGIN.PHONE_FIELD_HINT".tr(),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        RegExp regExp = new RegExp(r"^[0-9]{8,12}$");
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
                        Visibility(
                          visible: _codeSent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 20,),
                              Text("LOGIN.SMS_CODE_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                              Container(height: 10,),
                              Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: _boxDecoration,
                                  child: TextFormField(
                                    focusNode: _smsFocusNode,
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
                            ],
                          )
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
                                child: Text("LOGIN.CONTINUE_BUTTON".tr(), style: TextStyle(color: Colors.white),),
                                onPressed: _buttonClickAble()? _onContinuePressed:null,
                              ),
                            ),
                          ],
                        ),
                        Container(height: 15,),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: double.infinity),
                          child: FlatButton(
                              onPressed: () async {
                                LegalService.openPrivacyPolicy(context);
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

  _clearCode() {
    _codeSent = false;
    _smsCode = null;
    _verificationId = null;
  }

  _buttonClickAble() => _isInitialized && _isInputValid;

  _onContinuePressed() async {
    // signInAnonymously(); This is for emulator tests
    // return;
    FocusScope.of(context).unfocus();
    if (_formKey.currentState.validate()) {
      if(_codeSent) {
        AuthService().signInWithOTP(_smsCode, _verificationId);
      } else {
        _sendSms(_countryCode + _phoneNo);
        setState(() {
          _isInputValid = false;
        });
      }
    }
  }

  void signInAnonymously() {
    FirebaseAuth.instance.signInAnonymously().then((result) {
      setState(() {
        final User user = result.user;
      });
    });
  }
}