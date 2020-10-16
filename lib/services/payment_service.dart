import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/environment/api_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  SharedPreferences prefs;
  static const String PREFS_CUSTOMER_ID = "Braintree_CustomerId";

  Future<Map<String, dynamic>> openPayMenu(double amount, String uid, String draftId, bool useCredits, double credits) async {
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
    if (useCredits) {
      if (credits < amount)
        amount = num.parse((amount - credits).toStringAsFixed(2));
      else
        amount = 0.0;
    }
    print(amount);
    String nonce = "";
    if (amount != 0) {
      const String currencyCode = 'EUR';
      final request = BraintreeDropInRequest(
        amount: amount.toString(),
        clientToken: token,
        collectDeviceData: true,
        cardEnabled: true,
        tokenizationKey: BRAINTREE_TOKENIZATION_KEY,
        googlePaymentRequest: BraintreeGooglePaymentRequest(
          totalPrice: amount.toString(),
          currencyCode: currencyCode,
          billingAddressRequired: false,
        ),
        paypalRequest: BraintreePayPalRequest(
          amount: amount.toString(),
          displayName: 'APP_NAME'.tr(),
          currencyCode: currencyCode,
        ),
      );
      BraintreeDropInResult result = await BraintreeDropIn.start(request);

      if (result == null) {
        print('Selection was canceled.');
        return null;
      }

      nonce = result.paymentMethodNonce.nonce;
    }

    url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/braintree_sendNonce?nonce=" + nonce + "&draftId=" + draftId + "&nonceAmount=" + amount.toString() + "&userId=" + uid + "&useCredits=" + useCredits.toString();

    Map<String, dynamic> transactionIds;
    try {
      http.Response response = await http.get(url);
      if (response.body == 'false') {
        return null;
      }
      transactionIds = json.decode(response.body);
    } catch (e) {
      print('Error 45: ' + e.message);
      return null;
    }
    return transactionIds;
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

  Future<bool> checkTransaction(String transactionId) async {
    if (transactionId.toLowerCase() == 'false')
      return false;
    var url = "https://europe-west1-post-now-f3c53.cloudfunctions.net/braintree_checkTransaction?transactionId=" + transactionId;
    try {
      http.Response response = await http.get(url);
      print(response.body);
      return response.body.toLowerCase() == 'true';
    } catch (e) {
      print(e.message);
      return false;
    }
  }
}