import 'package:firebase_database/firebase_database.dart';

class Message {
  String key;
  bool from_driver;
  String message;
  String img;
  bool read;
  DateTime send_time;

  Message({this.from_driver, this.message, this.img}) {
    setSendTime();
    read = false;
  }

  setSendTime() {
    send_time = DateTime.now();
  }

  Message.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    from_driver = snapshot.value["from-driver"];
    read = snapshot.value["read"];
    message = snapshot.value["message"];
    img = snapshot.value["img"];
    send_time = stringToDateTime(snapshot.value["send-time"]);
  }

  static DateTime stringToDateTime(String dateTime_string) {
    if (dateTime_string == null)
      return null;
    return DateTime.parse(dateTime_string);
  }

  static String dateTimeToString(DateTime dateTime) {
    if (dateTime == null)
      return null;
    return dateTime.toString();
  }

  Map toMap() {
    Map toReturn = new Map();
    toReturn['from-driver'] = from_driver;
    toReturn['read'] = read;
    toReturn['message'] = message;
    toReturn['img'] = img;
    toReturn['send-time'] = dateTimeToString(send_time);
    return toReturn;
  }

  @override
  bool operator == (covariant Message other) => send_time.compareTo(other.send_time) == 0;

}