import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/widgets/stateful_wrapper.dart';

import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      EasyLocalization(
          supportedLocales: [Locale('en', ''), Locale('de', ''), Locale('tr', ''), Locale('sr', ''), Locale('ro', '')],
          path: 'assets/translations',
          fallbackLocale: Locale('en', ''),
          saveLocale: true,
          useOnlyLangCode: true,
          child: MyApp()
      ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
      onInit: () { context.locale = Locale(ui.window.locale.languageCode, ''); },
      child: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          return MaterialApp(
              title: 'APP_NAME'.tr(),
              theme: ThemeData(
                  primarySwatch: Colors.lightBlue,
                  appBarTheme: Theme.of(context)
                      .appBarTheme
                      .copyWith(brightness: Brightness.dark),
                  brightness: Brightness.light,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  primaryTextTheme: TextTheme(
                      headline6: TextStyle(
                          color: Colors.white
                      )
                  )
              ),
              home: AuthService().handleAuth(snapshot.connectionState)
          );
        },
      )
    );
  }
}