import 'package:firebase_database/firebase_database.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';


enum Vehicle {
  CAR,
  BIKE
}

enum Status {
  WAITING,
  ON_ROAD,
  FINISHED,
  CANCELLED
}

class Job {
  String key;
  String driverId;
  String name;
  Status status;
  Vehicle vehicle;
  DateTime start_time;
  DateTime accept_time;
  DateTime finish_time;
  LatLng origin;
  LatLng destination;

  Job({this.name, this.vehicle, this.origin, this.destination}) {
    start_time = DateTime.now();
    status = Status.WAITING;
  }

  Job.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    driverId = snapshot.value["driver-id"];
    status = stringToStatus(snapshot.value["status"]);
    vehicle = stringToVehicle(snapshot.value["vehicle"]);
    origin = stringToLatLng(snapshot.value["origin"]);
    destination = stringToLatLng(snapshot.value["destination"]);
    start_time = stringToDateTime(snapshot.value["start-time"]);
    accept_time = stringToDateTime(snapshot.value["accept-time"]);
    finish_time = stringToDateTime(snapshot.value["finish-time"]);
  }

  static Status stringToStatus(String status_string) {
    switch (status_string) {
      case "waiting":
        return Status.WAITING;
      case "on_the_road":
        return Status.ON_ROAD;
      case "finished":
        return Status.FINISHED;
      case "no_driver_found":
        return Status.CANCELLED;
    }
    return null;
  }

  static String statusToString(Status status) {
    switch (status) {
      case Status.WAITING:
        return "waiting";
      case Status.ON_ROAD:
        return "on_the_road";
      case Status.FINISHED:
        return "finished";
      case Status.CANCELLED:
        return "no_driver_found";
    }
    return null;
  }

  static Vehicle stringToVehicle(String vehicle_string) {
    switch (vehicle_string) {
      case "car":
        return Vehicle.CAR;
      case "bike":
        return Vehicle.BIKE;
    }
    return null;
  }

  static String vehicleToString(Vehicle vehicle) {
    switch (vehicle) {
      case Vehicle.CAR:
    return "car";
      case Vehicle.BIKE:
    return "bike";
    }
    return null;
  }

  static LatLng stringToLatLng(String latlng_string) {
    if (latlng_string == null)
      return null;
    List<String> latlng = latlng_string.split(",");
    double lat = double.parse(latlng[0]);
    double lng = double.parse(latlng[1]);
    return LatLng(lat, lng);
  }

  static String latLngToString(LatLng latLng) {
    if (latLng == null)
      return null;
    return "${latLng.latitude},${latLng.longitude}";
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

  RouteMode getRouteMode() {
    switch (vehicle) {
      case Vehicle.CAR:
        return RouteMode.driving;
      case Vehicle.BIKE:
        return RouteMode.bicycling;
    }
    return null;
  }

  Map toMap() {
    Map toReturn = new Map();
    toReturn['name'] = name;
    toReturn['driver-id'] = driverId;
    toReturn['status'] = statusToString(status);
    toReturn['vehicle'] = vehicleToString(vehicle);
    toReturn['origin'] = latLngToString(origin);
    toReturn['destination'] = latLngToString(destination);
    toReturn['start-time'] = dateTimeToString(start_time);
    toReturn['accept-time'] = dateTimeToString(accept_time);
    toReturn['finish-time'] = dateTimeToString(finish_time);
    return toReturn;
  }

  @override
  bool operator == (covariant Job other) => start_time.compareTo(other.start_time) == 0;

}