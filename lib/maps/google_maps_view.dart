import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/core/service/firebase_service.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/job.dart';
import 'package:postnow/core/service/model/user.dart';
import 'package:postnow/core/service/payment_service.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:postnow/ui/view/all_orders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import '../chat_screen.dart';

const double EURO_PER_KM = 0.96;
const double EURO_START  = 5.00;
const bool TEST = false;

enum MenuTyp {
  FROM_OR_TO,
  NO_DRIVER_AVAILABLE,
  CALCULATING_DISTANCE,
  CONFIRM,
  SEARCH_DRIVER,
  PAYMENT_WAITING,
  PAYMENT_DECLINED,
  ACCEPTED,
  PACKAGE_PICKED,
  COMPLETED
}

class GoogleMapsView extends StatefulWidget {
  final String uid;
  GoogleMapsView(this.uid);

  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState(uid);
}


const String mapsApiKey = "AIzaSyDUr-GnemethAnyLSQZc6YPsT_lFeBXaI8";

class _GoogleMapsViewState extends State<GoogleMapsView> {
  BitmapDescriptor packageLocationIcon, driverLocationIcon, homeLocationIcon;
  List<String> orders = List();
  List<Driver> drivers = List();
  Set<Polyline> polylines = Set();
  List<LatLng> routeCoords;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: mapsApiKey);
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey: mapsApiKey);
  Marker packageMarker, destinationMarker;
  DatabaseReference driverRef, jobsRef, userRef;
  GoogleMapController _mapController;
  TextEditingController originTextController, destinationTextController;
  MenuTyp menuTyp;
  double price = 0.0;
  double totalDistance = 0.0;
  String originAddress, destinationAddress;
  Position myPosition;
  LatLng origin, destination;
  Job job;
  Driver myDriver;
  bool isDestinationButtonChosen = false;
  String uid;
  User me = User();

  _GoogleMapsViewState(uid) {
    this.uid = uid;
  }

  getRoute() async {
    polylines.clear();

    setNewCameraPosition(origin, destination, false);

    await setRoutePolyline(origin, destination, RouteMode.driving);
    menuTyp = MenuTyp.CONFIRM;

    setState(() {
      calculatePrice();
    });

  }

  void onPositionChanged(Position position) {
    setMyPosition(position);
  }

  double calculateDistance (List<LatLng> coords) {
    if (coords == null)
      return 0.0;
    double totalDistance = 0.0;
    for (int i = 0; i < coords.length - 1; i++) {
      totalDistance += _coordinateDistance(
          coords[i],
          coords[i + 1]
      );
    }
    return totalDistance;
  }

  void calculatePrice () {
    totalDistance = calculateDistance(routeCoords);
    double calcPrice = EURO_START;
    calcPrice += totalDistance * EURO_PER_KM;
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
    getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => {
      packageLocationIcon = BitmapDescriptor.fromBytes(value)
    });
    getBytesFromAsset('assets/driver_map_marker.png', 150).then((value) => {
      driverLocationIcon = BitmapDescriptor.fromBytes(value)
    });
    getBytesFromAsset('assets/home_map_marker.png', 130).then((value) => {
      homeLocationIcon = BitmapDescriptor.fromBytes(value)
    });

    getMyPosition();

    SharedPreferences.getInstance().then((value) => {
        if (value.containsKey('orders'))
          orders = value.getStringList('orders')
      }
    );

    originTextController = new TextEditingController(text: '');
    destinationTextController = new TextEditingController(text: '');

    driverRef = FirebaseDatabase.instance.reference().child('drivers');

    driverRef.onChildAdded.listen(_onDriversDataAdded);
    driverRef.onChildChanged.listen(_onDriversDataChanged);

    jobsRef = FirebaseDatabase.instance.reference().child('jobs');
    jobsRef.onChildAdded.listen(_onJobsDataAdded);
    jobsRef.onChildChanged.listen(_onJobsDataChanged);

    userRef = FirebaseDatabase.instance.reference().child('users').child(uid);

    userRef.once().then((snapshot) => {
      me = User.fromSnapshot(snapshot),
    });

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

  void _onJobsDataAdded(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    if (snapshot == job) {
      userRef.child("orders").child(snapshot.key).set(snapshot.key);
    }
  }

  void _onJobsDataChanged(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    if (snapshot == job) {
      print(snapshot.status);
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
                polylines.clear();
              }
            }
          }
          break;
        case Status.PACKAGE_PICKED:
          setState(() {
            menuTyp = MenuTyp.PACKAGE_PICKED;
          });
          break;
        case Status.FINISHED:
          setState(() {
            menuTyp = MenuTyp.COMPLETED;
          });
          break;
        case Status.CANCELLED:
          polylines.clear();
          packageMarker = null;
          setNewCameraPosition(LatLng(myPosition.latitude, myPosition.longitude), null, true);
          clearJob();
          break;
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
      _mapController = controller;
    });
  }

  _navigateToPaymentsAndGetResult(BuildContext context, double price) async {
    setState(() {
      menuTyp = MenuTyp.PAYMENT_WAITING;
    });

    if (TEST) {
      setState(() {
        addJobToPool('test_transaction_id');
        menuTyp = MenuTyp.SEARCH_DRIVER;
      });
      return;
    }

    PaymentService().openPayMenu(price, uid).then((result) => {
      setState(() {
        if (result != null) {
          addJobToPool(result);
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
        title: Text(("APP_NAME".tr()), style: TextStyle(color: Colors.white)),
        brightness: Brightness.dark,
        iconTheme:  IconThemeData(color: Colors.white),
      ),
      body:Stack(
          children: <Widget> [
            googleMapsWidget(),
            getTopMenu(),
            getBottomMenu(),
          ]
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Stack(
                children: <Widget>[
                  Text("SETTINGS".tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                  Positioned(
                    bottom: 0,
                    child: Text(me.getName(), style: TextStyle(fontSize: 22, color: Colors.white)),
                  )
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('MAPS.SIDE_MENU.MY_ORDERS'.tr()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllOrders(uid)),
                );
              },
            ),
            ListTile(
              title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr()),
              onTap: () {
                FirebaseService().signOut();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: getFloatingActionButton(),
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
    if (packageMarker != null)
      markers.add(packageMarker);
    if (destinationMarker != null)
      markers.add(destinationMarker);
    return markers;
  }

  Widget googleMapsWidget() => SizedBox(
    width: MediaQuery.of(context).size.width,  // or use fixed size like 200
    height: MediaQuery.of(context).size.height,
    child: GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(47.0, 13.0),
        zoom: 4
      ),
      onMapCreated: onMapCreated,
      zoomControlsEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      polylines: polylines,
      markers: _createMarker(),
      onTap: (t) {
        setMarker(t);
      },
    ),
  );

  setMarker(t, {String address}) {
    if (menuTyp != MenuTyp.FROM_OR_TO && menuTyp != null)
      return;
    if (t is Position)
      t = LatLng(t.latitude, t.longitude);
    setState(() {
      polylines.clear();
      LatLng chosen = t;
      if (isDestinationButtonChosen) {
        destination = chosen;
        destinationMarker = Marker(
            markerId: MarkerId("package"),
            position: chosen,
            icon: homeLocationIcon,
            onTap: () => {
              setState(() {
                isDestinationButtonChosen = true;
              })
            }
        );
        setPlaceForDestination(address: address);
      } else {
        origin = chosen;
        packageMarker = Marker(
            markerId: MarkerId("destination"),
            position: chosen,
            icon: packageLocationIcon,
            onTap: () => {
              setState(() {
                isDestinationButtonChosen = false;
              })
            }
        );
        setPlaceForOrigin(address: address);
      }
      if (isDestinationButtonChosen? origin == null : destination == null)
        isDestinationButtonChosen = !isDestinationButtonChosen;
    });
  }

  Widget getTopMenu() {
    if (menuTyp != null && menuTyp != MenuTyp.FROM_OR_TO)
      return Container();
    return Positioned(
      top: 0,
      width: MediaQuery
          .of(context)
          .size
          .width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          getDesOrOriginButton("assets/marker_buttons/package_selected.png",
              "assets/marker_buttons/package_not_selected.png",
              "assets/marker_buttons/package_selected_onPressed.png",
              "assets/marker_buttons/package_not_selected_onPressed.png",
              originAddress, false),
          getDesOrOriginButton("assets/marker_buttons/home_selected.png",
              "assets/marker_buttons/home_not_selected.png",
              "assets/marker_buttons/home_selected_onPressed.png",
              "assets/marker_buttons/home_not_selected_onPressed.png",
              destinationAddress, true),
        ],
      ),
    );
  }

    Widget getBottomMenu() {
      switch (menuTyp) {
        case MenuTyp.FROM_OR_TO:
          return fromOrToMenu();
        case MenuTyp.NO_DRIVER_AVAILABLE:
          return noDriverAvailableMenu();
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
        case MenuTyp.PACKAGE_PICKED:
          return packagePicked();
        case MenuTyp.COMPLETED:
          return jobCompleted();
      }
      return Container();
    }

    Widget jobCompleted() => Positioned(
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
                          title: Text('MAPS.BOTTOM_MENUS.PACKAGE_PICKED.PACKAGE_DELIVERED'.tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('OK'.tr()),
                              onPressed: () {
                                clearJob();
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

    Widget packagePicked() => Positioned(
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': myDriver.name})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.PACKAGE_PICKED.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: openMessageScreen,
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': myDriver.name})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.JOB_ACCEPTED.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: openMessageScreen,
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

                ]
            )
        )
    );

    Widget noDriverAvailableMenu() => Positioned(
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
                          title: Text('MAPS.NO_AVAILABLE_DRIVER_MESSAGE'.tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('OK'.tr()),
                              onPressed: () {
                                clearJob();
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
                          title: Text('MAPS.PRICE'.tr(namedArgs: {'price': price.toString()})),
                          subtitle: Text('MAPS.BOTTOM_MENUS.CONFIRM.FROM_TO'.tr(namedArgs: {'from': originAddress, 'to': destinationAddress})),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('CANCEL'.tr()),
                              onPressed: () {
                                setState(() {
                                  polylines.clear();
                                  if (destination != null && origin != null)
                                    menuTyp = MenuTyp.FROM_OR_TO;
                                });
                              },
                            ),
                            FlatButton(
                              child: Text('ACCEPT'.tr()),
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
                          title: Text("MAPS.BOTTOM_MENUS.SEARCH_DRIVER.ORDER_ACCEPTED".tr()),
                          subtitle: Text("MAPS.BOTTOM_MENUS.SEARCH_DRIVER.STATUS".tr()),
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
                          title: Text('MAPS.BOTTOM_MENUS.PAYMENT_WAITING.PAYMENT_WAITING'.tr()),
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
                          title: Text('MAPS.BOTTOM_MENUS.CALCULATING_DISTANCE.CALCULATING_DISTANCE'.tr()),
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
                          title: Text('MAPS.BOTTOM_MENUS.PAYMENT_DECLINED.PAYMENT_DECLINED'.tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('CLOSE'.tr()),
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

    void addJobToPool(transactionId) async {
      job = Job(
          name: "Robot",
          userId: uid,
          transactionId: transactionId,
          vehicle: Vehicle.CAR,
          price: price,
          origin: origin,
          destination: destination,
          originAddress: originAddress,
          destinationAddress: destinationAddress
      );
      orders.add(json.encode(job.toJson()));
      SharedPreferences.getInstance().then((value) => {
          value.setStringList('orders', orders)
        }
      );
      jobsRef.push().set(job.toMap());
    }

    void setNewCameraPosition(LatLng first, LatLng second, bool centerFirst) {
      if (first == null || _mapController == null)
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
      _mapController.animateCamera(cameraUpdate);
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
        routeCoords = await googleMapPolyline.getCoordinatesWithLocation (
            origin: origin,
            destination: destination,
            mode: mode
        );
      }
      drawPolyline(Colors.black26, [Colors.blue, Colors.blueAccent], routeCoords);
    }

    initPolyline(Color color) {
      setState(() {
        polylines.add(Polyline(
            polylineId: PolylineId("Route_all"),
            visible: true,
            points: routeCoords,
            width: 3,
            color: color,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
    }

    drawPolyline(Color firstColor, List<Color> colors, List<LatLng> routeCoords) async {
      int colorIndex = 0;
      while(isDrawableRoute()) {
        polylines.clear();
        initPolyline(firstColor);
        await new Future.delayed(Duration(milliseconds : 200));
        await drawPolylineHelper(colorIndex, firstColor, colors[colorIndex++ % colors.length], routeCoords);
        await new Future.delayed(Duration(milliseconds : 500));
      }
      polylines.clear();
    }

    bool isDrawableRoute() => menuTyp == MenuTyp.CONFIRM || menuTyp == MenuTyp.CALCULATING_DISTANCE;

    drawPolylineHelper(int id, Color firstColor, Color color, List<LatLng> routeCoords) async {

      for (int i=0; i < routeCoords.length-1 && isDrawableRoute(); i++) {
        // await addLineToPolyline(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), i%2==0);
        await drawOneLine(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), 20);
      }
      setState(() {
        polylines.add(Polyline(
            polylineId: PolylineId("LastPiece_" + id.toString()),
            visible: true,
            points: routeCoords,
            width: 3,
            color: color,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
    }

    addLineToPolyline(LatLng p1, LatLng p2, Color color, PolylineId id, bool ce) async {
      // TODO Bozuk method
      const int pieceDuration = 1000;
      await drawOneLine(p1, p2, ce ? Colors.redAccent: Colors.green, PolylineId(id.value + "__" ), pieceDuration);
      const double routePieceDistance = 0.02;
      double d = _coordinateDistance(p1, p2);
      double x = d / routePieceDistance;
      double lat = (p1.latitude - p2.latitude).abs() / x;
      double long = (p1.longitude - p2.longitude).abs() / x;
      int c = x.floor();
      List<LatLng> subList = List();
      List<LatLng> subSubList = List();

      if (c == 0) {
        await drawOneLine(
            p1, p2, color, PolylineId(id.value + "_first"),
            pieceDuration);
        return;
      }

      if (p1.latitude > p2.latitude) {
        color = Colors.deepPurple;
        for (int i = 0; i < c; i++) {
          LatLng latLng = LatLng(
              p2.latitude + (i * lat),
              p1.longitude > p2.longitude ? (p2.longitude + (i * long)) : (p2
                  .longitude - (i * long))
          );
          subSubList.add(latLng);
        }
        subList.addAll(subSubList);
        if (x > 0) {
          await drawOneLine(p2, subList.first, color, PolylineId(id.value + "_last3"), pieceDuration);
        }
      } else {
        for (int i = 0; i < c; i++) {
          LatLng latLng = LatLng(
              p1.latitude + (i * lat),
              p1.longitude > p2.longitude ? (p1.longitude - (i * long)) : (p1
                  .longitude + (i * long))
          );
          subSubList.add(latLng);
        }
        subList.addAll(subSubList);
        if (x > 0 && subList.isNotEmpty) {
          await drawOneLine(p2, subList.last, color, PolylineId(id.value + "_last2"), pieceDuration);
        }
      }

      for (int i = 0; i < subList.length-1; i++) {
        await drawOneLine(subList[i], subList[i+1], color, PolylineId(id.value + "_" + i.toString()), pieceDuration);
      }
      if (x > 0 && subList.isNotEmpty) {
        await drawOneLine(p2, subList.last, color, PolylineId(id.value + "_last"), pieceDuration);
      }
    }

    drawOneLine(LatLng p1, LatLng p2, Color color, PolylineId id, int duration) async {
      setState(() {
        polylines.add(Polyline(
            polylineId: id,
            visible: true,
            points: [p1, p2],
            width: 3,
            color: color,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
      await new Future.delayed(Duration(milliseconds : duration));
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
      if (myPosition == null) { // first time
        setNewCameraPosition(new LatLng(pos.latitude, pos.longitude), null, true);
      }
      myPosition = pos;
    }

    void openMessageScreen() async {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Chat_Screen(job.key, myDriver.name, false))
      );
    }

    getDesOrOriginButton(String activePath, String notActivePath, String activePathPressed, String notActivePathPressed, String label, bool isDestination) {

      onTapButton() {
        setNewCameraPosition(isDestination? destination : origin, null, true);
        if (isDestinationButtonChosen != isDestination) {
          setState(() {
            isDestinationButtonChosen = isDestination;
          });
        }
      }

      return Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              new Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  Material(
                    shadowColor: Colors.black,
                    borderOnForeground: false,
                    type: MaterialType.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(130, 230)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        onTapButton();
                      }, // handle your image tap here
                      child: Image.asset(
                        (isDestination
                            ? isDestinationButtonChosen
                            : !isDestinationButtonChosen)
                            ? activePath
                            : notActivePath,
                        width: MediaQuery.of(context).size.width * (0.4),
                        height: 100.0,
                      ),
                    ),
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 30.0,
                    width: 30.0,
                    child: (isDestination? destination != null : origin != null) ? FittedBox(
                      child: FloatingActionButton(
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          setState(() {
                            if (isDestination) {
                              destination = null;
                              setPlaceForDestination();
                            } else {
                              origin = null;
                              setPlaceForOrigin();
                            }
                            isDestinationButtonChosen = isDestination;
                          });
                        },
                        child: Icon(Icons.clear, color: Colors.white),
                      ),
                    ) : null,
                  ),

                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 5),
                color: Colors.transparent,
                width: (MediaQuery.of(context).size.width) * (0.4),
                child: Theme(
                  data: new ThemeData(
                    primaryColor: Colors.black,
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () async {
                      onTapButton();
                      Prediction p = await PlacesAutocomplete.show(
                        hint: "MAPS.TYPE_ADDRESS".tr(),
                        // startText: isDestination ? destinationTextController.text : originTextController.text,
                        context: context,
                        apiKey: mapsApiKey,
                        logo: Image.asset("assets/none.png"),
                        mode: Mode.overlay, // Mode.fullscreen
                        language: 'de',
                        components: [new Component(Component.country, "at")]);
                      LatLng wrotePlace = await predictionToLatLng(p);
                      setMarker(wrotePlace, address: predictionToString(p));
                    },
                    maxLines: null,
                    controller: isDestination
                        ? destinationTextController
                        : originTextController,
                    cursorColor: Colors.white,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textInputAction: TextInputAction.done,
                    decoration: new InputDecoration(
                      hintText: isDestination
                          ? "MAPS.DESTINATION_ADDRESS".tr()
                          : "MAPS.PACKAGE_ADDRESS".tr(),
                      hintStyle: TextStyle(color: Colors.white70),
                      contentPadding: new EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: new OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(8.0),
                        ),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.lightBlue,
                    ),
                  ),
                )
              ),
              (isDestination == isDestinationButtonChosen && myPosition != null) ?
              Container(
                    width: (MediaQuery
                        .of(context)
                        .size
                        .width) * (0.4),
                    child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                  ),
                  onPressed: (){
                    setMarker(LatLng(myPosition.latitude, myPosition.longitude));
                  },
                  color: Colors.blue,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text("MAPS.CURRENT_LOCATION".tr(), style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                  )
                )
              ) : Container(),
              (isDestination == isDestinationButtonChosen) ?
              getLastAddress(1) : Container(),
              (isDestination == isDestinationButtonChosen) ?
              getLastAddress(2) : Container(),
            ],
          )
      );
    }

    String predictionToString(Prediction p) => p.description ;

    Future<LatLng> predictionToLatLng(Prediction p) async {
      if (p == null)
        return null;
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
      final double lat = detail.result.geometry.location.lat;
      final double lng = detail.result.geometry.location.lng;
      return LatLng(lat, lng);
    }

    void setPlaceForOrigin({String address}) async {
      commonPiece();
      if (origin == null) {
        originTextController.clear();
        return;
      }
      if (address == null) {
        List<Placemark> originPlaceMarks = await Geolocator().placemarkFromCoordinates(origin.latitude, origin.longitude);
        originAddress = placeMarkToString(originPlaceMarks[0]);
      } else {
        originAddress = address;
      }
      originTextController.text = originAddress;
    }

    void setPlaceForDestination({String address}) async {
      commonPiece();
      if (destination == null) {
        destinationTextController.clear();
        return;
      }
      if (address == null) {
        List<Placemark> destinationPlaceMarks = await Geolocator()
            .placemarkFromCoordinates(
            destination.latitude, destination.longitude);
        destinationAddress = placeMarkToString(destinationPlaceMarks[0]);
      } else {
        destinationAddress = address;
      }
      destinationTextController.text = destinationAddress;
    }

    void commonPiece() {
      setState(() {
        menuTyp = destination != null && origin != null ? MenuTyp.FROM_OR_TO : null;
        menuTyp = destination != null && origin != null ? MenuTyp.FROM_OR_TO : null;
      });
    }

    String placeMarkToString(Placemark p) {
      return p.name + " " + p.subAdministrativeArea + "/" + p.country;
    }

  getFloatingActionButton() {
      if (menuTyp == null)
        return positionFloatingActionButton();
      switch (menuTyp) {
        case MenuTyp.FROM_OR_TO:
          return goToPayFloatingActionButton();
      }
      return null;
  }

  positionFloatingActionButton() => FloatingActionButton(
    onPressed: () {
      if (myPosition == null)
        return;
      LatLng pos = LatLng(myPosition.latitude, myPosition.longitude);
      setNewCameraPosition(pos, null, true);
    },
    child: Icon(Icons.my_location, color: Colors.white,),
    backgroundColor: Colors.lightBlueAccent,
  );

    bool isOnlineDriverAvailable() {
      for (int i = 0; i < drivers.length; i++) {
        if (drivers[i].isOnline)
          return true;
      }
      return false;
    }

  void goToPayFloatingActionButton() => FloatingActionButton(
    onPressed: () {
      setState(() {
        if (!isOnlineDriverAvailable()) {
          menuTyp = MenuTyp.NO_DRIVER_AVAILABLE;
          return;
        }
        menuTyp = MenuTyp.CALCULATING_DISTANCE;
        getRoute();
      });
    },
    child: Icon(Icons.arrow_forward, color: Colors.white,),
    backgroundColor: Colors.redAccent,
  );

  void clearJob() {
    setState(() {
      originTextController.clear();
      destinationTextController.clear();
      polylines = Set();
      isDestinationButtonChosen = false;
      totalDistance = 0.0;
      price = 0.0;
      packageMarker = null;
      destinationMarker = null;
      routeCoords = null;
      myDriver = null;
      originAddress = null;
      destinationAddress = null;
      destination = null;
      origin = null;
      job = null;
      menuTyp = null;
    });
  }

  getLastAddress(int i) {
    if (orders.length < i)
      return Container();
    Job order = Job.fromJson(json.decode(orders[orders.length-i]));
    return Container(
      margin: EdgeInsets.only(bottom: 5),
        width: (MediaQuery
            .of(context)
            .size
            .width) * (0.4),
        child: RaisedButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            onPressed: () {
              setMarker(isDestinationButtonChosen ? order.destination : order.origin,
                  address: isDestinationButtonChosen ? order.destinationAddress : order.originAddress);
            },
            color: Colors.redAccent,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text(isDestinationButtonChosen
                        ? order.destinationAddress
                        : order.originAddress,
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,),
                  )
                ]
            )
        )
    );
  }
}