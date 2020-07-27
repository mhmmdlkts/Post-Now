import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  SharedPreferences prefs;
  static const String PREFS_CUSTOMER_ID = "Braintree_CustomerId";

  Future<bool> openPayMenu(double amount) async {
    String customerId = await getCustomerId();
    var url = "https://us-central1-post-now-f3c53.cloudfunctions.net/braintree_getToken" + (customerId == null ? "" : "?customerId=" + customerId);
    String token;
    print(url);
    try {
      http.Response response = await http.get(url);
      token = response.body;
    } catch (e) {
      print(e.message);
    }

    assert (token != null);

    final request = BraintreeDropInRequest(
      amount: amount.toString(),
      clientToken: token,
      collectDeviceData: true,
      cardEnabled: true,
      tokenizationKey: "sandbox_v26s63jp_rdjzd3ff9xx4j5sc",
      googlePaymentRequest: BraintreeGooglePaymentRequest(
        totalPrice: amount.toString(),
        currencyCode: 'EUR',
        billingAddressRequired: false,
      ),
      paypalRequest: BraintreePayPalRequest(
        amount: amount.toString(),
        displayName: 'Post Now',
        currencyCode: 'EUR',
      ),
    );
    BraintreeDropInResult result = await BraintreeDropIn.start(request);

    if (result == null)
      print('Selection was canceled.');

    String nonce = result.paymentMethodNonce.nonce;
    url = "https://us-central1-post-now-f3c53.cloudfunctions.net/braintree_sendNonce?nonce=" + nonce + "&amount=" + amount.toString();
    String transactionId;
    try {
      http.Response response = await http.get(url);
      transactionId = response.body;
    } catch (e) {
      print(e.message);
      print(false);
    }
    if (await checkTransaction(transactionId))
      return true;
    else
      return false;
  }

  Future<String> getCustomerId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs.getString(PREFS_CUSTOMER_ID) ?? await createCustomerId();
  }

  Future<String> createCustomerId() async {
    if (prefs == null)
      prefs = await SharedPreferences.getInstance();
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    var url = "https://us-central1-post-now-f3c53.cloudfunctions.net/braintree_createCustomerId?uid=" + user.uid;
    try {
      http.Response response = await http.get(url);
      String customerId = response.body;
      prefs.setString(PREFS_CUSTOMER_ID, customerId);
      print(customerId);
      if (customerId.toLowerCase() == 'false')
        return null;
    } catch (e) {
      print(e.message);
      return null;
    }
    return null;
  }

  Future<bool> checkTransaction(String transactionId) async {
    if (transactionId.toLowerCase() == 'false')
      return false;
    var url = "https://us-central1-post-now-f3c53.cloudfunctions.net/braintree_checkTransaction?transactionId=" + transactionId;
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