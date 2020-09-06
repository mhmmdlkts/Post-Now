import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Driver implements Comparable{
  double distance;
  String key;
  String name;
  String token;
  double lat;
  double long;
  bool isOnline;
  bool isMyDriver = false;

  Driver({this.name, this.isOnline, this.lat, this.long, this.token});

  Driver.fromSnapshot(DataSnapshot snapshot) {
    try {
      key = snapshot.key;
      name = snapshot.value["name"];
      token = snapshot.value["token"];
      isOnline = snapshot.value["isOnline"];
      lat = snapshot.value["lat"] + 0.0;
      long = snapshot.value["long"] + 0.0;
    } catch (e) {
      print("Driver can't tranform from snapshot");
    }
  }

  Driver.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    token = json['token'];
    isOnline = json['isOnline'];
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.name != null)
      data['name'] = this.name;
    if (this.token != null)
      data['token'] = this.token;
    if (this.isOnline != null)
      data['isOnline'] = this.isOnline;
    if (this.lat != null)
      data['lat'] = this.lat;
    if (this.long != null)
      data['long'] = this.long;
    return data;
  }

  Marker getMarker(BitmapDescriptor bitmapDescriptor) {
    return Marker(
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

  String getName() {
    return name == null? "Name" : name;
  }

  LatLng getLatLng() => LatLng(lat, long);
}