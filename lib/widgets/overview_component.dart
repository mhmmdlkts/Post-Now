

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
  final VoidCallback voidCallback;
  final Color _grey = Colors.black45;
  OverviewComponent(this.job, this.maxWidth, this.maxHeight, this.bitmapDescriptorDestination, this.bitmapDescriptorOrigin, { Key key, this.voidCallback }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: voidCallback,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getJobStatus(), style: TextStyle(color: _getStatusTextColor(), fontWeight: FontWeight.bold, fontSize: 20),),
                Text(_getPrice(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500, fontSize: 20),),
              ],
            ),
            Container(height: 15,),
            _getLineWidget(icon: Icons.date_range, msg: "OVERVIEW.MODELS.ORDER_DATE".tr(), val: _getStartDateReadable()),
            _getLineWidget(icon: Icons.access_time_outlined, msg: "OVERVIEW.MODELS.ORDER_TIME".tr(), val: _getStartTimeReadable()),
            _getLineWidget(icon: Icons.pin_drop_outlined, msg: job.originAddress.getAddress()),
            _getLineWidget(icon: Icons.person_pin_circle_outlined, msg: job.destinationAddress.getAddress()),
          ],
        ),
      ),
    );
  }

  String _getPrice() {
    return job.price.total.toStringAsFixed(2) + " €";
  }

  String _getStartTimeReadable() {
    DateTime dt = job.startTime;
    if (dt == null)
      return "";
    dt = dt.toLocal();
    String h = dt.hour.toString();
    String min = dt.minute.toString();
    if (h.length == 1) h = "0$h";
    if (min.length == 1) min = "0$min";
    return '$h:$min';
  }

  String _getStartDateReadable() {
    DateTime dt = job.startTime;
    if (dt == null)
      return "";
    dt = dt.toLocal();
    String y = dt.year.toString();
    String m = dt.month.toString();
    String d = dt.day.toString();
    if (d.length == 1) d = "0$d";
    if (m.length == 1) m = "0$m";
    return '$d.$m.$y';
  }

  String _getJobStatus() {
    String status = "OVERVIEW.MODELS.JOB." + job.status.toString().split(".")[1];
    return status.tr();
  }

  Color _getStatusTextColor() {
    print(job.status.toString());
    switch (job.status) {
      case Status.CANCELLED:
      case Status.DRIVER_CANCELED:
      case Status.CUSTOMER_CANCELED:
        return Colors.red;
      case Status.FINISHED:
        return primaryBlue;
    }
    return Colors.green;
  }

  _getLineWidget({IconData icon, String msg, String val}) => Container(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, color: primaryBlue,),
        Container(width: 10,),
        Text(msg + (val == null?"":": "), style: TextStyle(color: _grey),),
        val!=null?Text(val, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),):Container(),
      ],
    ),
  );
}