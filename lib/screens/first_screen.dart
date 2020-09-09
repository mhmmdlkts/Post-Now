import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:postnow/services/auth_service.dart';

class FirstScreen extends StatefulWidget {
  FirstScreen();

  @override
  _FirstScreen createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {

  @override
  void initState() {
    super.initState();

    checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  Future<bool> checkUpdates() async {
    print('aa');
    print('aa');
    await Future.delayed(Duration(seconds: 4));
    print('aa');
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    print('aa');
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();

    final requiredBuildNumber = remoteConfig.getInt('build_version');
    print(':' + requiredBuildNumber.toString());

    PackageInfo.fromPlatform().then((packageInfo) => {
      print(packageInfo.toString())
    });
    return true;
  }
}