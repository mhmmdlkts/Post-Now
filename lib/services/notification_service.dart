import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/custom_notification.dart';

class NotificationService {
  static final List<CustomNotification> notifications = List();
  static String _uid;
  static String _appName;
  static String _position;

  static Future<void> fetch(String uid, Position latLng) async {
    _uid = uid;
    if (latLng != null)
      _position = latLng.latitude.toString() + "," + latLng.longitude.toString();
    _appName = (await PackageInfo.fromPlatform()).packageName.split(".").last;
    String url = '${FIREBASE_URL}getNotifications?uid=$uid&app=$_appName&position=$_position';
    print(url);
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
    url = url.replaceAll("{position}", _position);
    url = url.replaceAll("{uid}", _uid);
    url = url.replaceAll("{app}", _appName);
    print(url);
    return url;
  }
}