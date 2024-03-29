import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/enums/payment_methods_enum.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/credit_card.dart';
import 'package:postnow/screens/settings_screen.dart';
import 'package:postnow/screens/web_view_screen.dart';
import 'package:postnow/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'global_service.dart';

class PaymentService {
  SharedPreferences prefs;
  SettingsService _settingsService;
  static const String PREFS_CUSTOMER_ID = "Braintree_CustomerId";
  static const platform = const MethodChannel('$POSTNOW_PACKAGE_NAME/payments');
  User user;

  PaymentService(this.user) {
    _settingsService = SettingsService(user.uid, (){});
  }

  Future<bool> _showYouNeedTypYourAddressDialog(BuildContext context, double amount) async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.NEED_TYP_ADDRESS.TITLE".tr(),
            message: "DIALOGS.NEED_TYP_ADDRESS.CONTENT".tr(namedArgs: {'amount': amount.toStringAsFixed(2)}),
            negativeButtonText: "CLOSE".tr(),
            positiveButtonText: "DIALOGS.NEED_TYP_ADDRESS.POSITIVE".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }

  Future<bool> pay(BuildContext context, double amount, String uid, String draftId, bool useCredits, double credits, PaymentMethodsEnum paymentMethod, CreditCard creditCard) async {

    if (useCredits) {
      if (credits < amount)
        amount = num.parse((amount - credits).toStringAsFixed(2));
      else
        amount = 0.0;
    }

    if (amount >= INVOICE_NEEDS_ADDRESS_OVER_AMOUNT_VALUE && !(await _settingsService.existAddressInfo())) {
      final bool result = await _showYouNeedTypYourAddressDialog(context, INVOICE_NEEDS_ADDRESS_OVER_AMOUNT_VALUE);
      if (result) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen(user)),
        );
      }
      return false;
    }

    Set<String> params = Set();
    params.add("draftId=" + draftId);
    params.add("nonceAmount=" + amount.toStringAsFixed(2));
    params.add("userId=" + uid);
    params.add("useCredits=" + useCredits.toString());
    switch (paymentMethod) {
      case PaymentMethodsEnum.CREDITS:
        params.add('paymentMethod=${1}');
        break;
      case PaymentMethodsEnum.CASH:
        params.add('paymentMethod=${2}');
        break;
      case PaymentMethodsEnum.APPLE_PAY:
        params.add('paymentMethod=${3}');
        return await _callPayApiMollie(params, null);
      case PaymentMethodsEnum.PAYPAL:
        params.add('paymentMethod=${4}');
        break;
      case PaymentMethodsEnum.CREDIT_CARD:
        params.add('paymentMethod=${5}');
        break;
      case PaymentMethodsEnum.KLARNA:
        params.add('paymentMethod=${6}');
        break;
    }
    return await _callPayApiMollie(params, context);
  }

  Future<bool> _callPayApiMollie(Set<String> params, BuildContext context) async{
    String url = "${FIREBASE_URL}mollie?";
    params.forEach((element) { url += "&" + element; });
    try {
      http.Response response = await http.get(url);
      final  molliePayUrl = json.decode(response.body)["href"];

      if (context != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewScreen(molliePayUrl, (){}, popOnLoad: "postnow.at",)),
        );
        if (result == true)
          return true;
      } else {
        launch(molliePayUrl);
      }
    } catch (e) {
      print("error 85: " + e);
    }
    return false;
  }
}