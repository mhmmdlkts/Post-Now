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

Future<void> init() async {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
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

class MyApp extends StatelessWidget {
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
        home: AuthService().handleAuth()
    );
  }
}