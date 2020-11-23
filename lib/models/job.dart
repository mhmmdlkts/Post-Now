import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/enums/job_vehicle_enum.dart';
import 'package:postnow/models/price.dart';
import 'package:postnow/models/shopping_item.dart';
import 'package:postnow/services/time_service.dart';
import 'address.dart';

class Job implements Comparable {
  Address destinationAddress;
  Address originAddress;
  String mollieOrderId;
  String payMethod;
  String customTransactionId;
  List<ShoppingItem> shoppingList;
  DateTime acceptTime;
  DateTime finishTime;
  DateTime startTime;
  Vehicle vehicle;
  String driverId;
  String userId;
  Status status;
  Price price;
  String name;
  String sign;
  String key;

  Job({this.name, this.userId, this.price, this.driverId, this.vehicle, this.customTransactionId, this.shoppingList, this.mollieOrderId, this.originAddress, this.destinationAddress}) {
    status = Status.WAITING;
  }

  Job.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    payMethod = snapshot.value["payMethod"];
    driverId = snapshot.value["driver-id"];
    userId = snapshot.value["user-id"];
    sign = snapshot.value["sign"];
    shoppingList = ShoppingItem.jsonToList(snapshot.value["shoppingItems"]);
    mollieOrderId = snapshot.value["mollieOrderId"];
    customTransactionId = snapshot.value["customTransactionId"];
    price = Price.fromJson(snapshot.value["price"]);
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
      case "accepted":
        return Status.ACCEPTED;
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
      case Status.ACCEPTED:
        return "accepted";
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
    'payMethod': payMethod,
    'user-id': userId,
    'sign': sign,
    'shoppingItems': ShoppingItem.listToString(shoppingList),
    'customTransactionId': customTransactionId,
    'mollieOrderId': mollieOrderId,
    'price': price.toMap(),
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
    shoppingList = ShoppingItem.jsonToList(json["shoppingItems"]);
    payMethod = json["payMethod"];
    customTransactionId = json["customTransactionId"];
    mollieOrderId = json["mollieOrderId"];
    price = Price.fromJson(json["price"]);
    status = stringToStatus(json["status"]);
    vehicle = stringToVehicle(json["vehicle"]);
    originAddress = Address.fromJson(json["origin-address"]);
    destinationAddress = Address.fromJson(json["destination-address"]);
    startTime = stringToDateTime(json["start-time"]);
    acceptTime = stringToDateTime(json["accept-time"]);
    finishTime = stringToDateTime(json["finish-time"]);
  }

  bool hasShoppingList() => shoppingList != null && shoppingList.isNotEmpty;

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

  Address getAddress(bool isDestination) {
    if (isDestination)
      return destinationAddress;
    else
      return originAddress;
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

  @override
  int compareTo(other) => -startTime.compareTo(other.startTime);
}