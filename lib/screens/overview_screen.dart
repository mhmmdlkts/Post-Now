import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/services/overview_service.dart';

class OverviewScreen extends StatefulWidget {
  final User _user;
  OverviewScreen(this._user);

  @override
  _OverviewScreen createState() => _OverviewScreen(_user);
}

class _OverviewScreen extends State<OverviewScreen> {
  OverviewService _overviewService;
  User _user;

  _OverviewScreen(this._user) {
    _overviewService = OverviewService(_user.uid);
  }

  @override
  void initState() {
    super.initState();
    _overviewService.initOrderList().then((val) => setState((){}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: Text("OVERVIEW.TITLE".tr()),
          centerTitle: false,
          brightness: Brightness.dark,
        ),
        body: ListView.builder(
          shrinkWrap: true,
          itemCount: _overviewService.orders.length,
          itemBuilder: (BuildContext ctxt, int index) => getOrderWidget(_overviewService.orders[index]),
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
                    child: Text(job.startTime.toString()),
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
                    child: Text(job.originAddress.getAddress()),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.directions, color: Colors.black54,),
                  Container(width: padding),
                  Expanded(
                    child: Text(job.destinationAddress.getAddress()),
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
}