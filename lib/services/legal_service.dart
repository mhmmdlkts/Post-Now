import 'package:postnow/services/global_service.dart';
import 'package:url_launcher/url_launcher.dart';

const String POST_NOW_PRIVACY_POLICY_URL = "https://postnow.at/app-postnow-privacy-policy/";
const String POST_NOW_DRIVER_PRIVACY_POLICY_URL = "https://postnow.at/app-postnowdriver-privacy-policy/";
const String POST_NOW_SOFTWARE_LICENCES_URL = "https://postnow.at/software-licences/";

class LegalService {

  static void openPrivacyPolicy() async {
    String url = (await GlobalService.isDriverApp())?POST_NOW_DRIVER_PRIVACY_POLICY_URL:POST_NOW_PRIVACY_POLICY_URL;
    _openWeb(url);
  }

  static void openLicences() async {
    String url = POST_NOW_SOFTWARE_LICENCES_URL;
    _openWeb(url);
  }

  static void _openWeb(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}