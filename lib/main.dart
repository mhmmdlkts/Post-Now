import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/auth_service.dart';

import 'package:easy_localization/easy_localization.dart' as loc;
import 'dart:ui' as ui;

import 'models/user.dart';

void main() async {
  await init();
  runApp(
      loc.EasyLocalization(
          supportedLocales: [Locale('en', ''), Locale('de', ''), Locale('tr', '')],
          path: 'assets/translations',
          fallbackLocale: Locale('en', ''),
          saveLocale: true,
          useOnlyLangCode: true,
          child: MyApp()
      ),
  );
}

FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _firebaseMessaging.requestNotificationPermissions();
  _firebaseMessaging.configure(
    onLaunch: (message) {
      print("onLaunch");
      return Future.value(true);
    },
    onResume: (message) {
      print("onResume");
      return Future.value(true);
    },
    onMessage: (message) {
      print("onMessage");
      return Future.value(true);
    },
  );
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  bool isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (context.locale.languageCode != ui.window.locale.languageCode)
      context.locale = Locale(ui.window.locale.languageCode, '');
    return MaterialApp(
      title: 'APP_NAME'.tr(),
      theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primaryTextTheme: TextTheme(
              headline6: TextStyle(
                  color: Colors.white
              )
          )
      ),
      home: Stack(
        children: [
          FirebaseService().handleAuth((isInitialized) => setState(() {
            this.isInitialized = isInitialized;
          })),
          isInitialized? Container() : SplashScreen(),
        ],
      )
    );
  }
}


class MyHomePage extends StatefulWidget {
  final ValueChanged<bool> isInitialized;
  MyHomePage(this.isInitialized, {Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(isInitialized);
}

class _MyHomePageState extends State<MyHomePage> {
  String name, phoneNo, verificationId, smsCode;
  final _formKey = GlobalKey<FormState>();
  final ValueChanged<bool> isInitialized;

  bool codeSent = false;

  _MyHomePageState(this.isInitialized);



  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: 1500),
          () => {
        isInitialized.call(true)
          },
    );
  }

  Future<void> _nextClick(phoneNo) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) async {
      FirebaseService().signIn(authResult).then((value) => sendUserInfo(value.user));
    };

    final PhoneVerificationFailed verificationFailed = (AuthException authException) {
      print('${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      setState(() {
        this.codeSent = true;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("APP_NAME".tr()),
                  TextFormField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.person),
                      hintText: "LOGIN.NAME_FIELD_HINT".tr(),
                    ),
                    validator: (value) {
                      if (value.length < 3) {
                        return "LOGIN.NAME_FIELD_VALIDATOR_ENTER_NAME".tr();
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() {
                        name = val;
                      });
                    },
                  ),
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
                        phoneNo = val;
                      });
                    },
                  ),
                  codeSent? TextFormField(
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
                        smsCode = val;
                      });
                    },
                  ) : Container(),
                ],
              ),
            )
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_formKey.currentState.validate()) {
            if(codeSent) {
              FirebaseService().signInWithOTP(smsCode, verificationId).then((value) => sendUserInfo(value.user));
            } else {
              _nextClick(phoneNo);
            }
          }
        },
        child: Icon(Icons.arrow_forward, color: Colors.white,),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<String> getPushToken() async {
    return _firebaseMessaging.getToken();
  }

  sendUserInfo(FirebaseUser u) async {
    String token = await getPushToken();
    User user = new User(name: name, phone: phoneNo, token: token);
    FirebaseDatabase.instance.reference().child('users').child(u.uid).set(user.toJson());
  }
}