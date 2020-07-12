import 'dart:math' show cos, sqrt, asin;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as direction;
import 'package:postnow/core/service/model/driver.dart';

const double EURO_PER_KM = 0.96;
const double EURO_START  = 5.00;

enum MenuTyp {
  FROM_OR_TO,
  CONFIRM,
  PAY
}

class GoogleMapsView extends StatefulWidget {
  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  List<Driver> drivers = List();
  Set<Polyline> polylines = {};
  List<LatLng> routeCoords;
  final places = direction.GoogleMapsDirections(apiKey: "<Your-API-Key>");
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey: "AIzaSyDUr-GnemethAnyLSQZc6YPsT_lFeBXaI8");
  Marker choosedMarker;
  Driver driver;
  DatabaseReference driverRef;
  GoogleMapController _controller;
  MenuTyp menuTyp;
  double price = 0;
  double totalDistance = 0.0;
  String originAddress, destinationAddress;

  getRoute(LatLng point, bool fromCurentLoc) async {
    polylines = {};
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng current = LatLng(position.latitude, position.longitude);
    LatLng origin = fromCurentLoc ? current : point;
    LatLng destination = fromCurentLoc ? point : current;
    routeCoords = await googleMapPolyline.getCoordinatesWithLocation(
        origin: origin,
        destination: destination,
        mode: RouteMode.driving);

    List<Placemark> destination_placemarks = await Geolocator().placemarkFromCoordinates(destination.latitude, destination.longitude);
    List<Placemark> origin_placemarks = await Geolocator().placemarkFromCoordinates(origin.latitude, origin.longitude);
    setState(() {

        polylines.add(Polyline(
            polylineId: PolylineId("test"),
            visible: true,
            points: routeCoords,
            width: 2,
            color: Colors.deepOrange,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
        calculatePrice();

        originAddress = origin_placemarks[0].name;
        destinationAddress = destination_placemarks[0].name;
      });

  }

  void calculateDistance () {
    totalDistance = 0.0;
    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += _coordinateDistance(
        routeCoords[i].latitude,
        routeCoords[i].longitude,
        routeCoords[i + 1].latitude,
        routeCoords[i + 1].longitude,
      );
    }
  }

  void calculatePrice () {
    calculateDistance();
    double calcPrice = EURO_START;
    calcPrice += totalDistance * EURO_PER_KM;;
    setState(() {
      price = num.parse(calcPrice.toStringAsFixed(2));
    });
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

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



  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;

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
                    zoom: 11
                ),
                onMapCreated: onMapCreated,
                myLocationEnabled: true,
                polylines: polylines,
                markers: _createMarker(),
                onTap: (t) {
                  setState(() {
                    menuTyp = MenuTyp.FROM_OR_TO;
                    choosedMarker = Marker(
                        markerId: MarkerId("choosed"),
                        position: LatLng(t.latitude, t.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
                    );
                  });
                },
              ),
            ),
            Positioned(
                bottom: 0,
                child: getBottomMenu()
            )
          ]
      ),
    );
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in drivers)
      if (driver.isOnline)
        markers.add(driver.getMarker());
    if (choosedMarker != null)
      markers.add(choosedMarker);
    return markers;
  }

  Widget getBottomMenu() {
    switch (menuTyp) {
      case MenuTyp.FROM_OR_TO:
        return fromOrToMenu();
      case MenuTyp.CONFIRM:
        return confirmMenu();
      case MenuTyp.PAY:
        return payMenu();
    }
    return Column();
  }

  Widget fromOrToMenu() => SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height/4,
        child: Column(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  setState(() {
                    LatLng choosed = LatLng(choosedMarker.position.latitude, choosedMarker.position.longitude);
                    getRoute(choosed, false);
                    setState(() {
                      menuTyp = MenuTyp.CONFIRM;
                    });
                  });
                },
                child: const Text('Getir', style: TextStyle(fontSize: 20)),
              ),
              RaisedButton(
                onPressed: () {
                  LatLng choosed = LatLng(choosedMarker.position.latitude, choosedMarker.position.longitude);
                  getRoute(choosed, true);
                  setState(() {
                    menuTyp = MenuTyp.CONFIRM;
                  });
                },
                child: const Text('Götür', style: TextStyle(fontSize: 20)),
              ),
            ]
        )
    );

  Widget confirmMenu() => SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height/4,
      child: Column(
          children: <Widget>[
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.payment),
                    title: Text('Tutar $price €'),
                    subtitle: Text('From: $originAddress\nTo: $destinationAddress'),
                  ),
                  ButtonBar(
                    children: <Widget>[
                      FlatButton(
                        child: const Text('Iptal et'),
                        onPressed: () {
                          setState(() {
                            polylines = {};
                            menuTyp = MenuTyp.FROM_OR_TO;
                          });
                        },
                      ),
                      FlatButton(
                        child: const Text('Onayla'),
                        onPressed: () {
                          setState(() {
                            menuTyp = MenuTyp.PAY;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
      )
  );

  Widget payMenu() => SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height/4,
      child: Column(
          children: <Widget>[
            RaisedButton(
              onPressed: () {

              },
              child: const Text('PayPal', style: TextStyle(fontSize: 20)),
            ),
            RaisedButton(
              onPressed: () {
                setState(() {
                  menuTyp = MenuTyp.FROM_OR_TO;
                  polylines = {};
                });
              },
              child: const Text('Iptal Et', style: TextStyle(fontSize: 20)),
            ),
          ]
      )
  );

}