import 'package:http/http.dart' as http;
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/services/notification_service.dart';

class CustomNotification implements Comparable {

  String key;
  String app;
  String title;
  String body;
  String image;
  String positiveText;
  String negativeText;
  String _positiveAction;
  String _negativeAction;
  int priority;


  CustomNotification.fromJson(Map json) {
    key = json["key"];
    app = json["app"];
    title = json["title"];
    body = json["body"];
    image = json["image"];
    positiveText = json["positive_text"];
    negativeText = json["negative_text"];
    _positiveAction = json["positive_action"];
    _negativeAction = json["negative_action"];
    priority = json["priority"];
  }
  
  Future<void> accept() async {
    if (_positiveAction == null)
      return;
    String action = NotificationService.parseUrl(_positiveAction);
    final url = '$FIREBASE_URL$action';
    try {
      await http.get(url);
    } catch (e) {
      print(e.message);
    }
  }
  
  Future<void> decline() async {
    if (_negativeAction == null)
      return;
    String action = NotificationService.parseUrl(_negativeAction);
    final url = '$FIREBASE_URL$action';
    try {
      await http.get(url);
    } catch (e) {
      print(e.message);
    }
  }

  @override
  int compareTo(other) => priority.compareTo(other.priority);

}