import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/screens/licances_screen.dart';
import 'package:postnow/screens/web_view_screen.dart';
import 'package:postnow/services/global_service.dart';
import 'package:url_launcher/url_launcher.dart';

const String POST_NOW_PRIVACY_POLICY_URL = "https://postnow.at/app-postnow-privacy-policy/";
const String POST_NOW_DRIVER_PRIVACY_POLICY_URL = "https://postnow.at/app-postnowdriver-privacy-policy/";
const String POST_NOW_REGISTER_DRIVER = "https://postnow.at/register-driver/";

class LegalService {

  static void openPrivacyPolicy(BuildContext context) async {
    String url = (await GlobalService.isDriverApp())?POST_NOW_DRIVER_PRIVACY_POLICY_URL:POST_NOW_PRIVACY_POLICY_URL;
    openWeb(url, context);
  }

  static void openLicences(BuildContext context) async {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LicencesScreen())
    );
  }

  static void openRegisterDriver(BuildContext context) async {
    openWeb(POST_NOW_REGISTER_DRIVER, context);
  }

  static void openWeb(String url, BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url, (){})),
    );
  }

  static void openWriteMail() async {
    String email = "support@postnow.at" ;
    String subject = Uri.encodeComponent("LOGIN.AUTO_FILL_EMAIL_SUBJECT".tr());
    String url = 'mailto:$email?subject=$subject';
    await launch(url);
  }
}