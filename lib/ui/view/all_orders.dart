import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:postnow/core/service/model/job.dart';
import 'package:easy_localization/easy_localization.dart';

class AllOrders extends StatefulWidget {
  final String uid;
  AllOrders(this.uid);

  @override
  _AllOrders createState() => _AllOrders(uid);
}

class _AllOrders extends State<AllOrders> {
  DatabaseReference driversRef, jobsRef, userRef;
  String uid;
  List<Job> orders = List();

  _AllOrders(this.uid);

  @override
  void initState() {
    super.initState();
    driversRef = FirebaseDatabase.instance.reference().child('drivers');
    jobsRef = FirebaseDatabase.instance.reference().child('jobs');
    userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
    initOrderList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: Text("Gecmis Siparisler"),
          centerTitle: false,
          brightness: Brightness.dark,
        ),
        body: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (BuildContext ctxt, int index) => getOrderWidget(orders[index]),
        )
    );
  }

  getOrderWidget(Job job) {
    if (job == null)
      return;
    double padding = 7;
    return Card(
        margin: EdgeInsets.only(top: 12, right: 16, left: 16),
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.date_range, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.start_time.toString()),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.directions_car, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.getDriverId()),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.home, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.originAddress),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.directions, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.destinationAddress),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.euro_symbol, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.price.toString()),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.error_outline, color: Colors.black54,),
                    Container(width: padding),
                    Expanded(
                      child: Text(job.getStatusMessageKey().tr()),
                    )
                  ],
                ),
              ],
            )
        )
    );
  }

  void initOrderList() async {
    await userRef.child("orders").once().then((snapshot) => {
      snapshot.value.forEach((k, v) {
        findJob(k);
      })
    });
  }

  void findJob(String key) async {
    jobsRef.child(key).once().then((snapshot) => {
      addOrderToList(Job.fromSnapshot(snapshot)),
    });
  }

  void addOrderToList(Job job) async {
    if (job.driverId == null) {
      setState(() {
        orders.add(job);
      });
      return;
    }
    driversRef.child(job.driverId).once().then((snapshot) => {
      setState(() {
        orders.add(job);
        orders.last.driverId = snapshot.value["name"];
      })
    });
  }
}