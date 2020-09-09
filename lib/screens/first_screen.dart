import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/screens/sign_up_screen.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/first_screen_service.dart';
import 'package:store_redirect/store_redirect.dart';

import 'auth_screen.dart';
import 'maps_screen.dart';

class FirstScreen extends StatefulWidget {
  final AsyncSnapshot snapshot;
  FirstScreen(this.snapshot);

  @override
  _FirstScreen createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  final FirstScreenService _firstScreenService = FirstScreenService();
  bool needsUpdate;

  @override
  void initState() {
    super.initState();

    checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    if (needsUpdate == null)
      return SplashScreen();
    if (needsUpdate)
      return SplashScreen();

    if (widget.snapshot.hasData) {
      if (widget.snapshot.data.displayName == null)
        return SignUpScreen(widget.snapshot.data);
      return GoogleMapsView(widget.snapshot.data);
    } else {
      return AuthScreen();
    }
  }

  checkUpdates() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();

    final onlineVersion = int.parse(remoteConfig.getString(FIREBASE_REMOTE_CONFIG_VERSION_KEY));
    final int localVersion = int.parse((await PackageInfo.fromPlatform()).buildNumber);

    setState(() {
      needsUpdate = localVersion < onlineVersion;
    });

    if (needsUpdate)
      _firstScreenService.showUpdateAvailableDialog(context);
  }

}