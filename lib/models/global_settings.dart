import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class GlobalSettings {
  final TextEditingController invoiceAddressCtrl = TextEditingController(text: '');
  final TextEditingController invoiceNameCtrl = TextEditingController(text: '');
  bool enableCustomInvoiceAddress = false;

  GlobalSettings();

  GlobalSettings.fromSnapshot(DataSnapshot snapshot) {
    enableCustomInvoiceAddress = snapshot.value["enableCustomInvoiceAddress"];
    invoiceAddressCtrl.text = snapshot.value["customInvoiceAddress"];
    invoiceNameCtrl.text = snapshot.value["customInvoiceName"];
  }

  GlobalSettings.fromJson(Map json) {
    enableCustomInvoiceAddress = json["enableCustomInvoiceAddress"];
    invoiceAddressCtrl.text = json["customInvoiceAddress"];
    invoiceNameCtrl.text = json["customInvoiceName"];
  }

  Map<String, dynamic> toJson() => {
    "enableCustomInvoiceAddress": enableCustomInvoiceAddress,
    "customInvoiceAddress": invoiceAddressCtrl.text,
    "customInvoiceName": invoiceNameCtrl.text,
  };
}