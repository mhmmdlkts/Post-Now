import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_form.dart';
import 'package:flutter_credit_card/credit_card_model.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCreditCard extends StatefulWidget {
  @override
  _AddCreditCardState createState() => _AddCreditCardState();
}

class _AddCreditCardState extends State<AddCreditCard> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      Navigator.pop(context, false);
      return false;
    },
    child: Scaffold (
        appBar: AppBar(
          title: Text("Kredi Karti Ekle"),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(4),
          children: <Widget>[
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              cardBgColor: Colors.white,
              height: 180,
              textStyle: TextStyle(color: Colors.pink, fontSize: 15),
              width: MediaQuery.of(context).size.width,
              animationDuration: Duration(milliseconds: 1000),
            ),
            SingleChildScrollView(
              child: CreditCardForm(
                onCreditCardModelChange: onCreditCardModelChange,
              ),
            ),
            RaisedButton(
              onPressed: () { addCard();},
              child: Text("Karti Kaydet"),
            )
          ],
        )
      )
    );
  }

  void addCard() async {
    if (creditCartInfosAreIncorrect())
      return;

    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    while (prefs.containsKey('CreditCard$count'))
      count++;
    List<String> creditCardInfo = [cardNumber, expiryDate, cardHolderName, cvvCode];
    prefs.setStringList('CreditCard$count', creditCardInfo);
    Navigator.pop(context, true);
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  bool creditCartInfosAreIncorrect() {
    if (cardNumber.replaceAll(" ", "").length != 16)
      return true;
    if (expiryDate.replaceAll("/", "").length != 4)
      return true;
    if (cvvCode.length < 3)
      return true;
    if (cardHolderName.length < 3)
      return true;
    return false;
  }
}
