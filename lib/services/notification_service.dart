import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/custom_notification.dart';

class NotificationService {
  static final List<CustomNotification> notifications = List();
  static String _uid;
  static String _appName;

  static Future<void> fetch(String uid) async {
    _uid = uid;
    _appName = (await PackageInfo.fromPlatform()).packageName.split(".").last;
    String url = '${FIREBASE_URL}getNotifications?uid=$uid&app=$_appName';
    try {
      http.Response response = await http.get(url);
      json.decode(response.body).forEach((element) {
        notifications.add(CustomNotification.fromJson(element));
      });
      notifications.sort();
    } catch (e) {
      print(e.message);
    }
  }

  static String parseUrl(String url) {
    url = url.replaceAll("{uid}", _uid);
    url = url.replaceAll("{app}", _appName);
    return url;
  }
}