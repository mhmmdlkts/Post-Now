import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/widgets/contact_widget.dart';
import 'package:postnow/widgets/overview_component.dart';

class DirectJobOverview extends StatefulWidget {
  final Job job;
  final User user;
  final BitmapDescriptor bitmapDescriptorDestination;
  final BitmapDescriptor bitmapDescriptorOrigin;
  DirectJobOverview(this.user, this.job, this.bitmapDescriptorDestination, this.bitmapDescriptorOrigin);

  @override
  _DirectJobOverviewState createState() => _DirectJobOverviewState();
}

class _DirectJobOverviewState extends State<DirectJobOverview> {
  bool _showContact = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(("OVERVIEW.TITLE".tr()), style: TextStyle(color: Colors.white)),
        brightness: Brightness.dark,
        iconTheme:  IconThemeData(color: Colors.white),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          OverviewComponent(widget.job, MediaQuery.of(context).size.width, 200, widget.bitmapDescriptorDestination, widget.bitmapDescriptorOrigin),
          FlatButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("DIRECT_JOB_OVERVIEW.ANY_PROBLEMS".tr(), style: TextStyle(fontSize: 20),),
                Icon(_showContact?Icons.arrow_drop_down:Icons.arrow_drop_up)
              ],
            ),
            onPressed: () {
              setState(() {
                _showContact = !_showContact;
              });
            },
          ),
          Visibility(
            visible: _showContact,
            child: ContactWidget(widget.user, job: widget.job,)
          ),
        ],
      ),
    );
  }
  
}