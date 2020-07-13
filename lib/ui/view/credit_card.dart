import 'package:flutter/material.dart';
import 'package:postnow/ui/view/add_credit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditCards extends StatefulWidget {
  @override
  _CreditCardsState createState() => _CreditCardsState();
}

class _CreditCardsState extends State<CreditCards> {
  List<List<String>> cards = [];

  @override
  void initState() {
    super.initState();
    refreshList();
  }

  _navigateToPaymentsAndGetResult(BuildContext context, Widget widget) async {
    final bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => widget)
    );
    if (result)
      Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold (
        appBar: AppBar(
          title: Text("Kredi Kartlari"),
          centerTitle: false,

        ),
        body: ListView(
          children: [
            getAllCards(),
            Divider(),
            getAddCard()
          ],
        ),
      ),
    );
  }
  
  ListView getAllCards() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return Card(
            child: InkWell (
              onTap: () {
                onTapCreditCard(index);
              },
              child :Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    "${cards[index][0]}",
                    style: TextStyle(fontSize: 22.0)
                ),
              ),
            )
        );
      },
    );
  }

  void onTapCreditCard(int index) {
    print(cards[index]);
    Navigator.pop(context, true);
  }

  Widget getAddCard() {
    return Card(
        child: InkWell (
          onTap: () {
            _navigateToPaymentsAndGetResult(context, AddCreditCard());
          },
          child :Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
                "Yeni Kart Ekle",
                style: TextStyle(fontSize: 22.0)
            ),
          ),
        )
    );
  }

  void refreshList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cards = [];
      int count = 0;
      while (prefs.containsKey('CreditCard$count')) {
        cards.add(prefs.getStringList('CreditCard$count'));
        count++;
      }
    });
  }


}
/*
ListView(
          padding: const EdgeInsets.all(4),
          children: <Widget>[

            Card(
                child: InkWell (
                  onTap: () {
                    Navigator.pop(context, true);
                  },
                  child :Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                        "**** **** **** 9010",
                        style: TextStyle(fontSize: 22.0)
                    ),
                  ),
                )
            ),

          ],
        )
 */