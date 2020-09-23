import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:postnow/enums/legacity_enum.dart';
import 'package:postnow/services/legal_service.dart';

class LegalScreen extends StatefulWidget {
  final LegalTyp legalTyp;
  LegalScreen(this.legalTyp, {Key key}) : super(key: key);

  @override
  _PrivacyPolicy createState() => _PrivacyPolicy(legalTyp);
}

class _PrivacyPolicy extends State<LegalScreen> {
  final LegalService _policyService = LegalService();
  final LegalTyp legalTyp;
  Widget _content;

  _PrivacyPolicy(this.legalTyp);

  @override
  void initState() {
    super.initState();
    _policyService.getPrivacyPolicyWidget(legalTyp).then((value) => {
      setState(() {
        _content = value;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        iconTheme:  IconThemeData(color: Colors.white),
        title: Text(('LEGAL.' + legalTyp.toString()).tr()),
      ),
      body: Center(
        child: _content == null? CircularProgressIndicator() : _content,
      )
    );
  }
}