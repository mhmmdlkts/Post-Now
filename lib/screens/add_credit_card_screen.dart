import 'package:credit_card/credit_card_form.dart';
import 'package:credit_card/credit_card_model.dart';
import 'package:credit_card/credit_card_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:postnow/models/CreditCard.dart';
import 'package:postnow/services/add_credit_card_service.dart';

class AddCreditCardScreen extends StatefulWidget {
  final User user;
  AddCreditCardScreen(this.user);

  @override
  _AddCreditCardScreenState createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  AddCreditCardService _addCreditCardService;
  CreditCardModel _cardModel = CreditCardModel("","","","",false);

  @override
  void initState() {
    super.initState();
    _addCreditCardService = AddCreditCardService(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        title: Text("APP_NAME".tr()),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
      ),
      body: Material(
          child: ListView(
            children: [
              CreditCardWidget(
                cardNumber: _cardModel.cardNumber,
                expiryDate: _cardModel.expiryDate,
                cardHolderName: _cardModel.cardHolderName,
                cvvCode: _cardModel.cvvCode,
                showBackView: _cardModel.isCvvFocused,
                cardBgColor: Colors.black,
                height: 175,
                textStyle: TextStyle(color: Colors.lightGreen),
                width: MediaQuery.of(context).size.width,
                animationDuration: Duration(milliseconds: 1000),
              ),
              CreditCardForm(
                themeColor: Colors.red,
                onCreditCardModelChange: (CreditCardModel data) {
                  setState(() {
                    _cardModel = data;
                  });
                },
              ),
              FlatButton(
                onPressed: !_isCardReadyToSave() ? null: () async {
                  CreditCard card = CreditCard.fromModel(_cardModel);
                  await _addCreditCardService.saveCreditCard(card);
                  Navigator.pop(context, card);
                },
                child: Text("CHECKOUT".tr())
              )
            ],
          )
      ),
    );
  }

  bool _isCardReadyToSave() {
    return _cardModel.cvvCode.length > 2 &&
        _cardModel.expiryDate.length >= 5 && _cardModel.expiryDate.contains("/") &&
        _cardModel.cardNumber.length > 12 && _cardModel.cardHolderName.length > 2;
  }

}