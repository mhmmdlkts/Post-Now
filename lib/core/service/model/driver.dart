import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Driver {
  String key;
  String name;
  double lat;
  double long;
  bool isOnline;

  Driver({this.name, this.isOnline, this.lat, this.long});

  Driver.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    isOnline = snapshot.value["isOnline"];
    lat = snapshot.value["lat"] + 0.0;
    long = snapshot.value["long"] + 0.0;
  }

  Driver.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    isOnline = json['isOnline'];
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['isOnline'] = this.isOnline;
    data['lat'] = this.lat;
    data['long'] = this.long;
    return data;
  }

  Marker getMarker() {
    return Marker(
        markerId: MarkerId(key),
        position: LatLng(lat, long),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
    );
  }

}