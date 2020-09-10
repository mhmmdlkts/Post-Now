import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:postnow/enums/legacity_enum.dart';
import 'package:postnow/services/privacy_policy_service.dart';

class PrivacyPolicy extends StatefulWidget {
  final LegalTyp legalTyp;
  PrivacyPolicy(this.legalTyp, {Key key}) : super(key: key);

  @override
  _PrivacyPolicy createState() => _PrivacyPolicy(legalTyp);
}

class _PrivacyPolicy extends State<PrivacyPolicy> {
  final PrivacyPolicyService _policyService = PrivacyPolicyService();
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
        iconTheme:  IconThemeData(color: Colors.white),
        title: Text('PRIVACY_POLICY.TITLE'.tr()),
      ),
      body: Center(
        child: _content == null? CircularProgressIndicator() : _content,
      )
    );
  }
}