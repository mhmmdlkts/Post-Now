import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/enums/payment_methods_enum.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/models/credit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class PaymentService {
  SharedPreferences prefs;
  static const String PREFS_CUSTOMER_ID = "Braintree_CustomerId";

  Future<bool> pay(double amount, String uid, String draftId, bool useCredits, double credits, PaymentMethodsEnum paymentMethod, CreditCard creditCard) async {

    if (useCredits) {
      if (credits < amount)
        amount = num.parse((amount - credits).toStringAsFixed(2));
      else
        amount = 0.0;
    }
    Set<String> params = Set();
    params.add("draftId=" + draftId);
    params.add("nonceAmount=" + amount.toString());
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
        if (!Platform.isIOS)
          return false;
        // TODO implementire Apple Pay
        break;
      case PaymentMethodsEnum.PAYPAL:
        params.add('paymentMethod=${4}');
        final request = BraintreePayPalRequest(
        amount: amount.toString(),
        displayName: 'APP_NAME'.tr(),
        currencyCode: 'EUR',
        );
        final result = await Braintree.requestPaypalNonce(await _getBrainTreeToken(), request);
        params.add("nonce=" + result.nonce);
        break;
      case PaymentMethodsEnum.CREDIT_CARD:
        params.add('paymentMethod=${5}');
        if (creditCard == null)
          return false;
        BraintreePaymentMethodNonce result = await Braintree.tokenizeCreditCard(
            await _getBrainTreeToken(), creditCard.createBraintreeCreditCardRequest());
        params.add("nonce=" + result.nonce);
        break;
      case PaymentMethodsEnum.KLARNA:
        params.add('paymentMethod=${6}');
        return false;
        // TODO implementire Apple Pay
        break;
    }
    return await _callPayApi(params);
  }

  Future<bool> _callPayApi(Set<String> params) async{
    String url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/pay?";
    params.forEach((element) {
      url += "&" + element;
    });
    print(url);
    try {
      http.Response response = await http.get(url);
      return response.body.toLowerCase().trim() == 'true';
    } catch (e) {
      print('Error 45: ' + e.message);
      return null;
    }
  }

  Future<String> _getBrainTreeToken() async {
    String customerId = await getCustomerId();
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

  Future<String> getCustomerId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs.getString(PREFS_CUSTOMER_ID) ?? await createCustomerId();
  }

  Future<String> createCustomerId() async {
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