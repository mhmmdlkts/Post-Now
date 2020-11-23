import 'dart:convert';

import 'dart:math';

class ShoppingItem {
  bool isChecked = false;
  String name;
  int id, count;

  ShoppingItem({this.id, this.name, this.count});

  ShoppingItem.copy(ShoppingItem copy) {
    name = copy.name;
    count = copy.count;
  }

    ShoppingItem.fromJson(Map json, this.id) {
      isChecked = json["isChecked"];
      name = json["name"];
      count = json["count"];
    }

    Map toMap() => {
      "isChecked": isChecked,
      "name": name,
      "count": count
    };

    static List<ShoppingItem> jsonToList(List<dynamic> values) {
      if (values == null)
        return null;
      List<ShoppingItem> items = List();
      for (int i = 0; i < values.length; i++)
        items.add(ShoppingItem.fromJson(values[i], i));
      return items;
    }

    static double calcPrice(List<ShoppingItem> items, int freeCount, double price, double samePrice) {
      if (items == null)
        return 0;
      double cost = 0.0;
      items.forEach((element) {cost += calcSamePrice(element, samePrice);});
      return (max(items.length - freeCount, 0) * price) + cost;
    }

    static double calcSamePrice(ShoppingItem item, double samePrice) => max(item.count - 1, 0) * samePrice;

    static String listToString(List<ShoppingItem> items) {
      if (items == null)
        return null;
      return json.encode(items.map((e) => e.toMap()).toList());
    }

    @override
    bool operator == (covariant ShoppingItem other) => name == other.name && count == other.count;
}