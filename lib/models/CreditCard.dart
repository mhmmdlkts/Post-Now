import 'package:credit_card/credit_card_model.dart';
import 'package:credit_card_type_detector/credit_card_type_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:postnow/presentation/my_flutter_app_icons.dart';

class CreditCard {
  static final List<Color> randomColors = [Colors.orange, Colors.teal, Colors.indigoAccent, Colors.amber, Colors.blue, Colors.lightGreen, Colors.pinkAccent, Colors.purple];
  String cardNumber;
  String expirationMonth;
  String expirationYear;
  String cardHolder;
  String cvvCode;

  CreditCard({this.cardNumber, this.expirationMonth, this.expirationYear, this.cardHolder, this.cvvCode});

  CreditCard.fromModel(CreditCardModel cardModel) {
    cardNumber = cardModel.cardNumber.replaceAll(" ", "").trim();
    expirationMonth = cardModel.expiryDate.split("/")[0];
    expirationYear = "20" + cardModel.expiryDate.split("/")[1];
    cardHolder = cardModel.cardHolderName;
    cvvCode = cardModel.cvvCode;
  }
  
  CreditCard.fromJson(Map<dynamic, dynamic> json) {
    cardNumber = json["cardNumber"];
    cardHolder = json["cardHolder"];
    expirationMonth = json["expirationMonth"];
    expirationYear = json["expirationYear"];
    cvvCode = json["cvvCode"];
  }

  Map<String, dynamic> toJson() => {
    "cardNumber": cardNumber,
    "expirationMonth": expirationMonth,
    "cardHolder": cardHolder,
    "expirationYear": expirationYear,
    "cvvCode": cvvCode,
  };

  createBraintreeCreditCardRequest() => BraintreeCreditCardRequest(
    cardNumber: cardNumber,
    expirationMonth: expirationMonth,
    expirationYear: expirationYear
  );

  String getCardNumber({bool secure = true}) {
    if (!secure)
      return cardNumber;
    final int hidedChars = cardNumber.length - 4;
    return '*' * hidedChars + cardNumber.substring(hidedChars);
  }

  Icon getCardIcon() {
    CreditCardType typ = detectCCType(cardNumber);
    IconData iconData = MyFlutterApp.credit_card_alt;
    switch (typ) {
      case CreditCardType.mastercard:
        iconData = MyFlutterApp.cc_mastercard;
        break;
      case CreditCardType.visa:
        iconData = MyFlutterApp.cc_visa;
        break;
      case CreditCardType.amex:
        iconData = MyFlutterApp.cc_amex;
        break;
      case CreditCardType.discover:
        iconData = MyFlutterApp.cc_discover;
        break;
    }
    return Icon(iconData, color: _calcColor());
  }

  Color _calcColor() {
    int total = 0;
    for (int i = 0; i < cardNumber.length; i++)
      total += int.parse(cardNumber[i]);
    total *= int.parse(expirationMonth);
    return CreditCard.randomColors[total % CreditCard.randomColors.length];
  }
}