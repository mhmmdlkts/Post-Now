import 'package:postnow/environment/global_variables.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'dart:convert';

import 'package:postnow/services/global_service.dart';

class RemoteConfigService {
  static Map _values;
  static Future<void> fetch() async {
    String url = '${FIREBASE_URL}get_remote_config';
    try {
      http.Response response = await http.get(url);
      _values = json.decode(response.body);
    } catch (e) {
      print(e.message);
    }
  }

  static Future<int> getBuildVersion() async {
    if (_values == null)
      return -1;
    final String key = FIREBASE_REMOTE_CONFIG_VERSION_KEY(Platform.isIOS, await GlobalService.isDriverApp());
    return getInt(key);
  }

  static double getDouble(String key) {
    if (_values == null)
      return -1;
    try {
      return double.parse(_values[key]);
    } catch (e) {
      print(e);
      return 0.0;
    }
  }

  static int getInt(String key) {
    try {
      return int.parse(_values[key]);
    } catch (e) {
      print(e);
      return 0;
    }
  }

  static String getString(String key) {
    return _values[key].toString();
  }

  static List<String> getStringList(String key) {
    try {
      return List<String>.from(json.decode(_values[key]));
    } catch (e) {
      print(e);
      return List();
    }
  }
}