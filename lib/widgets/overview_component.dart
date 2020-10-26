

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/services/time_service.dart';

class OverviewComponent extends StatelessWidget {
  final Job job;
  final double maxWidth;
  final double maxHeight;
  final BitmapDescriptor bitmapDescriptorDestination;
  final BitmapDescriptor bitmapDescriptorOrigin;
  final _textStyle = TextStyle(fontSize: 16);
  final VoidCallback voidCallback;
  OverviewComponent(this.job, this.maxWidth, this.maxHeight, this.bitmapDescriptorDestination, this.bitmapDescriptorOrigin, { Key key, this.voidCallback }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: voidCallback,
      child: Column(
          children: [
            Stack(
              children: [
                _halfMapsWidget(job, false),
                _halfMapsWidget(job, true),
              ],
            ),
            Stack(
              children: [
                Container(
                    padding: EdgeInsets.only(right: voidCallback != null?50:10, left: 10, top: 10, bottom: 10),
                    width: maxWidth,
                    color: Colors.grey.shade300,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Text(getStartTimeReadable(), style: _textStyle,),
                                ),
                                Container(
                                  child: Text(getPrice(), style: _textStyle,),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  child: Text(getJobStatus(), style: _textStyle,),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                ),
                Visibility(
                    visible: voidCallback != null,
                    child:
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Icon(Icons.arrow_forward_ios, size: 30,),
                    )
                )
              ],
            )
          ]
      ),
    );
  }

  String getPrice() {
    return job.price.total.toString() + " €";
  }

  String getStartTimeReadable() {
    DateTime dt = job.startTime;
    if (dt == null)
      return "";
    dt = dt.toLocal();
    String y = dt.year.toString();
    String m = dt.month.toString();
    String d = dt.day.toString();
    String h = dt.hour.toString();
    String min = dt.minute.toString();
    if (d.length == 1) h = "0$d";
    if (m.length == 1) h = "0$m";
    if (h.length == 1) h = "0$h";
    if (min.length == 1) min = "0$min";
    return '$d.$m.$y $h:$min';
  }

  String getJobStatus() {
    String status = "MODELS.JOB." + job.status.toString().split(".")[1];
    switch(job.status) {
      case Status.FINISHED:
        return "";
    }
    return status.tr();
  }

  List<Widget> drawLine(length) {
    List<Widget> lines = List();
    double filled = 6;
    double empty = 3;
    double stroke = 2.5;
    double  total = 0;
    Color c = Colors.deepPurple;
    while (total <= length) {
      lines.add(Container(color: c, height: stroke, width: filled, margin: EdgeInsets.only(right: empty)));
      total += filled + empty;
    }
    return lines;
  }

  Widget _halfMapsWidget(Job job, bool isDestination) => Column(
    children: [
      Stack(
        children: [
          SizedBox(
            width: maxWidth / (isDestination?2:1),
            height: maxHeight,
            child: GestureDetector(
              onTap: null,
              child: GoogleMap(
                onTap: null,
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                    target: _jobToLatlng(job, isDestination), zoom: 14
                ),
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                compassEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                markers: _createMarker(job, isDestination.toString()),
              ),
            )
          ),
        ],
      ),
    ],
  );

  _createMarker(Job job, String id) {
    return {
      Marker(
        markerId: MarkerId(job.key + id + "1"),
        position: job.destinationAddress.coordinates,
        icon: bitmapDescriptorDestination,
      ),
      Marker(
        markerId: MarkerId(job.key + id + "2"),
        position: job.originAddress.coordinates,
        icon: bitmapDescriptorOrigin,
      )
    };
  }

  LatLng _jobToLatlng(Job job, bool isDestination) {
    LatLng centerLatLng = isDestination?job.destinationAddress.coordinates:job.originAddress.coordinates;
    return LatLng(centerLatLng.latitude, centerLatLng.longitude - (isDestination?0:0.000025*maxWidth));
  }
}