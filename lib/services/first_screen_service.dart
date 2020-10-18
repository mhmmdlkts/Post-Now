import 'package:postnow/environment/global_variables.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:flutter/material.dart';

class FirstScreenService {

  Future<void> showUpdateAvailableDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('DIALOGS.UPDATE_AVAILABLE.TITLE'.tr()),
          content: SingleChildScrollView(
            child: Text('DIALOGS.UPDATE_AVAILABLE.BODY'.tr()),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('DIALOGS.UPDATE_AVAILABLE.BUTTON'.tr()),
              onPressed: () {
                  StoreRedirect.redirect();
              },
            ),
          ],
        );
      },
    );
  }
}