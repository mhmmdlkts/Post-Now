import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/dialogs/address_manager_dialog.dart';
import 'package:postnow/enums/legacity_enum.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/screens/legal_menu_screen.dart';
import 'package:postnow/screens/legal_screen.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/voucher_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/services/payment_service.dart';
import 'package:postnow/enums/job_vehicle_enum.dart';
import 'package:postnow/screens/splash_screen.dart';
import 'package:postnow/services/maps_service.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postnow/enums/menu_typ_enum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postnow/models/driver.dart';
import 'package:postnow/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:screen/screen.dart';
import '../bottom_card.dart';
import 'chat_screen.dart';
import 'dart:convert';
import 'dart:async';


class MapsScreen extends StatefulWidget {
  final User user;
  MapsScreen(this.user);

  @override
  _MapsScreenState createState() => _MapsScreenState(user);
}

class _MapsScreenState extends State<MapsScreen> {
  final GoogleMapPolyline _googleMapPolyline = new GoogleMapPolyline(apiKey: GOOGLE_DIRECTIONS_API_KEY);
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: GOOGLE_DIRECTIONS_API_KEY);
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final GlobalKey _mapKey = GlobalKey();
  final List<Driver> _drivers = List();
  final User _user;
  String _driverPhone;
  String _driverName;
  bool _isInitialized = false;
  int _initCount = 0;
  int _initDone = 0;
  Set<Polyline> _polyLines = Set();
  List<String> _orders = List();
  BitmapDescriptor _packageLocationIcon, _driverLocationIcon, _homeLocationIcon;
  TextEditingController _originTextController, _destinationTextController;
  Marker _packageMarker, _destinationMarker;
  GoogleMapController _mapController;
  List<LatLng> _routeCoordinate;
  MapsService _mapsService;
  double _totalDistance = 0.0;
  double _price = 0.0;
  MenuTyp _menuTyp;
  BottomCard _bottomCard;
  Address _originAddress, _destinationAddress;
  Position _myPosition;
  Job _job;
  Driver _myDriver;
  double _credit;
  bool _isDestinationButtonChosen = false;

  _MapsScreenState(this._user) {
    _mapsService = MapsService(_user.uid);
  }

  goToPayButtonPressed() {
    setState(() {
      if (!isOnlineDriverAvailable()) {
        _changeMenuTyp(MenuTyp.NO_DRIVER_AVAILABLE);
        return;
      }
      _changeMenuTyp(MenuTyp.CALCULATING_DISTANCE);
      getRoute();
    });
  }

  getRoute() async {
    _polyLines.clear();
    _mapsService.setNewCameraPosition(
        _mapController, _getOrigin(), _getDestination(), false);
    await setRoutePolyline(_getOrigin(), _getDestination(), RouteMode.driving);

    calculatePrice().then((value) => {
        setState(() {
          if (value == null) {
            _changeMenuTyp(MenuTyp.NO_ROUTE);
            return;
          }
          if (value)
            _changeMenuTyp(MenuTyp.CONFIRM);
          else
            _changeMenuTyp(MenuTyp.TRY_AGAIN);
        })
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

  Future<bool> calculatePrice () async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();
    _totalDistance = calculateDistance(_routeCoordinate);
    if (_totalDistance == 0)
      return null;
    double calcPrice = remoteConfig.getDouble(FIREBASE_REMOTE_CONFIG_EURO_START_KEY);
    calcPrice += _totalDistance * remoteConfig.getDouble(FIREBASE_REMOTE_CONFIG_EURO_PER_KM_KEY);
    if (calcPrice == 0)
      return false;
    _price = num.parse(calcPrice.toStringAsFixed(2));
    return true;
  }

  @override
  void initState() {
    _initCount++;
    super.initState();
    Screen.keepOn(true);

    Future.delayed(const Duration(milliseconds: 2500)).then((value) {
      if (_isInitialized)
        return;
      print('Force init');
      setState((){
        _isInitialized = true;
      });
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => { setState((){
      _packageLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone('1');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/driver_map_marker.png', 150).then((value) => { setState((){
      _driverLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone('2');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/home_map_marker.png', 130).then((value) => { setState((){
      _homeLocationIcon = BitmapDescriptor.fromBytes(value);
      nextInitializeDone('3');
    })});

    _initCount++;
    SharedPreferences.getInstance().then((value) => {
        if (value.containsKey('orders'))
          _orders = value.getStringList('orders'),
        nextInitializeDone('4')
      }
    );

    _originTextController = new TextEditingController(text: '');
    _destinationTextController = new TextEditingController(text: '');

    _mapsService.driverRef.onChildAdded.listen(_onDriversDataAdded);
    _mapsService.driverRef.onChildChanged.listen(_onDriversDataChanged);


    _mapsService.jobsRef.onChildAdded.listen(_onJobsDataAdded);

    _mapsService.jobsRef.onChildChanged.listen((Event e) {
      setState(() {
        Job j = Job.fromSnapshot(e.snapshot);
        _onJobsDataChanged(j);
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

    _initCount++;
    _setJobIfExist().then((value) => {
      nextInitializeDone('5')
    });

    _initCount++;
    _mapsService.getCredit().then((value) => {
      setState(() {
        _credit = value;
      }),
      nextInitializeDone('5')
    });

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(onPositionChanged);
    nextInitializeDone('6');
  }

  nextInitializeDone(String code) {
    // print(code);
    _initDone++;
    if (_initCount == _initDone) {
      getMyPosition().then((value) => {
        _mapController.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(value.latitude, value.longitude), zoom: 13)
        )),
        Future.delayed(Duration(milliseconds: 500), () =>
          setState((){
            _isInitialized = true;
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
    if (snapshot == _job) {
      _mapsService.userRef.child("orders").child(snapshot.key).set(snapshot.key);
    }
  }

  _onJobsDataChanged(Job j) {
    if (j == _job || (j.isJobForMe(_user.uid) && j.finishTime == null)) {
      _job = j;
      _getDriverInfo();
      switch (_job.status) {
        case Status.ON_ROAD:
          _changeMenuTyp(MenuTyp.ACCEPTED);
          if (_job.driverId != null) {
            for (Driver d in _drivers) {
              if (d.key == _job.driverId) { // TODO delete foreach
                _myDriver = d;
                _myDriver.isMyDriver = true;
                _polyLines.clear();
              }
            }
          }
          break;
        case Status.PACKAGE_PICKED:
          _changeMenuTyp(MenuTyp.PACKAGE_PICKED);
          break;
        case Status.FINISHED:
          _changeMenuTyp(MenuTyp.COMPLETED);
          break;
        case Status.CANCELLED:
          _polyLines.clear();
          _packageMarker = null;
          _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
          _clearJob();
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

  _navigateToPaymentsAndGetResult(BuildContext context, double price, bool useCredits) async {
    setState(() {
      _changeMenuTyp(MenuTyp.PAYMENT_WAITING);
    });

    /*if (IS_TEST) {
      setState(() {
        addJobToPool('test_transaction_id');
        _changeMenuTyp(MenuTyp.SEARCH_DRIVER);
      });
      return;
    }*/

    PaymentService().openPayMenu(price, _user.uid, useCredits, _credit).then((result) => {
      setState(() {
        if (result != null) {
          addJobToPool(result);
          _changeMenuTyp(MenuTyp.SEARCH_DRIVER);
        } else
          _changeMenuTyp(MenuTyp.PAYMENT_DECLINED);
      })
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _content(),
        _isInitialized ? Container() : SplashScreen(),
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
          getBottomMenu() == null? Container() : getBottomMenu(), // TODO
        ]
    ),
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Stack(
              children: <Widget>[
                Text("SETTINGS".tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_user.displayName, style: TextStyle(fontSize: 22, color: Colors.white)),
                      _credit == null? Container() : Text(_credit.toStringAsFixed(2) + " €", style: TextStyle(fontSize: 18, color: Colors.white))
                    ],
                  ),
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
              _thisMethodFixABugButIStillAlwaysABugFixMeDude();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OverviewScreen(_user)),
              );
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.VOUCHER'.tr()),
            onTap: () {
              _thisMethodFixABugButIStillAlwaysABugFixMeDude();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VoucherScreen(_user.uid)),
              );
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.LEGAL'.tr()),
            onTap: () {
              _thisMethodFixABugButIStillAlwaysABugFixMeDude();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LegalMenu()),
              );
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.CONTACT'.tr()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LegalScreen(LegalTyp.CONTACT)),
              );
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr(), style: TextStyle(color: Colors.redAccent),),
            onTap: () {
              _thisMethodFixABugButIStillAlwaysABugFixMeDude();
              AuthService().signOut();
            },
          ),
        ],
      ),
    ),
    floatingActionButton: _getFloatingButton(),
  );

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    for (Driver driver in _drivers) {
      if (_menuTyp != MenuTyp.ACCEPTED) {
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
    key: _mapKey,
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
        _setMarker(t);
      },
    ),
  );

  _setMarker(pos, {Address address, String houseNumber}) async {
    if (_menuTyp != MenuTyp.FROM_OR_TO && _menuTyp != null)
      return;
    if (pos is Position)
      pos = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _polyLines.clear();
      LatLng chosen = pos;
      if (_isDestinationButtonChosen) {
        _destinationAddress = Address.fromLatLng(chosen);
        _destinationMarker = Marker(
            markerId: MarkerId("package"),
            position: chosen,
            icon: _homeLocationIcon,
            onTap: () => {
              setState(() {
                _isDestinationButtonChosen = true;
              })
            }
        );
        _setPlaceForDestination(address: address, houseNumber: houseNumber);
      } else {
        _originAddress = Address.fromLatLng(chosen);
        _packageMarker = Marker(
            markerId: MarkerId("destination"),
            position: chosen,
            icon: _packageLocationIcon,
            onTap: () => {
              setState(() {
                _isDestinationButtonChosen = false;
              })
            }
        );
        _setPlaceForOrigin(address: address, houseNumber: houseNumber);
      }
      if (_isDestinationButtonChosen? _originAddress == null : _destinationAddress == null)
        _isDestinationButtonChosen = !_isDestinationButtonChosen;
    });
  }

  Widget getTopMenu() {
    if (_menuTyp != null && _menuTyp != MenuTyp.FROM_OR_TO)
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
          _getDesOrOriginButton("assets/marker_buttons/package_selected.png",
              "assets/marker_buttons/package_not_selected.png",
              "assets/marker_buttons/package_selected_onPressed.png",
              "assets/marker_buttons/package_not_selected_onPressed.png", false),
          _getDesOrOriginButton("assets/marker_buttons/home_selected.png",
              "assets/marker_buttons/home_not_selected.png",
              "assets/marker_buttons/home_selected_onPressed.png",
              "assets/marker_buttons/home_not_selected_onPressed.png", true),
        ],
      ),
    );
  }

    Widget getBottomMenu() {
      switch (_menuTyp) {
        case MenuTyp.FROM_OR_TO:
          return fromOrToMenu();
      }
      if (_bottomCard == null)
        return Container();
      else
        return _bottomCard;
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
                                _clearJob();
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': _myDriver.getName()})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.PACKAGE_PICKED.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: () {
                                openMessageScreen(_job.key, _myDriver.getName());
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
                          title: Text("MAPS.BOTTOM_MENUS.YOUR_DRIVER".tr(namedArgs: {'name': _myDriver.getName()})),
                          subtitle: Text("MAPS.BOTTOM_MENUS.ON_JOB.STATUS".tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: () {
                                openMessageScreen(_job.key, _myDriver.getName());
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
                                _changeMenuTyp(MenuTyp.FROM_OR_TO);
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

  Widget noRouteMenu() => Positioned(
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
                        title: Text('MAPS.BOTTOM_MENUS.NO_ROUTE.MESSAGE'.tr()),
                      ),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: Text('OK'.tr()),
                            onPressed: () {
                              setState(() {
                                _clearJob();
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

    Widget tryAgainMenu() => Positioned(
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
                          title: Text('MAPS.BOTTOM_MENUS.TRY_AGAIN.MESSAGE'.tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('TRY_AGAIN'.tr()),
                              onPressed: goToPayButtonPressed,
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
                          title: Text('MAPS.PRICE'.tr(namedArgs: {'price': _price.toString()})),
                          subtitle: Text('MAPS.BOTTOM_MENUS.CONFIRM.FROM_TO'.tr(namedArgs: {'from': _originAddress.getAddress(), 'to': _destinationAddress.getAddress()})),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('CANCEL'.tr()),
                              onPressed: () {
                                setState(() {
                                  _polyLines.clear();
                                  if (_destinationAddress != null && _originAddress != null)
                                    _changeMenuTyp(MenuTyp.FROM_OR_TO);
                                });
                              },
                            ),
                            FlatButton(
                              child: Text('ACCEPT'.tr()),
                              onPressed: () {
                                setState(() {
                                  //menuTyp = MenuTyp.PAY;
                                  if (_price == 0)
                                    return;
                                  _navigateToPaymentsAndGetResult(context, _price, true);
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
                        _menuTyp != MenuTyp.ACCEPTED ? Padding (
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
                        _menuTyp != MenuTyp.ACCEPTED ? Padding (
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
                                _changeMenuTyp(MenuTyp.CONFIRM);
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

    void addJobToPool(Map<String, dynamic> transactionIds) async {
      _job = Job(
          name: _user.displayName,
          userId: _user.uid,
          customTransactionId: transactionIds['customTransId'],
          brainTreeTransactionId: transactionIds['brainTreeTransId'],
          vehicle: Vehicle.CAR,
          price: _price,
          originAddress: _originAddress,
          destinationAddress: _destinationAddress
      );
      _orders.add(json.encode(_job.toJson()));
      SharedPreferences.getInstance().then((value) => {
          value.setStringList('orders', _orders)
        }
      );
      _mapsService.jobsRef.push().set(_job.toMap());
    }

    Future<void> setRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
      _routeCoordinate = List();
      if (IS_TEST) {
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

    bool isDrawableRoute() => _menuTyp == MenuTyp.CONFIRM || _menuTyp == MenuTyp.CALCULATING_DISTANCE;

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

      if (IS_TEST) {
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
      if (_myPosition != null)
        return _myPosition;

      setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

      Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
        _myPosition = value,
      });

      return _myPosition;
    }

    void setMyPosition(Position pos) {
      if (_myPosition == null) { // first time
        _mapsService.setNewCameraPosition(_mapController, new LatLng(pos.latitude, pos.longitude), null, true);
      }
      _myPosition = pos;
    }

    void openMessageScreen(key, name) async {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(key, name, false))
      );
    }
    
    String _getDestinationAddress() {
      if (_destinationAddress == null)
        return null;
      return _destinationAddress.getAddress();
    }

    String _getOriginAddress() {
      if (_originAddress == null)
        return null;
      return _originAddress.getAddress();
    }

    LatLng _getDestination() {
      if (_destinationAddress == null)
        return null;
      return _destinationAddress.coordinates;
    }

    LatLng _getOrigin() {
      if (_originAddress == null)
        return null;
      return _originAddress.coordinates;
    }

    _getDesOrOriginButton(String activePath, String notActivePath, String activePathPressed, String notActivePathPressed, bool isDestination) {

      onTapButton() {
        _mapsService.setNewCameraPosition(_mapController, isDestination? _getDestination() : _getOrigin(), null, true);
        if (_isDestinationButtonChosen != isDestination) {
          setState(() {
            _isDestinationButtonChosen = isDestination;
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
                            ? _isDestinationButtonChosen
                            : !_isDestinationButtonChosen)
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
                    child: (isDestination? _destinationAddress != null : _originAddress != null) ? FittedBox(
                      child: FloatingActionButton(
                        heroTag: "btn",
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          setState(() {
                            if (isDestination) {
                              _destinationAddress = null;
                              _setPlaceForDestination();
                            } else {
                              _originAddress = null;
                              _setPlaceForOrigin();
                            }
                            _isDestinationButtonChosen = isDestination;
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
                        startText: _isDestinationButtonChosen? _getDestinationAddress() : _getOriginAddress(),
                        hint: "MAPS.TYPE_ADDRESS".tr(),
                        // startText: isDestination ? destinationTextController.text : originTextController.text,
                        context: context,
                        apiKey: GOOGLE_DIRECTIONS_API_KEY,
                        logo: Image.asset("assets/none.png"),
                        mode: Mode.overlay, // Mode.fullscreen
                        language: 'de',
                        components: [new Component(Component.country, "at")]
                      );
                      if (p == null)
                        return;
                      Address address = await _predictionToAddress(p);
                      _setMarker(address.coordinates, address: address);
                    },
                    maxLines: null,
                    controller: isDestination
                        ? _destinationTextController
                        : _originTextController,
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
              (isDestination == _isDestinationButtonChosen && _myPosition != null) ?
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
                    _setMarker(LatLng(_myPosition.latitude, _myPosition.longitude));
                  },
                  color: Colors.blue,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text("MAPS.CURRENT_LOCATION".tr(), style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                  )
                )
              ) : Container(),
              (isDestination == _isDestinationButtonChosen) ?
              _getLastAddress(1) : Container(),
              (isDestination == _isDestinationButtonChosen) ?
              _getLastAddress(2) : Container(),
            ],
          )
      );
    }

    Future<Address> _predictionToAddress(Prediction p) async {
      if (p == null)
        return null;
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
      final double lat = detail.result.geometry.location.lat;
      final double lng = detail.result.geometry.location.lng;
      return Address.fromAddressComponents(detail.result.addressComponents, coordinates: LatLng(lat, lng), doorNumber: _predictionToHouseNumber(p));
    }

    String _predictionToHouseNumber(Prediction p) {
      if (p == null)
        return null;
      List<String> list = p.description.split(" ");
      final RegExp regex = RegExp(r"^[0-9]+([-]?[a-zA-Z])?");
      for (int i = list.length-1; 0 <= i; i--) {
        String houseNumber = list[i].replaceAll(",", "");
        if (regex.hasMatch(houseNumber))
          if (houseNumber.contains("/"))
            return houseNumber.split("/")[1];
          else
            return houseNumber;
      }
      return null;
    }

    void _setPlaceForOrigin({Address address, String houseNumber}) async {
      _commonPiece();
      if (_originAddress == null) {
        _clearOriginAddress();
        return;
      }
      if (address == null) {
        List<Placemark> originPlaceMarks = await Geolocator()
            .placemarkFromCoordinates(_getOrigin().latitude, _getOrigin().longitude);
        _originAddress.updateWithPlaceMark(originPlaceMarks[0]);
      } else {
        _originAddress = address;
      }
      if (houseNumber != null) {
        if (houseNumber.contains("/")) {
          _originAddress.houseNumber = houseNumber.split("/")[0];
          _originAddress.doorNumber = houseNumber.split("/")[1];
        } else {
          _originAddress.houseNumber = houseNumber;
        }
      }
      _originTextController.text = _originAddress.getAddress();
      _originAddress = await _showAddressManagerDialog(_originAddress);
      if (_originAddress != null)
        _originTextController.text = _originAddress.getAddress();
      else
        _clearOriginAddress();
    }

    void _setPlaceForDestination({Address address, String houseNumber}) async {
      _commonPiece();
      if (_getDestination() == null) {
        _clearDestinationAddress();
        return;
      }
      if (address == null) {
        List<Placemark> destinationPlaceMarks = await Geolocator()
            .placemarkFromCoordinates(_getDestination().latitude, _getDestination().longitude);
        _destinationAddress.updateWithPlaceMark(destinationPlaceMarks[0]);
      } else {
        _destinationAddress = address;
      }
      if (houseNumber != null) {
        if (houseNumber.contains("/")) {
          _destinationAddress.houseNumber = houseNumber.split("/")[0];
          _destinationAddress.doorNumber = houseNumber.split("/")[1];
        } else {
          _destinationAddress.houseNumber = houseNumber;
        }
      }
      _destinationTextController.text = _destinationAddress.getAddress();
      _destinationAddress = await _showAddressManagerDialog(_destinationAddress);
      if (_destinationAddress != null)
        _destinationTextController.text = _destinationAddress.getAddress();
      else
        _clearDestinationAddress();
    }

    void _commonPiece() {
      setState(() {
        _changeMenuTyp(_destinationAddress != null && _originAddress != null ? MenuTyp.FROM_OR_TO : null);
      });
    }

  FloatingActionButton _getFloatingButton() {
      if (_menuTyp == null)
        return _positionFloatingActionButton();
      switch (_menuTyp) {
        case MenuTyp.FROM_OR_TO:
          return _goToPayFloatingActionButton();
      }
      return null;
  }

  void _changeMenuTyp(menuTyp) async {
    setState(() {
      _menuTyp = menuTyp;
      _changeBottomCard(_menuTyp);
    });
  }

  void _refreshBottomCard() {
    _changeBottomCard(_menuTyp);
  }

  void _changeBottomCard(menuTyp) {
    switch (menuTyp)
    {
      case MenuTyp.FROM_OR_TO:
      case MenuTyp.NO_DRIVER_AVAILABLE:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'MAPS.NO_AVAILABLE_DRIVER_MESSAGE'.tr(),
          mainButtonText: 'OK'.tr(),
          onMainButtonPressed: _clearJob,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      case MenuTyp.TRY_AGAIN:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'MAPS.BOTTOM_MENUS.TRY_AGAIN.MESSAGE'.tr(),
          mainButtonText: 'TRY_AGAIN'.tr(),
          onMainButtonPressed: goToPayButtonPressed,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      case MenuTyp.NO_ROUTE:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'MAPS.BOTTOM_MENUS.NO_ROUTE.MESSAGE'.tr(),
          mainButtonText: 'OK'.tr(),
          onMainButtonPressed: _clearJob,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      case MenuTyp.CALCULATING_DISTANCE:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          messageSendable: false,
          isLoading: true,
          headerText: 'MAPS.BOTTOM_MENUS.CALCULATING_DISTANCE.CALCULATING_DISTANCE'.tr(),
          shrinkWrap: false,
          showFooter: false,
        );
        break;
      case MenuTyp.CONFIRM:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          messageSendable: false,
          headerText: 'MAPS.PRICE'.tr(namedArgs: {'price': _price.toString()}),
          checkboxText: _credit == null? null: 'MAPS.BOTTOM_MENUS.CONFIRM.USE_CREDITS'.tr(namedArgs: {'money': _credit.toStringAsFixed(2)}),
          onCancelButtonPressed: () {
            setState(() {
              _polyLines.clear();
              if (_destinationAddress != null && _originAddress != null)
                _changeMenuTyp(MenuTyp.FROM_OR_TO);
            });
          },
          mainButtonText: 'ACCEPT'.tr(),
          onMainButtonPressed: () {
            setState(() {
              //menuTyp = MenuTyp.PAY;
              if (_price == 0)
                return;
              _navigateToPaymentsAndGetResult(context, _price, true);
            });
          },
          shrinkWrap: false,
          showFooter: false,
        );
        break;
        // return confirmMenu(); TODO SHOW destination addresses
      case MenuTyp.SEARCH_DRIVER:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          messageSendable: false,
          isLoading: true,
          headerText: 'MAPS.BOTTOM_MENUS.SEARCH_DRIVER.STATUS'.tr(),
          shrinkWrap: false,
          showFooter: false,
        );
        break;
      case MenuTyp.PAYMENT_WAITING:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          messageSendable: false,
          isLoading: true,
          headerText: 'MAPS.BOTTOM_MENUS.PAYMENT_WAITING.PAYMENT_WAITING'.tr(),
          shrinkWrap: false,
          showFooter: false,
        );
        break;
      case MenuTyp.PAYMENT_DECLINED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'MAPS.BOTTOM_MENUS.PAYMENT_DECLINED.PAYMENT_DECLINED'.tr(),
          mainButtonText: 'CLOSE'.tr(),
          onMainButtonPressed: () {
            _changeMenuTyp(MenuTyp.CONFIRM);
          },
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      case MenuTyp.ACCEPTED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          job: _job,
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: true,
          showOriginAddress: true,
          messageSendable: true,
          phone: _driverPhone,
          headerText: _driverName,
          defaultOpen: true,
          shrinkWrap: true,
          showFooter: false,
        );
        break;
      case MenuTyp.PACKAGE_PICKED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          job: _job,
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: true,
          showOriginAddress: false,
          messageSendable: true,
          phone: _driverPhone,
          headerText: _driverName,
          defaultOpen: true,
          shrinkWrap: true,
          showFooter: false,
        );
        break;
      case MenuTyp.COMPLETED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'THANKS'.tr(),
          mainButtonText: 'OK'.tr(),
          onMainButtonPressed: _clearJob,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      default:
        _bottomCard = null;
    }
  }

  _positionFloatingActionButton() => FloatingActionButton(
    heroTag: "btn",
    onPressed: () {
      if (_myPosition == null)
        return;
      LatLng pos = LatLng(_myPosition.latitude, _myPosition.longitude);
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

  FloatingActionButton _goToPayFloatingActionButton() => FloatingActionButton(
    heroTag: "btn",
    onPressed: goToPayButtonPressed,
    child: Icon(Icons.arrow_forward, color: Colors.white,),
    backgroundColor: Colors.redAccent,
  );

  void _clearJob() {
    setState(() {
      _clearDestinationAddress();
      _clearOriginAddress();
      _polyLines = Set();
      _isDestinationButtonChosen = false;
      _totalDistance = 0.0;
      _price = 0.0;
      _routeCoordinate = null;
      _myDriver = null;
      _job = null;
      _changeMenuTyp(null);
    });
  }

  _clearDestinationAddress() {
    _destinationTextController.clear();
    _destinationAddress = null;
    _destinationMarker = null;
    _isDestinationButtonChosen = true;
  }

  _clearOriginAddress() {
    _originTextController.clear();
    _originAddress = null;
    _packageMarker = null;
    _isDestinationButtonChosen = false;
  }

  _getLastAddress(int i) {
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
              _setMarker(_isDestinationButtonChosen ? order.destinationAddress.coordinates : order.originAddress.coordinates,
                  address: _isDestinationButtonChosen ? order.destinationAddress : order.originAddress);
            },
            color: Colors.redAccent,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text(_isDestinationButtonChosen
                        ? order.destinationAddress.getAddress()
                        : order.originAddress.getAddress(),
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

  _getDriverInfo() async {
    List<Future> todo = [
      _mapsService.getPhoneNumberFromDriver(_job).then((value) => { _driverPhone = value }),
      _mapsService.getNameFromDriver(_job).then((value) => { _driverName = value })
    ];
    await Future.wait(todo);
    _refreshBottomCard();
  }

  Future<void> _setJobIfExist() async {
    _initCount++;
    return _mapsService.userRef.child("currentJob").once().then((DataSnapshot snapshot){
      final jobId = snapshot.value;
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).once().then((DataSnapshot snapshot){
          Job j = Job.fromJson(snapshot.value, key: snapshot.key);
          _job = j;
          _onJobsDataChanged(j);
          nextInitializeDone('7');
        }).catchError((error) {
          nextInitializeDone('11');
        }).timeout(Duration(seconds: FUTURE_TIMEOUT_SEC), onTimeout: () {
          nextInitializeDone('10');
        });
      } else {
        nextInitializeDone('8');
      }
    }).catchError((error) {
      nextInitializeDone('12');
    }).timeout(Duration(seconds: FUTURE_TIMEOUT_SEC), onTimeout: () {
      nextInitializeDone('9');
    });
  }

  Future<Address> _showAddressManagerDialog(Address address) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddressManager(address);
      }
    );
  }

  void _thisMethodFixABugButIStillAlwaysABugFixMeDude() {
    if (_originAddress != null || _destinationAddress != null)
      _clearJob(); // TODO
    }
}