import 'dart:math' show cos, sqrt, asin;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as direction;
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/job.dart';
import 'package:postnow/ui/view/payments.dart';

const double EURO_PER_KM = 0.96;
const double EURO_START  = 5.00;
const bool TEST = false;

enum MenuTyp {
  FROM_OR_TO,
  CONFIRM,
  SEARCH_DRIVER,
  ACCEPTED
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
  DatabaseReference driverRef, jobsRef;
  GoogleMapController _controller;
  MenuTyp menuTyp;
  double price = 0;
  double totalDistance = 0.0;
  String originAddress, destinationAddress;
  Position myPosition;
  LatLng origin, destination;
  Job job;
  Driver myDriver;

  getRoute(LatLng point, bool fromCurrentLoc) async {
    polylines = {};
    myPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng current = LatLng(myPosition.latitude, myPosition.longitude);
    origin = fromCurrentLoc ? current : point;
    destination = fromCurrentLoc ? point : current;

    setNewCameraPosition(origin, destination, false);

    List<Placemark> destination_placemarks = await Geolocator().placemarkFromCoordinates(destination.latitude, destination.longitude);
    List<Placemark> origin_placemarks = await Geolocator().placemarkFromCoordinates(origin.latitude, origin.longitude);

    await setRoutePolyline(origin, destination, RouteMode.driving);

    setState(() {

        calculatePrice();

        originAddress = origin_placemarks[0].name;
        destinationAddress = destination_placemarks[0].name;
      });

  }

  void calculateDistance () {
    totalDistance = 0.0;
    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += _coordinateDistance(
        routeCoords[i],
        routeCoords[i + 1]
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

  double _coordinateDistance(LatLng latLng1, LatLng latLng2) {
    if (latLng1 == null || latLng2 == null)
      return 0.0;
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((latLng2.latitude - latLng1.latitude) * p) / 2 +
        c(latLng1.latitude * p) * c(latLng2.latitude * p) * (1 - c((latLng2.longitude - latLng1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void initState() {
    super.initState();
    driver = Driver();
    driverRef = FirebaseDatabase.instance.reference().child('drivers');
    driverRef.onChildChanged.listen(_onDriversDataChanged);
    driverRef.onChildAdded.listen(_onDriversDataAdded);

    jobsRef = FirebaseDatabase.instance.reference().child('jobs');
    jobsRef.onChildChanged.listen(_onJobsDataChanged);
  }

  Future<void> _onDriversDataAdded(Event event) async {
    myPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      Driver snapshot = Driver.fromSnapshot(event.snapshot);
      snapshot.distance = _coordinateDistance(snapshot.getLatLng(), LatLng(myPosition.latitude, myPosition.longitude));
      drivers.add(snapshot);
    });
  }

  Future<void> _onJobsDataChanged(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    print(job.start_time);
    if (snapshot == job) {
      job = snapshot;
      if (job.status == Status.ON_ROAD) {
        setState(() {
          menuTyp = MenuTyp.ACCEPTED;
        });
        if (job.driverId != null) {
          for (Driver d in drivers) {
            if (d.key == job.driverId) {
              myDriver = d;
              setState(() {
                myDriver = d;
                myDriver.isMyDriver = true;
              });
              await addToRoutePolyline(myDriver.getLatLng(), origin, job.getRouteMode());
              setNewCameraPosition(myDriver.getLatLng(), LatLng(myPosition.latitude, myPosition.longitude), false);
            }
          }
        }
      }
    }
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

  _navigateToPaymentsAndGetResult(BuildContext context) async {
    final bool result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Payments())
    );
    if (result == null || !result) {
      // TODO is not payed
    } else {
      setState(() {
        menuTyp = MenuTyp.SEARCH_DRIVER;
      });
    }
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
                    zoom: 9
                ),
                onMapCreated: onMapCreated,
                myLocationEnabled: true,
                polylines: polylines,
                markers: _createMarker(),
                onTap: (t) {
                  if (menuTyp != MenuTyp.FROM_OR_TO && menuTyp != null)
                    return;
                  setState(() {
                    polylines = {};
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
            getBottomMenu(),
          ]
      ),
    );
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in drivers) {
      if (menuTyp != MenuTyp.ACCEPTED) {
        if (driver.isOnline) {
          markers.add(driver.getMarker());
        }
      } else {
        if (driver.isMyDriver) {
          markers.add(driver.getMarker());
        }
      }
    }
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
      case MenuTyp.SEARCH_DRIVER:
        addJobToPool();
        return searchDriverMenu();
    }
    return Container();
  }

