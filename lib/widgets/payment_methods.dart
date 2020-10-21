import 'package:circular_check_box/circular_check_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:postnow/enums/payment_methods_enum.dart';
import 'package:postnow/models/credit_card.dart';
import 'package:postnow/presentation/my_flutter_app_icons.dart';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:postnow/screens/add_credit_card_screen.dart';


class PaymentMethods extends StatefulWidget {
  final void Function(PaymentMethodsEnum, bool, CreditCard) callback;
  final List<CreditCard> creditCards;
  final User user;
  final double amount;
  double credits;

  PaymentMethods(this.user, this.creditCards, this.callback, this.amount, credits) {
    this.credits = min(this.amount, credits);
  }

  _PaymentMethodsState createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {

  final GlobalKey _contentKey = GlobalKey();
  double _height = 0;
  bool _showCreditCards = false;
  bool _useCredits = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => {
      _height = _contentKey.currentContext.size.height
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'MAPS.PRICE'.tr(namedArgs: {'price': _getPrice().toStringAsFixed(2)}),
          style: TextStyle(fontSize: 24,),
          textAlign: TextAlign.center,
        ),
        Container(
          key: _contentKey,
          child: _showCreditCards? SizedBox(
              height: _height,
              child: _getCreditCards()
          ) : Container(
            margin: EdgeInsets.only(bottom: 10),
            child: _getAllPayMethods(),
          )
        )
      ],
    );
  }

  Widget _getCreditCards() {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.creditCards.length + 2,
        itemBuilder: (context, index) {
          if (index == 0)
            return _getButton((){ setState(() { _showCreditCards = false; });}, icon: Icon(Icons.keyboard_backspace), label: "GO_BACK");
          if (index == widget.creditCards.length + 1)
            return Container(
              margin: EdgeInsets.only(bottom: 10),
              child: _getButton(_addNewCardPressed, icon: Icon(MyFlutterApp.credit_card_with_add_button, color: Colors.indigo,), label: "MAPS.BOTTOM_MENUS.CONFIRM.ADD_NEW_CARD"),
            );
          CreditCard card = widget.creditCards[index - 1];
          return _getButton((){_payWithCreditCard(card);}, creditCard: card);
        },
      ),
    );
  }

  Widget _getAllPayMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.credits > 0 ? _getCheckBox(): Container(height: 20,),
        widget.credits >= widget.amount ? _getButton(_payWithCredits, icon: Icon(MyFlutterApp.coins, color: Colors.orange,), label: PaymentMethodsEnum.CREDITS, disable: _getPrice() != 0) : Container(),
        _getButton(_payWithCash, icon: Icon(MyFlutterApp.money_bill_alt, color: Colors.teal,),label: PaymentMethodsEnum.CASH, disable: _getPrice() == 0),
        _getButton(_payWithPaypal, icon: Icon(MyFlutterApp.paypal, color: Colors.blueAccent,), label: PaymentMethodsEnum.PAYPAL, disable: _getPrice() == 0),
        _getButton(() { setState(() { _showCreditCards = true; }); }, icon: Icon(MyFlutterApp.credit_card_alt, color: Colors.indigo,), label: PaymentMethodsEnum.CREDIT_CARD, disable: _getPrice() == 0),
        _getButton(_payWithKlarna, icon: Icon(MyFlutterApp.klarna__2_, color: Colors.pinkAccent,), label: PaymentMethodsEnum.KLARNA, disable: _getPrice() == 0),
        Platform.isIOS ? _getButton(_payWithApplePay, icon: Icon(MyFlutterApp.apple_pay, color: Colors.black), label: PaymentMethodsEnum.APPLE_PAY, disable: _getPrice() == 0) : Container()
      ],
    );
  }

  Widget _getButton(VoidCallback onPressed, {CreditCard creditCard, Icon icon, label, bool disable = false}) => Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Material(
          color: Colors.transparent,
          child: Opacity (
            opacity: disable? 0.7:1,
            child: Card(
              color: Colors.white,
              child: InkWell(
                onTap: disable? null: () {
                  onPressed.call();
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(
                    children: <Widget>[
                      creditCard != null?creditCard.getCardIcon():icon,
                      Container(width: 30,),
                      Text(creditCard != null?creditCard.getCardNumber():label.toString().toUpperCase().tr())
                    ],
                  ),
                ),
              ),
            ),
          )
      )
  );

  Widget _getCheckBox() {
    return  Row (
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularCheckBox(
          disabledColor: Colors.blueAccent,
          value: _useCredits,
          onChanged: (val) {
            setState(() {
              _useCredits = val;
            });
          },
        ),
        Text('MAPS.BOTTOM_MENUS.CONFIRM.USE_CREDITS'.tr(namedArgs: {'money': widget.credits.toStringAsFixed(2)}))
      ],
    );
  }

  double _getPrice() => widget.amount - (_useCredits ?widget.credits:0.0);

  void _payWithCreditCard(CreditCard creditCard) {
    widget.callback.call(PaymentMethodsEnum.CREDIT_CARD, _useCredits, creditCard);
  }

  void _payWithKlarna() {
    widget.callback.call(PaymentMethodsEnum.KLARNA, _useCredits, null);
  }

  void _payWithPaypal() {
    widget.callback.call(PaymentMethodsEnum.PAYPAL, _useCredits, null);
  }

  void _payWithApplePay() {
    widget.callback.call(PaymentMethodsEnum.APPLE_PAY, _useCredits, null);
  }

  void _payWithCredits() {
    widget.callback.call(PaymentMethodsEnum.CREDITS, _useCredits, null);
  }

  void _payWithCash() {
    widget.callback.call(PaymentMethodsEnum.CASH, _useCredits, null);
  }

  void _addNewCardPressed() async {
    CreditCard result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddCreditCardScreen(widget.user))
    );
    if (result != null) {
      widget.creditCards.add(result);
      _payWithCreditCard(result);
      if (mounted)
        setState(() { });
    }
  }
}