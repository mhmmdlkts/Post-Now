import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/credit_card.dart';

class AddCreditCardService {
  DatabaseReference _creditCardRef;
  AddCreditCardService(User user) {
    _creditCardRef = FirebaseDatabase.instance.reference().child('users').child(user.uid).child("creditCards");
  }

  saveCreditCard(CreditCard creditCard) {
    _creditCardRef.child(creditCard.cardNumber).set(creditCard.toJson());
  }
}