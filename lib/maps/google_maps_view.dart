import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/firebase_service.dart';

class GoogleMapsView extends StatefulWidget {
  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  List<Driver> drivers = List();
  Driver driver;
  DatabaseReference driverRef;

  @override
  void initState() {
    super.initState();
    driver = Driver();
    driverRef = FirebaseDatabase.instance.reference().child('drivers');

    driverRef.onChildChanged.listen(_onDriversDataChanged);
    driverRef.onChildAdded.listen(_onDriversDataAdded);
  }

  void _onDriversDataAdded(Event event) {
    setState(() {
      drivers.add(Driver.fromSnapshot(event.snapshot));
    });
  }

  void _onDriversDataChanged(Event event) {
    var old = drivers.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      drivers[drivers.indexOf(old)] = Driver.fromSnapshot(event.snapshot);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body:Stack(
          children: <Widget> [
            SizedBox(
              width: MediaQuery.of(context).size.width,  // or use fixed size like 200
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                    target: LatLng(47.823995, 13.023349),
                    zoom: 10
                ),
                onMapCreated: (map) {},
                markers: _createMarker(),
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                  width: MediaQuery.of(context).size.width,  // or use fixed size like 200
                  height: MediaQuery.of(context).size.height/4,
                  child: Column(
                    children: <Widget>[
                      RaisedButton(
                        onPressed: () {
                        },
                        child: const Text('Sign Out', style: TextStyle(fontSize: 20)),
                      ),
                    ]
                  )
              )
            )
        ]
      ),
    );
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in drivers) {
      if (driver.isOnline)
        markers.add(driver.getMarker());
    }
    return markers;
  }
}