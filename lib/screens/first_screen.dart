import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:postnow/services/first_screen_service.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/screens/sign_up_screen.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'intro_screen.dart';
import 'maps_screen.dart';


class FirstScreen extends StatefulWidget {
  final AsyncSnapshot snapshot;
  FirstScreen(this.snapshot);

  @override
  _FirstScreen createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  final FirstScreenService _firstScreenService = FirstScreenService();
  int _onlineVersion;
  SharedPreferences prefs;
  bool needsUpdate;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) => prefs = value);
    checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    if (prefs == null)
      return SplashScreen();
    if (needsUpdate == null)
      return SplashScreen();
    if (needsUpdate)
      return SplashScreen();

    if (widget.snapshot.hasData) {
      if (widget.snapshot.data.displayName == null)
        return SignUpScreen(widget.snapshot.data);
      if (_isFirstTimeOpen())
        return IntroScreen(() {
          setState((){
            prefs.setBool(IS_FIRST_TIME_OPEN_KEY, false);
          });
        });
      return MapsScreen(widget.snapshot.data);
    } else {
      return AuthScreen();
    }
  }

  checkUpdates() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();
    _onlineVersion = remoteConfig.getInt(FIREBASE_REMOTE_CONFIG_VERSION_KEY);

    final int localVersion = int.parse((await PackageInfo.fromPlatform()).buildNumber);

    setState(() {
      needsUpdate = localVersion < _onlineVersion;
    });

    if (needsUpdate)
      _firstScreenService.showUpdateAvailableDialog(context);
  }

  bool _isFirstTimeOpen() {
    bool isFirstTimeOpen = prefs.getBool(IS_FIRST_TIME_OPEN_KEY);
    if (isFirstTimeOpen == null) {
      isFirstTimeOpen = true;
    }
    return isFirstTimeOpen;
  }
}