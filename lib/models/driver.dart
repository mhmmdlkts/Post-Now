import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'global_settings.dart';

class Driver implements Comparable{
  double distance;
  String key;
  String name;
  String surname;
  String token;
  double lat;
  double long;
  bool isOnline;
  bool active;
  String email;
  String phone;
  String image;
  String fleetId;
  GlobalSettings settings;

  Driver({this.name, this.surname, this.email, this.phone, this.isOnline, this.lat, this.long, this.image, this.fleetId, this.token}) {
    settings = GlobalSettings();
  }

  Driver.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    token = snapshot.value["token"];
    isOnline = snapshot.value["isOnline"];
    active = snapshot.value["active"];
    lat = snapshot.value["lat"] + 0.0;
    long = snapshot.value["long"] + 0.0;
    surname = snapshot.value["surname"];
    email = snapshot.value["email"];
    phone = snapshot.value["phone"];
    image = snapshot.value["image"];
    fleetId = snapshot.value["fleetId"];
    if (snapshot.value["settings"] != null)
      settings = GlobalSettings.fromJson(snapshot.value["settings"]);
  }

  Map<String, dynamic> toJson() => {
    'name': this.name,
    'token': this.token,
    'isOnline': this.isOnline,
    'active': this.active,
    'lat': this.lat,
    'long': this.long,
    'surname': this.surname,
    'email': this.email,
    'phone': this.phone,
    'fleetId': this.fleetId,
    'image': this.image,
    'settings': this.settings.toJson()
  };

  Marker getMarker(BitmapDescriptor bitmapDescriptor) {
    return Marker(
      zIndex: 1,
      markerId: MarkerId(key),
      position: LatLng(lat, long),
      icon: bitmapDescriptor,
      infoWindow: InfoWindow(
        title: name,
      ),
    );
  }

  @override
  int compareTo(other) {
    if (this.distance == other.distance)
      return 0;
    else if (this.distance < other.distance)
      return 1;
    else
      return -1;
  }

  LatLng getLatLng() => LatLng(lat, long);
}