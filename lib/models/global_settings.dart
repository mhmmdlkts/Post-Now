import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;

class GlobalSettings {
  final TextEditingController invoiceAddressCtrl = TextEditingController(text: '');
  final TextEditingController invoiceNameCtrl = TextEditingController(text: '');
  String langCode;
  bool enableCustomInvoiceAddress = false;

  GlobalSettings({this.langCode}) {
    if (langCode == null)
      langCode = ui.window.locale.languageCode;
  }

  GlobalSettings.fromSnapshot(DataSnapshot snapshot) {
    langCode = snapshot.value["lang"];
    enableCustomInvoiceAddress = snapshot.value["enableCustomInvoiceAddress"];
    invoiceAddressCtrl.text = snapshot.value["customInvoiceAddress"];
    invoiceNameCtrl.text = snapshot.value["customInvoiceName"];
  }

  GlobalSettings.fromJson(Map json) {
    langCode = json["lang"];
    enableCustomInvoiceAddress = json["enableCustomInvoiceAddress"];
    invoiceAddressCtrl.text = json["customInvoiceAddress"];
    invoiceNameCtrl.text = json["customInvoiceName"];
  }

  Map<String, dynamic> toJson() => {
    "lang": langCode,
    "enableCustomInvoiceAddress": enableCustomInvoiceAddress,
    "customInvoiceAddress": invoiceAddressCtrl.text,
    "customInvoiceName": invoiceNameCtrl.text,
  };

  Future<bool> existAddressInfo() async => enableCustomInvoiceAddress && (invoiceAddressCtrl?.text?.isNotEmpty??false) && (invoiceNameCtrl?.text?.isNotEmpty??false);
}