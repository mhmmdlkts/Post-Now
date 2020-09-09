import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/screens/orders_overview_screen.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/services/payment_service.dart';
import 'package:postnow/enums/job_vehicle_enum.dart';
import 'package:postnow/services/maps_service.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/enums/menu_typ_enum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postnow/models/driver.dart';
import 'package:postnow/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:screen/screen.dart';
import 'chat_screen.dart';
import 'dart:convert';
import 'dart:async';


class GoogleMapsView extends StatefulWidget {
  final User user;
  GoogleMapsView(this.user);

  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState(user);
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  final GoogleMapPolyline _googleMapPolyline = new GoogleMapPolyline(apiKey: GOOGLE_DIRECTIONS_API_KEY);
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: GOOGLE_DIRECTIONS_API_KEY);
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final List<Driver> _drivers = List();
  final User user;
  bool isInitialized = false;
  int initCount = 0;
  int initDone = 0;
  Set<Polyline> _polyLines = Set();
  List<String> _orders = List();
  BitmapDescriptor _packageLocationIcon, _driverLocationIcon, _homeLocationIcon;
  TextEditingController originTextController, destinationTextController;
  Marker _packageMarker, _destinationMarker;
  GoogleMapController _mapController;
  List<LatLng> _routeCoordinate;
  MapsService _mapsService;
  double totalDistance = 0.0;
  double price = 0.0;
  MenuTyp menuTyp;
  String originAddress, destinationAddress;
  Position myPosition;
  LatLng origin, destination;
  Job job;
  Driver myDriver;
  bool isDestinationButtonChosen = false;

  _GoogleMapsViewState(this.user) {
    _mapsService = MapsService(user.uid);
  }

  getRoute() async {
    _polyLines.clear();

    _mapsService.setNewCameraPosition(_mapController, origin, destination, false);

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
      totalDistance += _mapsService.coordinateDistance(
          coords[i],
          coords[i + 1]
      );
    }
    return totalDistance;
  }

  void calculatePrice () {
    totalDistance = calculateDistance(_routeCoordinate);
    double calcPrice = EURO_START;
    calcPrice += totalDistance * EURO_PER_KM;
    setState(() {
      price = num.parse(calcPrice.toStringAsFixed(2));
    });
  }

  @override
  void initState() {
    initCount++;
    super.initState();
    Screen.keepOn(true);

    initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => { setState((){
      _packageLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone();
    })});

    initCount++;
    _mapsService.getBytesFromAsset('assets/driver_map_marker.png', 150).then((value) => { setState((){
      _driverLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone();
    })});

    initCount++;
    _mapsService.getBytesFromAsset('assets/home_map_marker.png', 130).then((value) => { setState((){
      _homeLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone();
    })});

    initCount++;
    SharedPreferences.getInstance().then((value) => {
        if (value.containsKey('orders'))
          _orders = value.getStringList('orders'),
        nextInitializeDone()
      }
    );

    originTextController = new TextEditingController(text: '');
    destinationTextController = new TextEditingController(text: '');

    _mapsService.driverRef.onChildAdded.listen(_onDriversDataAdded);
    _mapsService.driverRef.onChildChanged.listen(_onDriversDataChanged);


    _mapsService.jobsRef.onChildAdded.listen(_onJobsDataAdded);

    _mapsService.jobsRef.onChildChanged.listen((Event e) {
      setState(() {
        Job j = Job.fromSnapshot(e.snapshot);
        _onJobsDataChanged(j);
        print('set stattet');
      });
    });

    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onResume: $message');
      final data = message["data"];
      if (data == null)
        return;
      switch (data["typ"]) {
        case "message":
          _showMessageToast(data["key"], data["name"], data["message"]);
          break;
      }

      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    initCount++;
    setJobIfExist().then((value) => {
      nextInitializeDone()
    });

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(onPositionChanged);
    nextInitializeDone();
  }

  nextInitializeDone() {
    initDone++;
    if (initCount == initDone) {
      getMyPosition().then((value) => {
        _mapController.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(value.latitude, value.longitude), zoom: 13)
        )),
        Future.delayed(Duration(milliseconds: 500), () =>
          setState((){
            isInitialized = true;
          })
        )
      });
    }
  }

  void _onDriversDataAdded(Event event) {
    setState(() {
      Driver snapshot = Driver.fromSnapshot(event.snapshot);
      _drivers.add(snapshot);
    });
  }

  void _onJobsDataAdded(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    if (snapshot == job) {
      _mapsService.userRef.child("orders").child(snapshot.key).set(snapshot.key);
    }
  }

  _onJobsDataChanged(Job j) {
    print('aaaaa: ' + j.status.toString());
    print('aaaaa2: ' + j.isJobForMe(user.uid).toString());
    print('aaaaa3: ' + (j.startTime == null).toString());
    if (j == job || (j.isJobForMe(user.uid) && j.finishTime == null)) {
      print(j.status);
      job = j;
      switch (job.status) {
        case Status.ON_ROAD:
          menuTyp = MenuTyp.ACCEPTED;
          if (job.driverId != null) {
            for (Driver d in _drivers) {
              if (d.key == job.driverId) {
                myDriver = d;
                myDriver.isMyDriver = true;
                _polyLines.clear();
              }
            }
          }
          break;
        case Status.PACKAGE_PICKED:
          menuTyp = MenuTyp.PACKAGE_PICKED;
          break;
        case Status.FINISHED:
          menuTyp = MenuTyp.COMPLETED;
          break;
        case Status.CANCELLED:
          _polyLines.clear();
          _packageMarker = null;
          _mapsService.setNewCameraPosition(_mapController, LatLng(myPosition.latitude, myPosition.longitude), null, true);
          clearJob();
          break;
      }
    }
  }

  void _onDriversDataChanged(Event event) {
    var old = _drivers.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _drivers[_drivers.indexOf(old)] = Driver.fromSnapshot(event.snapshot);
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

    PaymentService().openPayMenu(price, user.uid).then((result) => {
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
    return Stack(
      children: [
        _content(),
        isInitialized ? Container() : SplashScreen(),
      ],
    );
  }

  Widget _content() => new Scaffold(
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
                  child: Text(user.displayName, style: TextStyle(fontSize: 22, color: Colors.white)),
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
                MaterialPageRoute(builder: (context) => AllOrders(user.uid)),
              );
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr()),
            onTap: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
    ),
    floatingActionButton: getFloatingActionButton(),
  );

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in _drivers) {
      if (menuTyp != MenuTyp.ACCEPTED) {
        if (driver.isOnline) {
          markers.add(driver.getMarker(_driverLocationIcon));
        }
      } else {
        if (driver.isMyDriver) {
          markers.add(driver.getMarker(_driverLocationIcon));
        }
      }
    }
    if (_packageMarker != null)
      markers.add(_packageMarker);
    if (_destinationMarker != null)
      markers.add(_destinationMarker);
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
      polylines: _polyLines,
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
      _polyLines.clear();
      LatLng chosen = t;
      if (isDestinationButtonChosen) {
        destination = chosen;
        _destinationMarker = Marker(
            markerId: MarkerId("package"),
            position: chosen,
            icon: _homeLocationIcon,
            onTap: () => {
              setState(() {
                isDestinationButtonChosen = true;
              })
            }
        );
        setPlaceForDestination(address: address);
      } else {
        origin = chosen;
        _packageMarker = Marker(
            markerId: MarkerId("destination"),
            position: chosen,
            icon: _packageLocationIcon,
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': myDriver.getName()})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.PACKAGE_PICKED.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: () {
                                openMessageScreen(job.key, myDriver.getName());
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': myDriver.getName()})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.JOB_ACCEPTED.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: () {
                                openMessageScreen(job.key, myDriver.getName());
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
                                  _polyLines.clear();
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

    void addJobToPool(transactionId) async {
      job = Job(
          name: "Robot",
          userId: user.uid,
          transactionId: transactionId,
          vehicle: Vehicle.CAR,
          price: price,
          origin: origin,
          destination: destination,
          originAddress: originAddress,
          destinationAddress: destinationAddress
      );
      _orders.add(json.encode(job.toJson()));
      SharedPreferences.getInstance().then((value) => {
          value.setStringList('orders', _orders)
        }
      );
      _mapsService.jobsRef.push().set(job.toMap());
    }

    Future<void> setRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
      _routeCoordinate = List();
      if (TEST) {
        _routeCoordinate.add(origin);
        _routeCoordinate.add(destination);
      } else {
        _routeCoordinate = await _googleMapPolyline.getCoordinatesWithLocation (
            origin: origin,
            destination: destination,
            mode: mode
        );
      }
      drawPolyline(Colors.black26, [Colors.blue, Colors.blueAccent], _routeCoordinate);
    }

    initPolyline(Color color) {
      setState(() {
        _polyLines.add(Polyline(
            polylineId: PolylineId("Route_all"),
            visible: true,
            points: _routeCoordinate,
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
        _polyLines.clear();
        initPolyline(firstColor);
        await new Future.delayed(Duration(milliseconds : 200));
        await drawPolylineHelper(colorIndex, firstColor, colors[colorIndex++ % colors.length], routeCoords);
        await new Future.delayed(Duration(milliseconds : 500));
      }
      _polyLines.clear();
    }

    bool isDrawableRoute() => menuTyp == MenuTyp.CONFIRM || menuTyp == MenuTyp.CALCULATING_DISTANCE;

    drawPolylineHelper(int id, Color firstColor, Color color, List<LatLng> routeCoords) async {

      for (int i=0; i < routeCoords.length-1 && isDrawableRoute(); i++) {
        // await addLineToPolyline(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), i%2==0);
        await drawOneLine(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), 20);
      }
      setState(() {
        _polyLines.add(Polyline(
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
      double d = _mapsService.coordinateDistance(p1, p2);
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
        _polyLines.add(Polyline(
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
        newRouteCoords.addAll(await _googleMapPolyline.getCoordinatesWithLocation(
            origin: origin,
            destination: destination,
            mode: mode));
      }

      newRouteCoords.addAll(_routeCoordinate);

      setState(() {
        _polyLines.add(Polyline(
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
        _mapsService.setNewCameraPosition(_mapController, new LatLng(pos.latitude, pos.longitude), null, true);
      }
      myPosition = pos;
    }

    void openMessageScreen(key, name) async {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(key, name, false))
      );
    }

    getDesOrOriginButton(String activePath, String notActivePath, String activePathPressed, String notActivePathPressed, String label, bool isDestination) {

      onTapButton() {
        _mapsService.setNewCameraPosition(_mapController, isDestination? destination : origin, null, true);
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
                        startText: isDestinationButtonChosen? destinationAddress : originAddress,
                        hint: "MAPS.TYPE_ADDRESS".tr(),
                        // startText: isDestination ? destinationTextController.text : originTextController.text,
                        context: context,
                        apiKey: GOOGLE_DIRECTIONS_API_KEY,
                        logo: Image.asset("assets/none.png"),
                        mode: Mode.overlay, // Mode.fullscreen
                        language: 'de',
                        components: [new Component(Component.country, "at")]
                      );
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
      _mapsService.setNewCameraPosition(_mapController, pos, null, true);
    },
    child: Icon(Icons.my_location, color: Colors.white,),
    backgroundColor: Colors.lightBlueAccent,
  );

    bool isOnlineDriverAvailable() {
      for (int i = 0; i < _drivers.length; i++) {
        if (_drivers[i].isOnline)
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
      _polyLines = Set();
      isDestinationButtonChosen = false;
      totalDistance = 0.0;
      price = 0.0;
      _packageMarker = null;
      _destinationMarker = null;
      _routeCoordinate = null;
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
    if (0 >= i || _orders.length < i)
      return Container();
    Job order = Job.fromJson(json.decode(_orders[_orders.length-i]));
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

  _showMessageToast(key, name, message) {
    showToastWidget(
        MessageToast(
          message: message,
          name: name,
          onPressed: () {
            openMessageScreen(key, name);
          },
        ),
        duration: Duration(seconds: 5),
        position: ToastPosition.top,
        handleTouch: true
    );
  }

  Future<void> setJobIfExist() async {
    initCount++;
    return _mapsService.userRef.child("currentJob").once().then((DataSnapshot snapshot){
      final jobId = snapshot.value;
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).once().then((DataSnapshot snapshot){
          Job j = Job.fromJson(snapshot.value, key: snapshot.key);
          print(j.status);
          job = j;
          _onJobsDataChanged(j);
          nextInitializeDone();
        });
      } else {
        nextInitializeDone();
      }
    });
  }
}