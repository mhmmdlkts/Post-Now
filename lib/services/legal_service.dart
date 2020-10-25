import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/services/global_service.dart';
import 'package:url_launcher/url_launcher.dart';

const String POST_NOW_PRIVACY_POLICY_URL = "https://postnow.at/app-postnow-privacy-policy/";
const String POST_NOW_DRIVER_PRIVACY_POLICY_URL = "https://postnow.at/app-postnowdriver-privacy-policy/";
const String POST_NOW_SOFTWARE_LICENCES_URL = "https://postnow.at/software-licences/";
const String POST_NOW_REGISTER_DRIVER = "https://postnow.at/register-driver/";

class LegalService {

  static void openPrivacyPolicy() async {
    String url = (await GlobalService.isDriverApp())?POST_NOW_DRIVER_PRIVACY_POLICY_URL:POST_NOW_PRIVACY_POLICY_URL;
    openWeb(url);
  }

  static void openLicences() async {
    openWeb(POST_NOW_SOFTWARE_LICENCES_URL);
  }

  static void openRegisterDriver() async {
    openWeb(POST_NOW_REGISTER_DRIVER);
  }

  static void openWeb(String url) async {
    try {
      await launch(url);
    } catch (e) {
      print("Can not launch " + e);
    }
  }

  static void openWriteMail() async {
    String email = "support@postnow.at" ;
    String subject = Uri.encodeComponent("LOGIN.AUTO_FILL_EMAIL_SUBJECT".tr());
    String url = 'mailto:$email?subject=$subject';
    await launch(url);
  }
}