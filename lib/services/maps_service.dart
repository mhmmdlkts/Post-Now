import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/src/route_mode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/environment/global_variables.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:postnow/models/address.dart';
import 'package:postnow/models/draft_order.dart';

import 'package:postnow/models/job.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/models/shopping_item.dart';
import 'package:postnow/services/remote_config_service.dart';

class MapsService with WidgetsBindingObserver {
  final DatabaseReference jobsChatRef = FirebaseDatabase.instance.reference().child('jobs_chat');
  final DatabaseReference driverRef = FirebaseDatabase.instance.reference().child('drivers');
  final DatabaseReference jobsRef = FirebaseDatabase.instance.reference().child('jobs');
  final DatabaseReference draftRef = FirebaseDatabase.instance.reference().child('draft_order');
  DatabaseReference userRef;
  final String uid;

  MapsService(this.uid) {
    userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
  }

  double calculatePrice (Position position, LatLng latLng) {
    double totalDistance = coordinateDistance(LatLng(position.latitude, position.longitude), latLng);
    print('total: ' + totalDistance.toString());
    double calcPrice = RemoteConfigService.getDouble(FIREBASE_REMOTE_CONFIG_EURO_START_KEY);
    print('calcPrice: ' + calcPrice.toString());
    calcPrice += totalDistance * RemoteConfigService.getDouble(FIREBASE_REMOTE_CONFIG_EURO_PER_KM_KEY);
    return num.parse(calcPrice.toStringAsFixed(2));
  }

  int getFreeItemCount() => RemoteConfigService.getInt(FIREBASE_REMOTE_FREE_SHOPPING_ITEMS_COUNT);
  double getShoppingItemCost() => RemoteConfigService.getDouble(FIREBASE_REMOTE_SHOPPING_ITEMS_COST);
  double getShoppingSameItemCost() => RemoteConfigService.getDouble(FIREBASE_REMOTE_SHOPPING_SAME_ITEMS_COST);

  List<String> getTopics() {
    return RemoteConfigService.getStringList(FIREBASE_REMOTE_CONFIG_MARKET_TOPICS);
  }

  double coordinateDistance(LatLng latLng1, LatLng latLng2) {
    if (latLng1 == null || latLng2 == null)
      return 0.0;
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((latLng2.latitude - latLng1.latitude) * p) / 2 +
        c(latLng1.latitude * p) * c(latLng2.latitude * p) * (1 - c((latLng2.longitude - latLng1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void setNewCameraPosition(GoogleMapController controller, LatLng first, LatLng second, bool centerFirst) async {
    if (first == null || controller == null)
      return;
    CameraUpdate cameraUpdate;
    if (second == null) {
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else if (centerFirst) {
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else {
      LatLng target = LatLng(
          (first.latitude + second.latitude) / 2,
          (first.longitude + second.longitude) / 2
      );
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: await controller.getZoomLevel()));

      /*LatLngBounds bound = _latLngBoundsCalculate(first, second);
      cameraUpdate = CameraUpdate.newLatLngBounds(bound, 70);*/
    }
    controller.animateCamera(cameraUpdate);
  }

  LatLngBounds _latLngBoundsCalculate(LatLng first, LatLng second) {
    bool check = first.latitude < second.latitude;
    return LatLngBounds(southwest: check ? first : second, northeast: check ? second : first);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  Future<double> getCredit() async {
    double credit;
    await userRef.child("credit").once().then((value) => {
      credit = value.value + 0.0,
    });
    return credit;
  }

  double getCancelFeeAmount() {
     return RemoteConfigService.getDouble(FIREBASE_REMOTE_CANCEL_FEE_KEY);
  }

  void cancelJob(Job j) async {
    String url = '${FIREBASE_URL}cancelJob?jobId=${j.key}&requesterId=${uid}';

    try {
      print(http.get(url));
    } catch (e) {
      print('Error 45: ' + e.message);
    }
  }

  Future<String> getMapStyle() async {
    return await rootBundle.loadString("assets/map_styles/light_map.json");
  }

  Future<DraftOrder> createDraft(Address origin, Address destination, List<ShoppingItem> shopItems, RouteMode mode) async {
    DraftOrder rtnVal;
    String url = '${FIREBASE_URL}draftOrder?origin=${json.encode(origin.toMap())}&destination=${json.encode(destination.toMap())}&mode=${mode.toString().split(".").last}&uid=${uid}&items=${ShoppingItem.listToString(shopItems)}';
    url = Uri.encodeFull(url);
    try {
      http.Response response = await http.get(url);
      if (response.statusCode != 200)
        throw('Status code: ' + response.statusCode.toString());
      dynamic obj = json.decode(response.body);
      if (obj["error"] != null && obj["key"] == null)
        return null;
      await draftRef.child(obj["key"]).once().then((DataSnapshot snapshot){
        rtnVal = DraftOrder.fromSnapshot(snapshot);
      }).catchError((onError) => {
        print(onError)
      });
    } catch (e) {
      print('Error 47: ' + e.message);
      return null;
    }
    return rtnVal;
  }

  Future<bool> isOnlineDriverAvailable(LatLng origin, LatLng destination) async {
    String url = '${FIREBASE_URL}checkAvailableDriver?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}';
    http.Response response = await http.get(url);
    if (response.statusCode != 200)
      throw('Status code: ' + response.statusCode.toString());
    return response.body.trim().toLowerCase() == 'true';
  }

  Future<List<Prediction>> getAutoCompleter(String autoCompleterText) async {
    const String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    const String SalzburgCenterLoc = "47.8262658,13.0127823";
    final String request = '$baseUrl?input=${Uri.encodeComponent(autoCompleterText)}&location=$SalzburgCenterLoc&radius=1000&key=$GOOGLE_API_KEY_PLACES_AND_DIRECTIONS';
    List<Prediction> predictions = List();
    try {
      http.Response response = await http.get(request);
      dynamic obj = json.decode(response.body);
      for (int i = 0; i < obj["predictions"].length; i++) {
        predictions.add(Prediction.fromJson(obj["predictions"][i]));
      }
    } catch (e) {
      print(e);
    }
    return predictions;
  }
}