  Widget fromOrToMenu() => Positioned(
          bottom: 0,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  RaisedButton(
                    onPressed: () {
                      setState(() {
                        LatLng chosen = LatLng(choosedMarker.position.latitude, choosedMarker.position.longitude);
                        getRoute(chosen, false);
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
        )
      );

  Widget confirmMenu() => Positioned(
      bottom: 0,
      child: SizedBox (
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
                                //menuTyp = MenuTyp.PAY;
                                _navigateToPaymentsAndGetResult(context);
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
      )
  );

  Widget searchDriverMenu() => Positioned(
      bottom: 0,
      child: SizedBox (
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height/4,
          child: Column(
              children: <Widget>[
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.directions_car),
                        title: Text('Siparisiniz Onayladi'),
                        subtitle: Text('Paketinizi teslim edicek soför bekleniyor.'),
                      ),
                      menuTyp != MenuTyp.ACCEPTED ? Padding (
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                        ),
                      ): Container()
                    ],
                  ),
                ),
              ]
          )
      )
  );

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void addJobToPool() async {
    if (job != null)
      return;
    job = Job(
      name: "Ali",
      vehicle: Vehicle.CAR,
      origin: origin,
      destination: destination
    );
    jobsRef.push().set(job.toMap());
  }

  void setNewCameraPosition(LatLng first, LatLng second, bool centerFirst) {
    if (first == null)
      return;
    CameraUpdate cameraUpdate;
    if (second == null) {
      // firsti ortala, zoom sabit
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else if (centerFirst) {
      // firsti ortala, secondu da sigdir
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else {
      // first second arasini ortala, ikisini de sigdir
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target:
            LatLng(
              (first.latitude + second.latitude) / 2,
              (first.longitude + second.longitude) / 2
            ),
            zoom: _coordinateDistance(first, second)));

      LatLngBounds bound = _latLngBoundsCalculate(first, second);
      cameraUpdate = CameraUpdate.newLatLngBounds(bound, 70);
    }
    _controller.moveCamera(cameraUpdate);
  }
   LatLngBounds _latLngBoundsCalculate(LatLng first, LatLng second) {
    bool check = first.latitude < second.latitude;
    return LatLngBounds(southwest: check ? first : second, northeast: check ? second : first);
   }

  Future<void> setRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
    routeCoords = List();
    if (TEST) {
      routeCoords.add(origin);
      routeCoords.add(destination);
    } else {
      routeCoords = await googleMapPolyline.getCoordinatesWithLocation(
      origin: origin,
      destination: destination,
      mode: mode);
    }

    setState(() {
      polylines = Set();
      polylines.add(Polyline(
          polylineId: PolylineId("Route"),
          visible: true,
          points: routeCoords,
          width: 2,
          color: Colors.deepPurpleAccent,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap
      ));
    });
  }

  Future<void> addToRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
    List<LatLng> newRouteCoords = List();

    if (TEST) {
      newRouteCoords.add(origin);
      newRouteCoords.add(destination);
    } else {
      newRouteCoords.addAll(await googleMapPolyline.getCoordinatesWithLocation(
      origin: origin,
      destination: destination,
      mode: mode));
    }

    newRouteCoords.addAll(routeCoords);

    setState(() {
      polylines.add(Polyline(
          polylineId: PolylineId("Route"),
          visible: true,
          points: newRouteCoords,
          width: 2,
          color: Colors.redAccent,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap
      ));
    });
  }
}