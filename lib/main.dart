import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/core/service/firebase_service.dart';
import 'package:postnow/ui/view/fire_home_view.dart';

void main() async {
  await init();
  runApp(MyApp());
}

FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _firebaseMessaging.requestNotificationPermissions();
  final token = _firebaseMessaging.getToken();
  print(token);
  _firebaseMessaging.configure(onLaunch: (message) {
    print("onLaunch");
    return Future.value(true);
  },
  onResume: (message) {
    print("onResume");
    return Future.value(true);
  },
  onMessage: (message) {
    print("onMessage");
    /*showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Text(message["natification"]["title"]),
      )
    );*/
    return Future.value(true);
  },
);

}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Now',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FirebaseService().handleAuth(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String phoneNo, verificationId, smsCode;

  bool codeSent = false;

  Future<void> _nextClick(phoneNo) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) {
      FirebaseService().signIn(authResult);
      /*Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SmsVerifyPage(title: "SMS Verification")),
      );*/
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
        codeAutoRetrievalTimeout: autoTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Post Now',
            ),
            TextFormField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                icon: Icon(Icons.smartphone),
                hintText: "Exp. 00436601234567",
              ),
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
                hintText: "Exp. 123456",
              ),
              onChanged: (val) {
                setState(() {
                  smsCode = val;
                });
              },
            ) : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          codeSent ? FirebaseService().signInWithOTP(smsCode, verificationId) : _nextClick(phoneNo);
        },
        tooltip: 'Next',
        child: Icon(Icons.arrow_forward),
      ), // This trailing comma makes auto-formatting nicer for build methods.


    );
  }
}


class SmsVerifyPage extends StatefulWidget {
  SmsVerifyPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SmsVerifyPageState createState() => _SmsVerifyPageState();
}

class _SmsVerifyPageState extends State<SmsVerifyPage> {
  int _counter = 0;

  void _incrementCounter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FireHomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Post Now',
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                icon: Icon(Icons.verified_user),
                hintText: "Exp. 123456",
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.arrow_forward),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
