import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/enums/payment_methods_enum.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/models/credit_card.dart';
import 'package:postnow/screens/web_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import 'global_service.dart';

class PaymentService {
  SharedPreferences prefs;
  static const String PREFS_CUSTOMER_ID = "Braintree_CustomerId";
  static const platform = const MethodChannel('$POSTNOW_PACKAGE_NAME/payments');

  Future<bool> pay(BuildContext context, double amount, String uid, String draftId, bool useCredits, double credits, PaymentMethodsEnum paymentMethod, CreditCard creditCard) async {

    if (useCredits) {
      if (credits < amount)
        amount = num.parse((amount - credits).toStringAsFixed(2));
      else
        amount = 0.0;
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
    String url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/mollie?";
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
    }
    return false;
  }

  Future<bool> _callPayApi(Set<String> params) async{
    String url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/pay?";
    params.forEach((element) {
      url += "&" + element;
    });
    try {
      http.Response response = await http.get(url);
      return response.body.toLowerCase().trim() == 'true';
    } catch (e) {
      print('Error 45: ' + e.message);
      return null;
    }
  }

  Future<String> _callNativeApplePayCode(String amount) async {
    try {
      return (await platform.invokeMethod('applePay', {"amount":amount, "authorization": BRAINTREE_TOKENIZATION_KEY})).toString();
    } on PlatformException catch (e) {
      print("Apple Pay Failed: '${e.message}'.");
    }
    return null;
  }

  Future<String> _getBrainTreeToken() async {
    String customerId = await _getCustomerId();
    var url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/braintree_getToken" + (customerId == null ? "" : "?customerId=" + customerId);
    String token;
    try {
      http.Response response = await http.get(url);
      token = response.body;
    } catch (e) {
      print(e.message);
    }

    assert (token != null);
    return token;
  }

  Future<String> _getCustomerId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs.getString(PREFS_CUSTOMER_ID) ?? await _createCustomerId();
  }

  Future<String> _createCustomerId() async {
    if (prefs == null)
      prefs = await SharedPreferences.getInstance();
    User user = FirebaseAuth.instance.currentUser;
    var url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/braintree_createCustomerId?uid=" + user.uid;
    try {
      http.Response response = await http.get(url);
      String customerId = response.body;
      await prefs.setString(PREFS_CUSTOMER_ID, customerId);
      if (customerId.toLowerCase() == 'false')
        return null;
      else return customerId;
    } catch (e) {
      print(e.message);
      return null;
    }
  }
}