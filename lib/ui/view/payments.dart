import 'package:flutter/material.dart';
import 'package:postnow/ui/view/credit_card.dart';

class Payments extends StatefulWidget {
  @override
  _PaymentsState createState() => _PaymentsState();
}

class _PaymentsState extends State<Payments> {

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
    return Scaffold (
      appBar: AppBar(
        title: Text("Ödeme Secenekleri"),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(4),
        children: <Widget>[
          Card(
              child: InkWell (
                onTap: () {
                  _navigateToPaymentsAndGetResult(context, CreditCards());
                },
                child :Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                      "Credit Card",
                      style: TextStyle(fontSize: 22.0)
                  ),
                ),
              )
          ),
          Card(
              child: InkWell (
                onTap: () {
                  Navigator.pop(context, true);
                },
                child :Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                      "PayPal",
                      style: TextStyle(fontSize: 22.0)
                  ),
                ),
              )
          ),
          Card(
            child: InkWell (
              onTap: () {
                Navigator.pop(context, false);
              },
              child :Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "Iptal",
                style: TextStyle(fontSize: 22.0)
                ),
              ),
            )
          ),
        ],
      )
    );
  }
}