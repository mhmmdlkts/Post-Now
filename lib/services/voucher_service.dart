import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/environment/global_variables.dart';

class VoucherService {
  String _lastTriedCode;

  Future<Map<String, dynamic>> enCashVoucher(String code, String uid) async {
    if (code == _lastTriedCode)
      return null;
    _lastTriedCode = code;
    String url = '${FIREBASE_URL}enCashVoucher?code=$code&userId=$uid';

    try {
      http.Response response = await http.get(url);
      if (response.statusCode != 200)
        throw('Status code: ' + response.statusCode.toString());
      return json.decode(response.body);
    } catch (e) {
      print('Error 46: ' + e.message);
    }
    return null;
  }

  String getErrorMessage(int code) {
    switch(code) {
      case 0:
        return 'VOUCHER.ERROR.NO_ERROR'.tr();
      case 1:
        return 'VOUCHER.ERROR.ALREADY_USED'.tr();
      case 2:
        return 'VOUCHER.ERROR.NOT_EXIST'.tr();
    }
    return 'VOUCHER.ERROR.NOT_KNOWN'.tr();
  }

  double convertToNumber(String s) {
    if(s == null) {
      return null;
    }
    return double.parse(s, (e) => null);
  }
}