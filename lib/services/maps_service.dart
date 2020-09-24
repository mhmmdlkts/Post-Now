import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/environment/global_variables.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import 'package:postnow/models/job.dart';

class MapsService with WidgetsBindingObserver {
  final DatabaseReference jobsChatRef = FirebaseDatabase.instance.reference().child('jobs_chat');
  final DatabaseReference driverRef = FirebaseDatabase.instance.reference().child('drivers');
  final DatabaseReference driverInfoRef = FirebaseDatabase.instance.reference().child('drivers_info');
  final DatabaseReference jobsRef = FirebaseDatabase.instance.reference().child('jobs');
  DatabaseReference userRef;
  final String uid;

  MapsService(this.uid) {
    userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
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

  void setNewCameraPosition(GoogleMapController controller, LatLng first, LatLng second, bool centerFirst) {
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
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target:
          LatLng(
              (first.latitude + second.latitude) / 2,
              (first.longitude + second.longitude) / 2
          ),
              zoom: coordinateDistance(first, second)));

      LatLngBounds bound = _latLngBoundsCalculate(first, second);
      cameraUpdate = CameraUpdate.newLatLngBounds(bound, 70);
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

  Future<String> getPhoneNumberFromDriver(Job j) async {
    String phone;
    await driverInfoRef.child(j.driverId).child("phone").once().then((value) => {
      phone = value.value
    });
    return phone;
  }

  Future<String> getNameFromDriver(Job j) async {
    String name;
    await driverRef.child(j.driverId).child("name").once().then((value) => {
      name = value.value,
    });
    return name;
  }

  Future<double> getCredit() async {
    double credit;
    await userRef.child("credit").once().then((value) => {
      credit = value.value + 0.0,
    });
    return credit;
  }

  Future<double> getCancelFeeAmount() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();
    return remoteConfig.getDouble(FIREBASE_REMOTE_CANCEL_FEE_KEY);
  }

  void cancelJob(Job j) async {
    String url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/cancelJob?jobId=" + j.key + "&requesterId=" + uid;

    try {
      print(http.get(url));
    } catch (e) {
      print('Error 45: ' + e.message);
    }
  }
}