import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/enums/legacity_enum.dart';
const String POST_NOW_PRIVACY_POLICY_URL = "https://legal.postnow.at/postnow_privacy_policy.html";
const String POST_NOW_SOFTWARE_LICENCES_URL = "https://legal.postnow.at/postnow_software_licences.html";
const String POST_NOW_CONTACT_URL = "https://legal.postnow.at/postnow_contact.html";

class LegalService {
  Future<Widget> getPrivacyPolicyWidget(LegalTyp legalTyp) async {
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.all(10),
            child: Html(
            data: await _getPrivacyPolicyContent(legalTyp),
          ),
        )
      ],
    );
  }

  String _getLegalUrl(LegalTyp legalTyp) {
    assert (legalTyp != null);
    switch (legalTyp) {
      case LegalTyp.PRIVACY_POLICY:
        return POST_NOW_PRIVACY_POLICY_URL;
      case LegalTyp.SOFTWARE_LICENCES:
        return POST_NOW_SOFTWARE_LICENCES_URL;
      case LegalTyp.CONTACT:
        return POST_NOW_CONTACT_URL;
    }
    return null;
  }

  Future<String> _getPrivacyPolicyContent(LegalTyp legalTyp) async {
    return (await http.get(_getLegalUrl(legalTyp))).body;
  }
}