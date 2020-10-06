import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/enums/job_vehicle_enum.dart';
import 'address.dart';

class Job {
  Address destinationAddress;
  Address originAddress;
  String brainTreeTransactionId;
  String customTransactionId;
  DateTime acceptTime;
  DateTime finishTime;
  DateTime startTime;
  Vehicle vehicle;
  String driverId;
  String userId;
  Status status;
  double price;
  String name;
  String sign;
  String key;

  Job({this.name, this.userId, this.price, this.driverId, this.vehicle, this.customTransactionId, this.brainTreeTransactionId, this.originAddress, this.destinationAddress}) {
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
    brainTreeTransactionId = snapshot.value["brainTreeTransactionId"];
    customTransactionId = snapshot.value["customTransactionId"];
    price = snapshot.value["price"] + 0.0;
    status = stringToStatus(snapshot.value["status"]);
    vehicle = stringToVehicle(snapshot.value["vehicle"]);
    originAddress = Address.fromJson(snapshot.value["origin-address"]);
    destinationAddress = Address.fromJson(snapshot.value["destination-address"]);
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
      case "customer_canceled":
        return Status.CUSTOMER_CANCELED;
      case "driver_canceled":
        return Status.DRIVER_CANCELED;
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
      case Status.CUSTOMER_CANCELED:
        return "customer_canceled";
      case Status.DRIVER_CANCELED:
        return "driver_canceled";
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
    'customTransactionId': customTransactionId,
    'brainTreeTransactionId': brainTreeTransactionId,
    'price': price,
    'status': statusToString(status),
    'vehicle': vehicleToString(vehicle),
    'origin-address': originAddress.toMap(),
    'destination-address': destinationAddress.toMap(),
    'start-time': dateTimeToString(startTime),
    'accept-time': dateTimeToString(acceptTime),
    'finish-time': dateTimeToString(finishTime),
  };

  Job.fromJson(Map json, {this.key}) {
    if (key == null)
      this.key = json["key"];
    name = json["name"];
    driverId = json["driver-id"];
    userId = json["user-id"];
    sign = json["sign"];
    customTransactionId = json["customTransactionId"];
    brainTreeTransactionId = json["brainTreeTransactionId"];
    price = json["price"] + 0.0;
    status = stringToStatus(json["status"]);
    vehicle = stringToVehicle(json["vehicle"]);
    originAddress = Address.fromJson(json["origin-address"]);
    destinationAddress = Address.fromJson(json["destination-address"]);
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
    if (customTransactionId != null) toReturn['customTransactionId'] = customTransactionId;
    if (brainTreeTransactionId != null) toReturn['brainTreeTransactionId'] = brainTreeTransactionId;
    if (status != null) toReturn['status'] = statusToString(status);
    if (vehicle != null) toReturn['vehicle'] = vehicleToString(vehicle);
    if (originAddress != null) toReturn['origin-address'] = originAddress.toMap();
    if (destinationAddress != null) toReturn['destination-address'] = destinationAddress.toMap();
    if (startTime != null) toReturn['start-time'] = dateTimeToString(startTime);
    if (acceptTime != null) toReturn['accept-time'] = dateTimeToString(acceptTime);
    if (finishTime != null) toReturn['finish-time'] = dateTimeToString(finishTime);
    return toReturn;
  }

  bool isJobAccepted() {
    return this.acceptTime != null;
  }

  String getDriverId() {
    return driverId == null ? "No Driver" : driverId;
  }

  String getStatusMessageKey() {
    return "MODELS.JOB." + status.toString().split('.')[1];
  }

  LatLng getOrigin() {
    if (originAddress == null)
      return null;
    return originAddress.coordinates;
  }

  LatLng getDestination() {
    if (destinationAddress == null)
      return null;
    return destinationAddress.coordinates;
  }

  String getOriginAddress() {
    if (originAddress == null)
      return null;
    return originAddress.getAddress();
  }

  String getDestinationAddress() {
    if (destinationAddress == null)
      return null;
    return destinationAddress.getAddress();
  }

  Duration getDriveTime() {
    if (acceptTime == null || finishTime == null)
      return Duration();
    return finishTime.difference(acceptTime);
  }

  @override
  bool operator == (covariant Job other) {
    if (key != null)
      return key == other.key;
    if (originAddress != null && destinationAddress != null) {
      return originAddress == originAddress && destinationAddress == destinationAddress;
    }
    return false;
  }
}