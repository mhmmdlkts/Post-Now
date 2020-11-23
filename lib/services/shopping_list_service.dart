import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/shopping_item.dart';

class ShoppingListService {
  DatabaseReference shopListRef = FirebaseDatabase.instance.reference().child('jobs');
  List<ShoppingItem> shoppingList = List();
  int remain = 0;
  final String jobKey;
  List<VoidCallback> onListChanged = List();

  ShoppingListService(this.jobKey, onListChanged) {
    subscribe(onListChanged);
    shopListRef = shopListRef.child(jobKey).child("shoppingItems");
    shopListRef.onValue.listen((event) {
      shoppingList = ShoppingItem.jsonToList(event.snapshot.value);
      _countRemains();
      _sortList();
      _notify();
    });
  }

  changeItemStatus(int id, bool status) {
    shopListRef.child(id.toString()).child("isChecked").set(status);
    _sortList();
    _notify();
  }

  subscribe(VoidCallback listener) => onListChanged.add(listener);

  _sortList() => shoppingList.sort((item, _) => item.isChecked?1:0 );

  _notify() => onListChanged.forEach((element) async => element.call());

  _countRemains () => remain = shoppingList.where((element) => !element.isChecked).length;
}