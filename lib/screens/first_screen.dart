import 'package:postnow/services/first_screen_service.dart';
import 'package:postnow/screens/sign_up_screen.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/material.dart';
import 'package:postnow/services/remote_config_service.dart';
import 'auth_screen.dart';
import 'maps_screen.dart';


class FirstScreen extends StatefulWidget {
  AsyncSnapshot snapshot;
  FirstScreen(this.snapshot);

  @override
  _FirstScreen createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  final FirstScreenService _firstScreenService = FirstScreenService();
  int _onlineVersion;
  bool _needsUpdate;

  @override
  void initState() {
    super.initState();
    checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    if (_needsUpdate == null || _needsUpdate)
      return SplashScreen();

    if (widget.snapshot.hasData) {
      if (widget.snapshot.data.displayName == null)
        return SignUpScreen(widget.snapshot.data);
      return MapsScreen(widget.snapshot.data);
    }
    return AuthScreen();
  }

  checkUpdates() async {
    await RemoteConfigService.fetch();
    _onlineVersion = await RemoteConfigService.getBuildVersion();

    final int localVersion = int.parse((await PackageInfo.fromPlatform()).buildNumber);

    setState(() {
      _needsUpdate = localVersion < _onlineVersion;
    });

    if (_needsUpdate)
      _firstScreenService.showUpdateAvailableDialog(context);
  }
}