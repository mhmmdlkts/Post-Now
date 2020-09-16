import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:postnow/enums/legacity_enum.dart';
import 'package:postnow/screens/legal_screen.dart';

class LegalMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:  IconThemeData(color: Colors.white),
          brightness: Brightness.dark,
          title: Text('LEGAL.TITLE'.tr()),
        ),
        body: ListView.builder (
            itemCount: LegalTyp.values.length,
            itemBuilder: (BuildContext ctxt, int index) {
              return _getMenuButton(context, LegalTyp.values[index]);
            }
        )
    );
  }

  Widget _getMenuButton(context, LegalTyp legalTyp) => InkWell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: Text(('LEGAL.' + legalTyp.toString()).tr(), textAlign: TextAlign.left,),
        ),
        Divider(height: 0)
      ],
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LegalScreen(legalTyp)),
      );
    },
  );
}