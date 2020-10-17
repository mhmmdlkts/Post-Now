import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

import 'job.dart';

class Price {
  double total;
  double voucher;
  double payed;
  double driverBecomes;

  Price.fromJson(Map json) {
    if (json["total"] != null)
      total = json["total"] + 0.0;
    if (json["voucher"] != null)
      voucher = json["voucher"] + 0.0;
    if (json["payed"] != null)
      payed = json["payed"] + 0.0;
    if (json["driverBecomes"] != null)
      driverBecomes = json["driverBecomes"] + 0.0;
  }

  Map toMap() => {
    "total": total,
    "voucher": voucher,
    "payed": payed,
    "driverBecomes": driverBecomes
  };
}