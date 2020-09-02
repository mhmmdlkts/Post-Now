import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/enums/job_vehicle_enum.dart';

class Job {
  String destinationAddress;
  String transactionId;
  String originAddress;
  DateTime acceptTime;
  DateTime finishTime;
  DateTime startTime;
  LatLng destination;
  Vehicle vehicle;
  String driverId;
  String userId;
  Status status;
  LatLng origin;
  double price;
  String name;
  String sign;
  String key;

  Job({this.name, this.userId, this.price, this.driverId, this.vehicle, this.transactionId, this.origin, this.destination, this.originAddress, this.destinationAddress}) {
    setStartTime();
    status = Status.WAITING;
  }

  setStartTime() {
    startTime = DateTime.now();
  }

  setAcceptTime() {
    acceptTime = DateTime.now();
  }

  setFinishTime() {
    finishTime = DateTime.now();
  }

  Job.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    driverId = snapshot.value["driver-id"];
    userId = snapshot.value["user-id"];
    sign = snapshot.value["sign"];
    transactionId = snapshot.value["transactionId"];
    price = snapshot.value["price"] + 0.0;
    status = stringToStatus(snapshot.value["status"]);
    vehicle = stringToVehicle(snapshot.value["vehicle"]);
    origin = stringToLatLng(snapshot.value["origin"]);
    destination = stringToLatLng(snapshot.value["destination"]);
    originAddress = snapshot.value["origin-address"];
    destinationAddress = snapshot.value["destination-address"];
    startTime = stringToDateTime(snapshot.value["start-time"]);
    acceptTime = stringToDateTime(snapshot.value["accept-time"]);
    finishTime = stringToDateTime(snapshot.value["finish-time"]);
  }

  static Status stringToStatus(String statusString) {
    switch (statusString) {
      case "waiting":
        return Status.WAITING;
      case "on_the_road":
        return Status.ON_ROAD;
      case "package_picked":
        return Status.PACKAGE_PICKED;
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
      case Status.PACKAGE_PICKED:
        return "package_picked";
      case Status.FINISHED:
        return "finished";
      case Status.CANCELLED:
        return "no_driver_found";
    }
    return null;
  }

  static Vehicle stringToVehicle(String vehicleString) {
    switch (vehicleString) {
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

  static LatLng stringToLatLng(String latLngString) {
    if (latLngString == null)
      return null;
    List<String> latLng = latLngString.split(",");
    double lat = double.parse(latLng[0]);
    double lng = double.parse(latLng[1]);
    return LatLng(lat, lng);
  }

  static String latLngToString(LatLng latLng) {
    if (latLng == null)
      return null;
    return "${latLng.latitude},${latLng.longitude}";
  }

  static DateTime stringToDateTime(String dateTimeString) {
    if (dateTimeString == null)
      return null;
    return DateTime.parse(dateTimeString);
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

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'driver-id': driverId,
    'user-id': userId,
    'sign': sign,
    'transactionId': transactionId,
    'price': price,
    'status': statusToString(status),
    'vehicle': vehicleToString(vehicle),
    'origin': latLngToString(origin),
    'destination': latLngToString(destination),
    'origin-address': originAddress,
    'destination-address': destinationAddress,
    'start-time': dateTimeToString(startTime),
    'accept-time': dateTimeToString(acceptTime),
    'finish-time': dateTimeToString(finishTime),
  };

  Job.fromJson(Map json, {key}) {
    if (key == null)
      this.key = json["key"];
    else
      this.key = key;
    name = json["name"];
    driverId = json["driver-id"];
    userId = json["user-id"];
    sign = json["sign"];
    transactionId = json["transactionId"];
    price = json["price"] + 0.0;
    status = stringToStatus(json["status"]);
    vehicle = stringToVehicle(json["vehicle"]);
    origin = stringToLatLng(json["origin"]);
    destination = stringToLatLng(json["destination"]);
    originAddress = json["origin-address"];
    destinationAddress = json["destination-address"];
    startTime = stringToDateTime(json["start-time"]);
    acceptTime = stringToDateTime(json["accept-time"]);
    finishTime = stringToDateTime(json["finish-time"]);
  }

  Map toMap() {
    Map toReturn = new Map();
    if (name != null) toReturn['name'] = name;
    if (driverId != null) toReturn['driver-id'] = driverId;
    if (userId != null) toReturn['user-id'] = userId;
    if (sign != null) toReturn['sign'] = sign;
    if (price != null) toReturn['price'] = price;
    if (transactionId != null) toReturn['transactionId'] = transactionId;
    if (status != null) toReturn['status'] = statusToString(status);
    if (vehicle != null) toReturn['vehicle'] = vehicleToString(vehicle);
    if (origin != null) toReturn['origin'] = latLngToString(origin);
    if (destination != null) toReturn['destination'] = latLngToString(destination);
    if (originAddress != null) toReturn['origin-address'] = originAddress;
    if (destinationAddress != null) toReturn['destination-address'] = destinationAddress;
    if (startTime != null) toReturn['start-time'] = dateTimeToString(startTime);
    if (acceptTime != null) toReturn['accept-time'] = dateTimeToString(acceptTime);
    if (finishTime != null) toReturn['finish-time'] = dateTimeToString(finishTime);
    return toReturn;
  }

  bool isJobForMe(String uid) {
    return this.driverId == uid;
  }

  bool isJobAccepted() {
    return this.acceptTime != null;
  }

  getDriverId() {
    return driverId == null ? "No Driver" : driverId;
  }

  String getStatusMessageKey() {
    return "MODELS.JOB." + Status.WAITING.toString().split('.')[1];
  }

  @override
  bool operator == (covariant Job other) => key.compareTo(other.key) == 0;

}