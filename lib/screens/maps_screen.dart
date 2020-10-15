import 'package:audioplayers/audio_cache.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:postnow/dialogs/address_manager_dialog.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/dialogs/settings_dialog.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/models/draft_order.dart';
import 'package:postnow/models/settings_item.dart';
import 'package:postnow/screens/contact_form_screen.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/voucher_screen.dart';
import 'package:postnow/services/global_service.dart';
import 'package:postnow/services/legal_service.dart';
import 'package:postnow/services/vibration_service.dart';
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
  final AudioCache _audioPlayer = AudioCache();
  final GlobalKey _mapKey = GlobalKey();
  final List<Driver> _drivers = List();
  final User _user;
  String _driverPhone;
  String _driverName;
  bool _isInitialized = false;
  bool _isInitDone = false;
  int _initCount = 0;
  int _initDone = 0;
  Set<Polyline> _polyLines = Set();
  List<String> _orders = List();
  BitmapDescriptor _packageLocationIcon, _driverLocationIcon, _homeLocationIcon;
  TextEditingController _originTextController, _destinationTextController;
  Marker _packageMarker, _destinationMarker;
  GoogleMapController _mapController;
  MapsService _mapsService;
  DraftOrder _draft;
  MenuTyp _menuTyp;
  BottomCard _bottomCard;
  Address _originAddress, _destinationAddress;
  Position _myPosition;
  PermissionStatus _permissionStatus;
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
    _draft = await _mapsService.createDraft(_originAddress, _destinationAddress, RouteMode.driving);
    drawPolyline(Colors.black26, [Colors.blue, Colors.blueAccent]);

    _changeMenuTyp(MenuTyp.CONFIRM);
  }

  void _onPositionChanged(Position position) {
    _setMyPosition(position);
  }

  @override
  void initState() {
    _initCount++;
    super.initState();
    Screen.keepOn(true);

    Future.delayed(const Duration(milliseconds: 2500)).then((value) {
      if(_initIsDone())
        print("Force init");
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => { setState((){
      _packageLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('1');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/driver_map_marker.png', 150).then((value) => { setState((){
      _driverLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('2');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/home_map_marker.png', 130).then((value) => { setState((){
      _homeLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('3');
    })});

    _initCount++;
    SharedPreferences.getInstance().then((value) => {
        if (value.containsKey('orders'))
          _orders = value.getStringList('orders'),
        _nextInitializeDone('4')
      }
    );

    _originTextController = new TextEditingController(text: '');
    _destinationTextController = new TextEditingController(text: '');

    _mapsService.driverRef.onChildAdded.listen(_onDriversDataAdded);
    _mapsService.driverRef.onChildChanged.listen(_onDriversDataChanged);


    _mapsService.jobsRef.onChildAdded.listen(_onJobsDataAdded);

    _mapsService.userRef.child('credit').onValue.listen((Event e) {
      setState(() {
        if (e.snapshot.value == null)
          _credit = 0.0;
        else
          _credit = e.snapshot.value + 0.0;
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
    
    _nextInitializeDone('6');
  }

  void _nextInitializeDone(String code) {
    // print(code);
    _initDone++;
    if (_initCount == _initDone) {
      _initIsDone();
    }
  }

  bool _initIsDone() {
    if (_isInitDone)
      return false;
    _isInitDone = true;
    _initMyPosition().then((val) => {
      Future.delayed(Duration(milliseconds: 400), () =>
        setState((){
          _isInitialized = true;
        })
      )
    });
    return true;
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

  _onMyJobChanged(Job j) {
    _job = j;
    _getDriverInfo();
    switch (_job.status) {
      case Status.ON_ROAD:
        _changeMenuTyp(MenuTyp.ACCEPTED);
        break;
      case Status.WAITING:
        _changeMenuTyp(MenuTyp.SEARCH_DRIVER);
        break;
      case Status.PACKAGE_PICKED:
        _changeMenuTyp(MenuTyp.PACKAGE_PICKED);
        break;
      case Status.FINISHED:
        _changeMenuTyp(MenuTyp.COMPLETED);
        break;
      case Status.CANCELLED:
        _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
        _clearJob();
        break;
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



  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    _mapsService.getMapStyle().then((style) {
      setState(() {
        _mapController.setMapStyle(style);
      });
    });
  }

  _navigateToPaymentsAndGetResult(BuildContext context, bool useCredits) async {
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

    PaymentService().openPayMenu(_draft.price, _user.uid, _draft.key, useCredits, _credit).then((transactionIds) => {
      setState(() {
        print (transactionIds);
        if (transactionIds != null) {
          //addJobToPool(transactionIds);
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
            title: Text('MAPS.SIDE_MENU.PRIVACY_POLICY'.tr()),
            onTap: () {
              _thisMethodFixABugButIStillAlwaysABugFixMeDude();
              LegalService.openPrivacyPolicy();
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.SOFTWARE_LICENCES'.tr()),
            onTap: () {
              LegalService.openLicences();
            },
          ),
          ListTile(
            title: Text('MAPS.SIDE_MENU.CONTACT'.tr()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactFormScreen(_user)),
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
      onMapCreated: _onMapCreated,
      zoomControlsEnabled: false,
      myLocationEnabled: _myPosition != null,
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
                                _openMessageScreen(_job.key, _myDriver.getName());
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
                                _openMessageScreen(_job.key, _myDriver.getName());
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
                          title: Text('MAPS.PRICE'.tr(namedArgs: {'price': _draft.price.toString()})),
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
                                  if (_draft.price == 0)
                                    return;
                                  _navigateToPaymentsAndGetResult(context, true);
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
          price: _draft.price,
          originAddress: _originAddress,
          destinationAddress: _destinationAddress
      );
      _orders.add(json.encode(_job.toJson()));
      SharedPreferences.getInstance().then((value) => {
          value.setStringList('orders', _orders)
        }
      );
      String jobId = _mapsService.jobsRef.push().key;
      _mapsService.jobsRef.child(jobId).set(_job.toMap());
      _mapsService.jobsRef.child(jobId).onChildRemoved.listen((Event e) {
        _clearJob();
      });
    }

    initPolyline(Color color) {
      setState(() {
        _polyLines.add(Polyline(
            polylineId: PolylineId("Route_all"),
            visible: true,
            points: _draft.routes,
            width: 3,
            color: color,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
    }

    drawPolyline(Color firstColor, List<Color> colors) async {
      int colorIndex = 0;
      while(isDrawableRoute()) {
        _polyLines.clear();
        initPolyline(firstColor);
        await new Future.delayed(Duration(milliseconds : 200));
        await drawPolylineHelper(colorIndex, firstColor, colors[colorIndex++ % colors.length], _draft.routes);
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

      newRouteCoords.addAll(_draft.routes);

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
    
    Future<bool> _positionIsNotGranted() async {
      if (_permissionStatus == PermissionStatus.granted) {
        return false;
      }
      _permissionStatus = await Permission.location.status;
      if (_permissionStatus.isGranted)
        return false;
      _permissionStatus = await Permission.location.request();
      if (_permissionStatus == PermissionStatus.permanentlyDenied || _permissionStatus == PermissionStatus.denied) {
        bool val = await _allowLocationDialog();
        if (val) {
          await openAppSettings();
          await _iAmBackDialog();
        }
      }
      return !_permissionStatus.isGranted;
    }

    Future<void> _initMyPosition() async {
      if (await _positionIsNotGranted()) {
        return null;
      }
      const locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

      Geolocator().getPositionStream(locationOptions).listen(_onPositionChanged);

      _setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

      Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
        _myPosition = value,
      });

      await _mapController.moveCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(_myPosition.latitude, _myPosition.longitude), zoom: 13)
      ));
    }

    void _setMyPosition(Position pos) {
      _myPosition = pos;
    }

    void _openMessageScreen(key, name) async {
      bool _isDriverApp = await GlobalService.isDriverApp();
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(key, name, _isDriverApp))
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
          headerText: 'MAPS.NO_AVAILABLE_DRIVER_MESSAGE'.tr(),
          mainButtonText: 'OK'.tr(),
          onMainButtonPressed: () {
            _changeMenuTyp(MenuTyp.FROM_OR_TO);
          },
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
          isLoading: true,
          headerText: 'MAPS.BOTTOM_MENUS.CALCULATING_DISTANCE.CALCULATING_DISTANCE'.tr(),
          shrinkWrap: false,
          showFooter: false,
          onCancelButtonPressed: () {
            setState(() {
              _polyLines.clear();
              if (_destinationAddress != null && _originAddress != null)
                _changeMenuTyp(MenuTyp.FROM_OR_TO);
            });
          },
        );
        break;
      case MenuTyp.CONFIRM:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          headerText: 'MAPS.PRICE'.tr(namedArgs: {'price': _draft.price.toString()}),
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
              if (_draft.price == 0)
                return;
              _navigateToPaymentsAndGetResult(context, true);
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
          chatName: _driverName,
          phone: _driverPhone,
          headerText: _driverName,
          defaultOpen: true,
          shrinkWrap: true,
          showFooter: false,
          settingsDialog: _getSettingsDialog(),
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
          chatName: _driverName,
          phone: _driverPhone,
          headerText: _driverName,
          defaultOpen: true,
          shrinkWrap: true,
          showFooter: false,
          settingsDialog: _getSettingsDialog(),
        );
        break;
      case MenuTyp.COMPLETED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
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


  showLocalNot() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  _positionFloatingActionButton() {
    if (_myPosition == null)
      return null;
    return FloatingActionButton(
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
  }

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
      _polyLines.clear();
      _packageMarker = null;
      _isDestinationButtonChosen = false;
      _draft = null;
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
    VibrationService.vibrateMessage();
    _audioPlayer.play('sounds/push_notification.mp3');
    showToastWidget(
        MessageToast(
          message: message,
          name: name,
          onPressed: () {
            _openMessageScreen(key, name);
          },
        ),
        duration: Duration(seconds: 5),
        position: ToastPosition.top,
        handleTouch: true
    );
  }

  _getDriverInfo() async {
    await Future.wait([
      _mapsService.getPhoneNumberFromDriver(_job).then((value) => { _driverPhone = value }),
      _mapsService.getNameFromDriver(_job).then((value) => { _driverName = value })
    ]);
    _refreshBottomCard();
  }

  Future<void> _myJobListener() async {
    return _mapsService.userRef.child("currentJob").onValue.listen((Event e){
      final jobId = e.snapshot.value;
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).onValue.listen((Event e){
          print(e.snapshot.value["status"]);
          Job j = Job.fromSnapshot(e.snapshot);
          _job = j;
          _onMyJobChanged(j);
        });
      } else {
        _clearJob();
      }
    });
  }

  Future<bool> _showAreYouSureDialog() async {
    final String amount = (await _mapsService.getCancelFeeAmount()).toString();
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "WARNING".tr(),
            message: "DIALOGS.ARE_YOU_SURE_CANCEL.CONTENT_WITH_AMOUNT".tr(namedArgs: {'amount': amount}),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "ACCEPT".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }

  Future<bool> _allowLocationDialog() async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.ALLOW_LOCATION.TITLE".tr(),
            message: "DIALOGS.ALLOW_LOCATION.MESSAGE".tr(),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "DIALOGS.ALLOW_LOCATION.ALLOW".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }

  Future<bool> _iAmBackDialog() async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.I_AM_BACK.TITLE".tr(),
            message: "DIALOGS.I_AM_BACK.MESSAGE".tr(),
            positiveButtonText: "DIALOGS.I_AM_BACK.POSITIVE".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
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

  _getSettingsDialog() => SettingsDialog(
      [
        SettingsItem(
            textKey: "DIALOGS.JOB_SETTINGS.CANCEL_JOB",
            onPressed: () async {
              if (await _showAreYouSureDialog()) {
                _mapsService.cancelJob(_job);
              }
            },
            icon: Icons.cancel, color: Colors.white
        ),
        SettingsItem(textKey: "CLOSE", onPressed: () {}, icon: Icons.close, color: Colors.redAccent),
      ]
  );
}