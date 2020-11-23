import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/screens/direct_job_overview_screen.dart';
import 'package:postnow/services/overview_service.dart';
import 'package:postnow/widgets/overview_component.dart';

class OverviewScreen extends StatefulWidget {
  final BitmapDescriptor bitmapDescriptorDestination;
  final BitmapDescriptor bitmapDescriptorOrigin;
  final User _user;
  final OverviewService overviewService;
  OverviewScreen(this._user, this.bitmapDescriptorDestination, this.bitmapDescriptorOrigin, {this.overviewService});

  @override
  _OverviewScreen createState() => _OverviewScreen(_user, overviewService: overviewService);
}

class _OverviewScreen extends State<OverviewScreen> {
  final User _user;
  OverviewService _overviewService;
  bool _isLoading = true;

  _OverviewScreen(this._user, {OverviewService overviewService}) {
    if (overviewService != null && overviewService.orders.isNotEmpty) {
      _overviewService = overviewService;
      return;
    }
    _overviewService = OverviewService(_user.uid);
    _overviewService.initOrderList().then((val) => setState((){}));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
          setState(() {
            _isLoading = false;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: Text("OVERVIEW.TITLE".tr()),
          centerTitle: false,
          brightness: Brightness.dark,
        ),
        body: _isLoading?Container():ListView.separated(
          shrinkWrap: true,
          itemCount: _overviewService.orders.length,
          itemBuilder: (BuildContext ctxt, int index) => getOrderWidget(_overviewService.orders[index]),
          separatorBuilder: (_,i) => Divider(height: 0,thickness: 0.5,),
        )
    );
  }

  getOrderWidget(Job job) {
    return Container(
      child: OverviewComponent(job, MediaQuery.of(context).size.width, 200, widget.bitmapDescriptorDestination, widget.bitmapDescriptorOrigin, voidCallback: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DirectJobOverview(_user, job, widget.bitmapDescriptorOrigin, widget.bitmapDescriptorDestination)),
        );
      }),
      margin: EdgeInsets.only(bottom: 0),
    );
  }
}