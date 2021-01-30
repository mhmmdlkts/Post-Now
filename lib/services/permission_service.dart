import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/enums/permission_typ_enum.dart';

class PermissionService {
  static const platform = const MethodChannel('postnow/permission');

  static Future<bool> positionIsNotGranted(PermissionTypEnum permissionTyp, {BuildContext context}) async {
    PermissionStatus permissionStatus;

    switch (permissionTyp) {
      case PermissionTypEnum.LOCATION:
        permissionStatus = await Permission.locationWhenInUse.status;
        if (permissionStatus.isGranted)
          return false;
        permissionStatus = await Permission.locationWhenInUse.request();
        break;

      case PermissionTypEnum.LOCATION_ALWAYS:
        permissionStatus = await Permission.locationAlways.status;
        if (permissionStatus.isGranted)
          return false;
        if (Platform.isIOS) {
          await platform.invokeMethod('alwaysLocation');
          permissionStatus = await Permission.locationWhenInUse.status; // Keep it locationWhenInUse!
        } else
          permissionStatus = await Permission.locationAlways.request();
        break;

      case PermissionTypEnum.NOTIFICATION:
        permissionStatus = await Permission.notification.status;
        if (permissionStatus.isGranted)
          return false;
        permissionStatus = await Permission.notification.request();
        break;

      case PermissionTypEnum.CAMERA:
        permissionStatus = await Permission.camera.status;
        if (permissionStatus.isGranted)
          return false;
        permissionStatus = await Permission.camera.request();
    }
    if (permissionStatus == null)
      return true;

    if (context != null && (permissionStatus == PermissionStatus.permanentlyDenied || permissionStatus == PermissionStatus.denied)) {
      bool val = await _allowDialog(context, permissionTyp);
      if (val) {
        await openAppSettings();
        await _iAmBackDialog(context);
      }
      return await positionIsNotGranted(permissionTyp);
    }
    return !permissionStatus.isGranted;
  }

  static Future<bool> _iAmBackDialog(BuildContext context) async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.I_AM_BACK.TITLE".tr(),
            message: "DIALOGS.I_AM_BACK.MESSAGE".tr(),
            positiveButtonText: "DIALOGS.I_AM_BACK.POSITIVE".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }

  static Future<bool> _allowDialog(BuildContext context, PermissionTypEnum typ) async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.${ typ.toString().toUpperCase()}.TITLE".tr(),
            message: "DIALOGS.${ typ.toString().toUpperCase()}.MESSAGE".tr(),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "DIALOGS.${ typ.toString().toUpperCase()}.ALLOW".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }
}