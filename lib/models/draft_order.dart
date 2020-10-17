import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:postnow/models/price.dart';

class DraftOrder {
  List<LatLng> routes;
  String key;
  double distance;
  double duration;
  Price price;

  DraftOrder.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    distance = snapshot.value["distance"] + 0.0;
    duration = snapshot.value["duration"] + 0.0;
    price = Price.fromJson(snapshot.value["price"]);
    setRoutes(snapshot.value["waypoints"]);
  }

  setRoutes(String wayPoints) {
    List<PointLatLng> result = PolylinePoints().decodePolyline(wayPoints);
    routes = List();
    for (int i = 0; i < result.length; i++)
      routes.add(LatLng(result[i].latitude, result[i].longitude));
  }
}