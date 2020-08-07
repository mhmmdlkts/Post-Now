import 'dart:math' show cos, sqrt, asin;
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as direction;
import 'package:postnow/core/service/firebase_service.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/job.dart';
import 'package:postnow/core/service/payment_service.dart';
import 'package:postnow/ui/view/payments.dart';
import 'dart:ui' as ui;

import '../chat_screen.dart';

const double EURO_PER_KM = 0.96;
const double EURO_START  = 5.00;
const bool TEST = false;

enum MenuTyp {
  FROM_OR_TO,
  CALCULATING_DISTANCE,
  CONFIRM,
  SEARCH_DRIVER,
  PAYMENT_WAITING,
  PAYMENT_DECLINED,
  ACCEPTED
}

class GoogleMapsView extends StatefulWidget {
  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  BitmapDescriptor packageLocationIcon, driverLocationIcon;
  List<Driver> drivers = List();
  Set<Polyline> polylines = {};
  List<LatLng> routeCoords;
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey: "AIzaSyDUr-GnemethAnyLSQZc6YPsT_lFeBXaI8");
  Marker chosenMarker;
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
    print("---");
    polylines = {};
    Position pos = await getMyPosition();
    LatLng current = LatLng(pos.latitude, pos.longitude);
    origin = fromCurrentLoc ? current : point;
    destination = fromCurrentLoc ? point : current;

    setNewCameraPosition(origin, destination, false);
    List<Placemark> destination_placemarks = await Geolocator().placemarkFromCoordinates(destination.latitude, destination.longitude);
    List<Placemark> origin_placemarks = await Geolocator().placemarkFromCoordinates(origin.latitude, origin.longitude);

    await setRoutePolyline(origin, destination, RouteMode.driving);
    menuTyp = MenuTyp.CONFIRM;

    setState(() {

        calculatePrice();

        originAddress = origin_placemarks[0].name;
        destinationAddress = destination_placemarks[0].name;
      });

  }

  void onPositionChanged(Position position) {
    setMyPosition(position);
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
    getBytesFromAsset('assets/package_map_marker.png', 180).then((value) => {
      packageLocationIcon = BitmapDescriptor.fromBytes(value)
    });
    getBytesFromAsset('assets/driver_map_marker.png', 130).then((value) => {
      driverLocationIcon = BitmapDescriptor.fromBytes(value)
    });

    getMyPosition();

    driver = Driver();
    driverRef = FirebaseDatabase.instance.reference().child('drivers');

    driverRef.onChildAdded.listen(_onDriversDataAdded);
    driverRef.onChildChanged.listen(_onDriversDataChanged);

    jobsRef = FirebaseDatabase.instance.reference().child('jobs');
    jobsRef.onChildChanged.listen(_onJobsDataChanged);

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(onPositionChanged);
  }

  void _onDriversDataAdded(Event event) {
    setState(() {
      Driver snapshot = Driver.fromSnapshot(event.snapshot);
      drivers.add(snapshot);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  void _onJobsDataChanged(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    Position pos = await getMyPosition();
    if (snapshot == job) {
      job = snapshot;
      switch (job.status) {
        case Status.ON_ROAD:
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
                addToRoutePolyline(myDriver.getLatLng(), origin, job.getRouteMode()).then((value) => {
                  setNewCameraPosition(myDriver.getLatLng(), LatLng(pos.latitude, pos.longitude), false)
                });
              }
            }
          }
          break;
        case Status.CANCELLED:
          polylines = {};
          chosenMarker = null;
          setNewCameraPosition(LatLng(pos.latitude, pos.longitude), null, true);
          setState(() {
            menuTyp = null;
          });
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

  _navigateToPaymentsAndGetResult(BuildContext context, double price) async {
    setState(() {
      menuTyp = MenuTyp.PAYMENT_WAITING;
    });

    PaymentService().openPayMenu(price).then((result) => {
      setState(() {
        if (result) {
          addJobToPool();
          menuTyp = MenuTyp.SEARCH_DRIVER;
        } else
          menuTyp = MenuTyp.PAYMENT_DECLINED;
      })
    });
  }


  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: AppBar(
        title: Text("Post Now", style: TextStyle(color: Colors.white)),
        brightness: Brightness.dark,
        iconTheme:  IconThemeData(color: Colors.white),
      ),
      body:Stack(
          children: <Widget> [
            SizedBox(
              width: MediaQuery.of(context).size.width,  // or use fixed size like 200
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                    target: LatLng(0.0, 0.0)
                ),
                onMapCreated: onMapCreated,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                polylines: polylines,
                markers: _createMarker(),
                onTap: (t) {
                  if (menuTyp != MenuTyp.FROM_OR_TO && menuTyp != null)
                    return;
                  setState(() {
                    polylines = {};
                    menuTyp = MenuTyp.FROM_OR_TO;
                    chosenMarker = Marker(
                      markerId: MarkerId("choosed"),
                      position: LatLng(t.latitude, t.longitude),
                      icon: packageLocationIcon,
                    );
                  });
                },
              ),
            ),
            getBottomMenu(),
          ]
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Ayarlar', style: TextStyle(fontSize: 20, color: Colors.white)),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Cikis Yap'),
              onTap: () {
                FirebaseService().signOut();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: menuTyp == null ? FloatingActionButton(
        onPressed: () {
          if (myPosition == null)
            return;
          setNewCameraPosition(LatLng(myPosition.latitude, myPosition.longitude), null, true);
        },
        child: Icon(Icons.my_location, color: Colors.white,),
        backgroundColor: Colors.lightBlueAccent,
      ) : null,
    );
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in drivers) {
      if (menuTyp != MenuTyp.ACCEPTED) {
        if (driver.isOnline) {
          markers.add(driver.getMarker(driverLocationIcon));
        }
      } else {
        if (driver.isMyDriver) {
          markers.add(driver.getMarker(driverLocationIcon));
        }
      }
    }
    if (chosenMarker != null)
      markers.add(chosenMarker);
    return markers;
  }

  Widget getBottomMenu() {
    switch (menuTyp) {
      case MenuTyp.FROM_OR_TO:
        return fromOrToMenu();
      case MenuTyp.CALCULATING_DISTANCE:
        return calcDistanceMenu();
      case MenuTyp.CONFIRM:
        return confirmMenu();
      case MenuTyp.SEARCH_DRIVER:
        return searchDriverMenu();
      case MenuTyp.PAYMENT_WAITING:
        return paymentWaiting();
      case MenuTyp.PAYMENT_DECLINED:
        return paymentDeclined();
      case MenuTyp.ACCEPTED:
        return jobAcceptedMenu();
    }
    return Container();
  }

  Widget jobAcceptedMenu() => Positioned(
      bottom: 0,
      child: SizedBox(
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
                        title: Text('Sürücünüz: ${myDriver.name}'),
                        subtitle: Text("Durum: " + "Paketinizi almaya gidiyor."),
                      ),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: const Text('Mesaj Gönder'),
                            onPressed: messageScreen,
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
                      LatLng chosen = LatLng(chosenMarker.position.latitude, chosenMarker.position.longitude);
                      setState(() {
                        menuTyp = MenuTyp.CALCULATING_DISTANCE;
                      });
                      getRoute(chosen, false);
                    });
                  },
                  child: const Text('Getir', style: TextStyle(fontSize: 20)),
                ),
                RaisedButton(
                  onPressed: () {
                    LatLng chosen = LatLng(chosenMarker.position.latitude, chosenMarker.position.longitude);
                    getRoute(chosen, true);
                    setState(() {
                      menuTyp = MenuTyp.CALCULATING_DISTANCE;
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
                                if (price == 0)
                                  return;
                                _navigateToPaymentsAndGetResult(context, price);
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

  Widget paymentWaiting() => Positioned(
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
                        title: Text('Ödeme bekleniyor.'),
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

  Widget calcDistanceMenu() => Positioned(
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
                        title: Text('Yol hesaplaniyor.'),
                      ),
                      CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              ]
          )
      )
  );

  Widget paymentDeclined() => Positioned(
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
                        leading: Icon(Icons.error_outline),
                        title: Text('Ödeme basarisiz.'),
                      ),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: const Text('Kapat'),
                            onPressed: () {
                              setState(() {
                                menuTyp = MenuTyp.CONFIRM;
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void addJobToPool() async {
    job = Job(
      name: "Robot",
      vehicle: Vehicle.CAR,
      origin: origin,
      destination: destination,
      originAddress: originAddress,
      destinationAddress: destinationAddress
    );
    jobsRef.push().set(job.toMap());
    print(job.key);
  }

  void setNewCameraPosition(LatLng first, LatLng second, bool centerFirst) {
    if (first == null || _controller == null)
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
    _controller.animateCamera(cameraUpdate);
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

  Future<Position> getMyPosition() async {
    if (myPosition != null)
      return myPosition;

    setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

    Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
      myPosition = value,
    });

    return myPosition;
  }

  void setMyPosition(Position pos) {
    if (myPosition == null)
      setNewCameraPosition(new LatLng(pos.latitude, pos.longitude), null, true);
    myPosition = pos;
  }

  void messageScreen() async {
    final bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Chat_Screen(job.key, myDriver.name))
    );
    if (result)
      Navigator.pop(context, result);
  }
}