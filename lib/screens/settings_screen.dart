import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/models/user.dart' as u;
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/services/legal_service.dart';
import 'package:postnow/services/settings_service.dart';

import 'contact_form_screen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  SettingsScreen(this.user);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  u.User _user;
  SettingsService _settingsService;
  bool _customInvoiceNeedsSave = false;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(widget.user.uid, _allSaved);
    _settingsService.userRef.onValue.listen((event) {
      setState(() {
        _user = u.User.fromSnapshot(event.snapshot);
        _settingsService.accountNameCtrl.text = _user.name;
        _settingsService.accountPhoneCtrl.text = _user.phone;
        _settingsService.accountEmailCtrl.text = _user.email;
        _settingsService.settings = _user.settings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('SETTINGS'.tr()),
      ),
      child: _settingsService.settings == null? CupertinoSettings( items: <Widget>[CupertinoActivityIndicator()]):
      CupertinoSettings(
        items: <Widget>[
          CSHeader('SETTINGS_SCREEN.ACCOUNT.TITLE'.tr()),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountNameCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.NAME_HINT".tr(), textCapitalization: TextCapitalization.words),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountEmailCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.EMAIL_HINT".tr()),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountPhoneCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.PHONE_HINT".tr()),
          CSHeader('SETTINGS_SCREEN.INVOICE.TITLE'.tr()),
          CSControl(
            nameWidget: Text('SETTINGS_SCREEN.INVOICE.ENABLE'.tr()),
            contentWidget: CupertinoSwitch(
              value: _settingsService.settings.enableCustomInvoiceAddress,
              onChanged: (bool value) {_settingsService.toggleCustomAddress();},
            ),
            style: CSWidgetStyle(
              icon: Icon(Icons.work_outline),
            ),
            addPaddingToBorder: false,
          ),
          Visibility(
            visible: _settingsService.settings.enableCustomInvoiceAddress,
            child: Column(
              children: [
                CupertinoTextField(controller: _settingsService.settings.invoiceNameCtrl, placeholder: "SETTINGS_SCREEN.INVOICE.NAME_HINT".tr(),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (val) {
                      if (!_customInvoiceNeedsSave)
                        setState(() {
                          _customInvoiceNeedsSave = true;
                        });
                    }),
                CupertinoTextField(controller: _settingsService.settings.invoiceAddressCtrl, placeholder: "SETTINGS_SCREEN.INVOICE.ADDRESS_HINT".tr(),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) {
                    if (!_customInvoiceNeedsSave)
                      setState(() {
                        _customInvoiceNeedsSave = true;
                      });
                  },
                  minLines: 3, maxLines: 5,),
              ],
            ),
          ),
          Visibility(
            visible: _customInvoiceNeedsSave,
            child: CSButton(CSButtonType.DEFAULT_CENTER, "SAVE".tr(), (){ _settingsService.commitSettings(); }),
          ),
          CSDescription(
            'SETTINGS_SCREEN.INVOICE.DESCRIPTION'.tr(),
          ),
          CSSpacer(showBorder: false),
          CSButton(CSButtonType.DEFAULT_CENTER, "SETTINGS_SCREEN.SOFTWARE_LICENCES".tr(), (){ LegalService.openLicences();}),
          CSSpacer(showBorder: false),
          CSButton(CSButtonType.DESTRUCTIVE, "SETTINGS_SCREEN.SIGN_OUT".tr(),  (){ AuthService().signOut();})
        ],
      ),
    );
  }

  void _allSaved() {
    setState(() {
      _customInvoiceNeedsSave = false;
    });
  }

  _showAreYouCantChangeDialog() async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "WARNING".tr(),
            message: "DIALOGS.SETTINGS.YOU_CANT_CHANGE.MESSAGE".tr(),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "DIALOGS.SETTINGS.YOU_CANT_CHANGE.CONTACT".tr(),
          );
        }
    );
    if (val == null || !val)
      return false;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactFormScreen(widget.user)),
    );
  }
}