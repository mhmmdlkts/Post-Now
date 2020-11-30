import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicencesScreen extends StatefulWidget {
  LicencesScreen({Key key}) : super(key: key);

  @override
  _LicencesScreenState createState() => new _LicencesScreenState();
}

class _LicencesScreenState extends State<LicencesScreen> {

  Map licencesJson;
  List list;

  @override
  void initState() {
    super.initState();

    rootBundle.loadString("assets/licances/licances.json").then((value) => setState((){
      licencesJson = json.decode(value);
      list = licencesJson.values.toList();
    }));
    Future.delayed(Duration(seconds: 1), () => setState((){}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SETTINGS_SCREEN.SOFTWARE_LICENCES".tr(), style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
        brightness: Brightness.dark,
      ),
      body: ListView.separated(
        padding: EdgeInsets.only(top: 20, bottom:40, left: 5, right: 5),
        itemCount: list?.length??0,
        itemBuilder: (_,i) => Column(
          children: [
            Text(list[i]["TITLE"], style: TextStyle(fontSize: 11)),
            Container(height: 10,),
            Text(list[i]["LICENCE"], style: TextStyle(fontSize: 10)),
          ],
        ),
        separatorBuilder: (_,i) => Container(height: 25),
      ),
    );
  }

}