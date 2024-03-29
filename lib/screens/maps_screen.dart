import 'dart:math';

import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:html/parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/dialogs/address_manager_dialog.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/dialogs/custom_notification_dialog.dart';
import 'package:postnow/dialogs/order_details_dialog.dart';
import 'package:postnow/dialogs/settings_dialog.dart';
import 'package:postnow/dialogs/topic_chooser_dialog.dart';
import 'package:postnow/enums/order_typ_enum.dart';
import 'package:postnow/enums/payment_methods_enum.dart';
import 'package:postnow/enums/permission_typ_enum.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/models/credit_card.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/models/custom_notification.dart';
import 'package:postnow/models/draft_order.dart';
import 'package:postnow/models/settings_item.dart';
import 'package:postnow/models/shopping_item.dart';
import 'package:postnow/presentation/my_flutter_app_icons.dart';
import 'package:postnow/screens/contact_form_screen.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/settings_screen.dart';
import 'package:postnow/screens/shopping_list_maker_screen.dart';
import 'package:postnow/screens/voucher_screen.dart';
import 'package:postnow/services/global_service.dart';
import 'package:postnow/services/legal_service.dart';
import 'package:postnow/services/notification_service.dart';
import 'package:postnow/services/overview_service.dart';
import 'package:postnow/services/permission_service.dart';
import 'package:postnow/services/places_service.dart';
import 'package:postnow/services/remote_config_service.dart';
import 'package:postnow/services/vibration_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/services/payment_service.dart';
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
import 'package:postnow/widgets/chooser_widget.dart';
import 'package:postnow/widgets/payment_methods.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:screen/screen.dart';
import '../widgets/bottom_card.dart';
import 'dart:io' show Platform;
import 'chat_screen.dart';
import 'dart:async';


class MapsScreen extends StatefulWidget {
  final User user;
  MapsScreen(this.user);

  @override
  _MapsScreenState createState() => _MapsScreenState(user);
}

class _MapsScreenState extends State<MapsScreen> {
  final GoogleMapPolyline _googleMapPolyline = new GoogleMapPolyline(apiKey: ApiKeys.getGoogleApiKeyForThisPlatform());
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: GOOGLE_API_KEY_PLACES_AND_DIRECTIONS);
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final AudioCache _audioPlayer = AudioCache();
  final List<CreditCard> _creditCards = List();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _toolbarKey = GlobalKey();
  final GlobalKey _addressBarKey = GlobalKey();
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final Set<Marker> _marketMarkers = Set();
  final AuthService _firebaseService = AuthService();
  final User _user;
  OverviewService _overviewService;
  PlacesService _placesService;
  bool _isInitialized = false;
  bool _isInitDone = false;
  int _initCount = 0;
  int _initDone = 0;
  Set<Polyline> _polyLines = Set();
  BitmapDescriptor _packageLocationIcon, _driverLocationIcon, _homeLocationIcon, _shopLocationIcon, _shopLocationIconGray;
  TextEditingController _originTextController, _destinationTextController;
  Marker _packageMarker, _destinationMarker;
  GoogleMapController _mapController;
  MapsService _mapsService;
  PaymentService _paymentService;
  DraftOrder _draft;
  OrderTypEnum _orderTyp;
  MenuTyp _menuTyp;
  BottomCard _bottomCard;
  Address _originAddress, _destinationAddress;
  Position _myPosition;
  Job _job;
  Driver _myDriver;
  double _credit;
  bool _isDestinationButtonChosen = false;
  double _mapBottomPoint = 0;
  double _mapHeight = 0;
  double _toolbarHeight = 0;
  double _drawerWidth = 0;
  double _drawerPosition = 0;
  double _addressFieldHeight = 0;
  final FocusNode _receiverFieldFocusNode = FocusNode();
  final FocusNode _senderFieldFocusNode = FocusNode();
  bool _visibleReceiverField = true;
  bool _visibleSenderField = true;
  Duration _mapsCloseOpenDur = Duration(milliseconds: 800);
  String _addressSearchField = "";
  String _placesTopic;
  List<Prediction> _predictions = List();
  List<Address> _oldAddresses = List();
  bool isDrawerOpen = false;
  List<ShoppingItem> _shopItems;

  _MapsScreenState(this._user) {
    _paymentService = PaymentService(_user);
    _mapsService = MapsService(_user.uid);
    _overviewService = OverviewService(_user.uid);
  }

  goToPayButtonPressed() {
    _changeMenuTyp(MenuTyp.PLEASE_WAIT);
    _mapsService.isOnlineDriverAvailable(_getOrigin(), _getDestination()).then((value) => {
      setState(() {
        if (!value) {
          _changeMenuTyp(MenuTyp.NO_DRIVER_AVAILABLE);
          return;
        }
        _changeMenuTyp(MenuTyp.CALCULATING_DISTANCE);
        getRoute();
      })
    });
  }

  getRoute() async {
    _polyLines.clear();
    _mapsService.setNewCameraPosition(
        _mapController, _getOrigin(), _getDestination(), false);
    _draft = await _mapsService.createDraft(_originAddress, _destinationAddress, _shopItems, RouteMode.driving);
    if (_draft == null) {
      _changeMenuTyp(MenuTyp.TRY_AGAIN);
      return;
    }
    _mapsService.draftRef.child(_draft.key).child("pay_status").onValue.listen((event) {
      final String result = event.snapshot.value;
      if (_menuTyp != MenuTyp.PAYMENT_WAITING)
        return;
      if (result == "paid") {
        _changeMenuTyp(MenuTyp.SEARCH_DRIVER);
        return;
      }
      _changeMenuTyp(MenuTyp.PAYMENT_DECLINED);
    });
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
    // Permission.notification.request();
    _firebaseService.setMyToken(_user.uid);
    Screen.keepOn(true);

    Future.delayed(const Duration(milliseconds: 2500)).then((value) {
      if(_initIsDone())
        print("Force init");
    });

    PermissionService.positionIsNotGranted(PermissionTypEnum.NOTIFICATION, context: context);

    final markerSize = Platform.isIOS?130:80;

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', markerSize).then((value) => { setState((){
      _packageLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('1');
    })});

    _initCount++;
    initializeDateFormatting().then((value) => {
      _nextInitializeDone('0.0'),
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/driver_map_marker.png', (markerSize*1.15).round()).then((value) => { setState((){
      _driverLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('2');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/shop_map_marker.png', (markerSize*1.15).round()).then((value) => { setState((){
      _shopLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('2.1');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/shop_map_marker_gray.png', (markerSize*1.15).round()).then((value) => { setState((){
      _shopLocationIconGray = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('2.2');
    })});

    _initCount++;
    _mapsService.getBytesFromAsset('assets/home_map_marker.png', markerSize).then((value) => { setState((){
      _homeLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('3');
    })});

    _mapsService.userRef.child("creditCards").onValue.listen((Event e){
      _creditCards.clear();
      if (e.snapshot.value != null) {
        e.snapshot.value.forEach((key, value) {
          _creditCards.add(CreditCard.fromJson(value));
        });
        setState(() {});
      }
    });

    _originTextController = new TextEditingController(text: '');
    _destinationTextController = new TextEditingController(text: '');

    _mapsService.jobsRef.onChildAdded.listen(_onJobsDataAdded);

    FirebaseFirestore.instance.collection('users').doc(_user.uid).snapshots().listen((snapshot) {
      setState(() {
        _credit = 0.0;
        if (snapshot.exists && snapshot.data().keys.contains("credit"))
          _credit = snapshot["credit"] + 0.0;
      });
    });


    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      switch (message["typ"]) {
        case "message":
          _showMessageToast(message["key"], message["name"], message["message"]);
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

    _overviewService.initOrderList().then((value) => {
      setState((){})
    });

    _nextInitializeDone('6');

    _initCount++;
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
          setState(() {
            _toolbarHeight = _toolbarKey.currentContext.size.height;
            _addressFieldHeight = _addressBarKey.currentContext.size.height;
            _drawerWidth = _drawerKey.currentContext.size.width;
            _drawerPosition = -_drawerWidth;
            _mapHeight = MediaQuery.of(context).size.height - _toolbarHeight - MediaQuery.of(context).padding.top;
          });
          _nextInitializeDone('7');
    });

    onFocusChanged(FocusNode focusNode) {
      _closeOpenMap(!focusNode.hasFocus);
    }

    _receiverFieldFocusNode.addListener(() {
      onFocusChanged(_receiverFieldFocusNode);
    });
    _senderFieldFocusNode.addListener(() {
      onFocusChanged(_senderFieldFocusNode);
    });
  }

  void _nextInitializeDone(String code) {
    // print(code);
    _initDone++;
    if (_initCount == _initDone) {
      _myJobListener();
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

  void _onJobsDataAdded(Event event) async {
    Job snapshot = Job.fromSnapshot(event.snapshot);
    if (snapshot == _job) {
      _mapsService.userRef.child("orders").child(snapshot.key).set(snapshot.key);
    }
  }

  _onMyJobChanged(Job j) {
    _job = j;

    if (j == null)
      return;

    _addAddressMarker(null, null);
    _addAddressMarker(j.destinationAddress.coordinates, true);
    if (_job.status != Status.PACKAGE_PICKED)
      _addAddressMarker(j.originAddress.coordinates, false);
    _mapsService.driverRef.child(j.driverId).onValue.listen(_onMyDriverDataChanged);
    switch (_job.status) {
      case Status.ACCEPTED:
        _changeMenuTyp(MenuTyp.ACCEPTED);
        break;
      case Status.ON_ROAD:
        _changeMenuTyp(MenuTyp.ON_ROAD);
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

  void _onMyDriverDataChanged(Event event) {
    setState(() {
      _myDriver = Driver.fromSnapshot(event.snapshot);
      _refreshBottomCard();
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

  Widget _getNewSearchWidget(bool isDestination, {double leftPadding = 20, double rightPadding = 20}) {
    _getTextFieldController() => isDestination ? _destinationTextController : _originTextController;
    _clearField() {
      setState(() {
        _polyLines.clear();
        if (isDestination) {
          _destinationAddress = null;
          _setPlaceForDestination();
        } else {
          _originAddress = null;
          _shopItems = null;
          _setPlaceForOrigin();
        }
        _isDestinationButtonChosen = isDestination;
      });
    }
    return _topButtonDesign(
      leftPadding: leftPadding,
      rightPadding: rightPadding,
      child: Stack(
        alignment: Alignment.centerRight,
        children: <Widget>[
          TextField(
            onChanged: (e) => _onAddressFieldChanged(e),
            textAlignVertical: TextAlignVertical.center,
            focusNode: isDestination?_receiverFieldFocusNode:_senderFieldFocusNode,
            controller: _getTextFieldController(),
            onTap: () async {
              _getAddressesList("");
              _onTapButton(isDestination);
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(right: 40),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.location_on, color: isDestination?secondaryPurple:primaryBlue),
              hintText: isDestination
                  ? "MAPS.DESTINATION_ADDRESS".tr()
                  : "MAPS.PACKAGE_ADDRESS".tr(),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(100)),
            child: Material(
              color: Colors.transparent,
              child: _getTextFieldController().text.isEmpty && !_visibleAllList()? IconButton(
                icon: Icon(Icons.my_location, color: Colors.green,),
                onPressed: () {
                  _receiverFieldFocusNode.unfocus();
                  _senderFieldFocusNode.unfocus();
                  _setMarker(LatLng(_myPosition.latitude, _myPosition.longitude), name: _user.displayName);
                },
              ) : IconButton(
                  icon: Icon(Icons.cancel, color: Colors.black38,),
                  onPressed: () {
                    _receiverFieldFocusNode.unfocus();
                    _senderFieldFocusNode.unfocus();
                    _clearField();
                  }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topButtonDesign ({Widget child, double leftPadding = 20, double rightPadding = 20}) {
    return AnimatedContainer(
        width: MediaQuery.of(context).size.width - (rightPadding + leftPadding),
        duration: Duration(milliseconds: 2000),
        margin: EdgeInsets.only(left: leftPadding, right: rightPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(100)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: child
    );
  }

  _navigateToPaymentsAndGetResult(bool useCredits, PaymentMethodsEnum paymentMethod, CreditCard creditCard) async {
    setState(() {
      _changeMenuTyp(MenuTyp.PAYMENT_WAITING);
    });

    final bool result = await _paymentService.pay(context, _draft.price.total, _user.uid, _draft.key, useCredits, _credit, paymentMethod, creditCard);
    if (result)
      return;
    setState(() {
      _changeMenuTyp(MenuTyp.CONFIRM);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Stack(
          children: [
            WillPopScope(
              child: Scaffold(
                backgroundColor: primaryBlue,
                appBar: AppBar(
                  brightness: Brightness.dark,
                ),
              ),
              onWillPop: () async {
                if (_destinationAddress == null && _originAddress == null)
                  return true;
                setState(() {
                  _receiverFieldFocusNode.unfocus();
                  _senderFieldFocusNode.unfocus();

                  _destinationAddress = null;
                  _originAddress = null;
                  _setPlaceForDestination();
                  _setPlaceForOrigin();
                  _polyLines.clear();
                  _isDestinationButtonChosen = false;
                });
                return false;
              },
            ),
            Material(
              color: primaryBlue,
              child: _content(),
            ),
            Positioned(
              bottom: 30,
              right: 20,
              child: _getFloatingButton(),
            ),
            Positioned.fill(
              child: Visibility(
                visible: 0 == _drawerPosition,
                child: AnimatedOpacity(
                  curve: Curves.easeInOutQuart,
                  duration: Duration(milliseconds: 200),
                  opacity: 0 == _drawerPosition?1:0,
                  child: GestureDetector(
                    onTap: () => setState((){
                      _drawerPosition = -_drawerWidth;
                    }),
                    child: Container(
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
                curve: Curves.easeInOutQuart,
                duration: Duration(milliseconds: 200),
                top: 0,
                bottom: 0,
                left: _drawerPosition,
                child: _myDrawer()
            ),
          ],
        ),
        _orderTyp == null && _menuTyp == null ? ChooserWidget((OrderTypEnum orderTyp) => setState((){
          _orderTyp = orderTyp;
          if (orderTyp == OrderTypEnum.SHOPPING)
            _getTopicButtons(Function);
        })):Container(),
        _isInitialized ? Container() : SplashScreen(),
      ],
    );
  }

  Widget _myDrawer() => Drawer(
    key: _drawerKey,
    child: ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: Stack(
            children: <Widget>[
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                        alignment: Alignment.centerLeft,
                        icon: Icon(Icons.arrow_back_rounded, color: Colors.white,),
                        onPressed: () => setState(() {
                          _drawerPosition = -_drawerWidth;
                        })
                    ),
                  ),
                  Text("SETTINGS".tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
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
            color: primaryBlue,
          ),
        ),
        ListTile(
          title: Text('MAPS.SIDE_MENU.MY_ORDERS'.tr()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OverviewScreen(_user, _homeLocationIcon, _packageLocationIcon, overviewService: _overviewService)),
            );
          },
        ),
        ListTile(
          title: Text('MAPS.SIDE_MENU.VOUCHER'.tr()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VoucherScreen(_user.uid)),
            );
          },
        ),
        ListTile(
          title: Text('MAPS.SIDE_MENU.PRIVACY_POLICY'.tr()),
          onTap: () {
            LegalService.openPrivacyPolicy(context);
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
          title: Text('SETTINGS'.tr()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen(_user)),
            );
          },
        ),
        ListTile(
          title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr(), style: TextStyle(color: Colors.redAccent),),
          onTap: () {
            AuthService().signOut();
          },
        ),
      ],
    ),
  );

  Widget _topMenu() {
    if (_bottomCard != null && _menuTyp != MenuTyp.FROM_OR_TO)
      return Container();
    return Stack(
      children: [
        Positioned(
          key: _addressBarKey,
          top: MediaQuery.of(context).padding.top + _toolbarHeight + 20,
          width: MediaQuery.of(context).size.width,
          child: Visibility(
            visible: _visibleReceiverField,
            child: Row(
              children: [
                Expanded(
                  flex: 700,
                  child: _placesTopic==null?_getNewSearchWidget(false, leftPadding: 25, rightPadding: 5): _topButtonDesign(
                    leftPadding: 25,
                    rightPadding: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            _showTopicChooserDialog();
                          },
                          child: Center(
                              child: Container(
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Opacity(opacity: 0, child: IconButton(icon: Icon(Icons.add)),),
                                        Text(_placesTopic, style: TextStyle( color: Colors.black.withAlpha(170), fontSize:22),textAlign: TextAlign.center,),
                                      ],
                                    ),
                                  )
                              )
                          ),
                        )
                      )
                    )
                  )
                ),
                Expanded(
                  flex: _visibleSenderField?_orderTyp== OrderTypEnum.SHOPPING? 250:35:35,
                  child: Opacity(
                    opacity: _visibleSenderField?_orderTyp== OrderTypEnum.SHOPPING? 1:0:0.0,
                    child: _topButtonDesign(
                      leftPadding: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        child: Material(
                            color: _getTopicButtons(Color),
                            child: InkWell(
                              onTap: _getTopicButtons(Function),
                              child: IconButton(
                                  icon: _getTopicButtons(Icon)
                              ),
                            )
                        ),
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          duration: _mapsCloseOpenDur,
          curve: Curves.easeOutCirc,
          top: MediaQuery.of(context).padding.top + _toolbarHeight + (!_visibleReceiverField?10:(_addressFieldHeight + 30)),
          child:  Visibility(
            visible: _visibleSenderField,
            child: _getNewSearchWidget(true),
          ),
        ),
        AnimatedPositioned(
          duration: _mapsCloseOpenDur,
          curve: Curves.easeOutCirc,
          top: _visibleAllList()?MediaQuery.of(context).padding.top + _toolbarHeight + _addressFieldHeight + 30:MediaQuery.of(context).size.height,
          child: _addressList(),
        ),
      ],
    );
  }

  _getTopicButtons(Type typ) {
    if (_originAddress == null && _placesTopic == null) {
      switch(typ) {
        case Icon: return Icon(Icons.store, color: Colors.white);
        case Color: return primaryBlue;
        case Function: return () => setState(() {
          _marketMarkers.clear();
          _placesTopic = null;
          _showTopicChooserDialog();
        });
      }
    }
    if (_placesTopic == null) {
      switch(typ) {
        case Icon: return Icon(Icons.format_list_numbered, color: Colors.white);
        case Color: return primaryBlue;
        case Function: return () => setState(() {
          _marketMarkers.clear();
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShoppingListMakerScreen(items: _shopItems, freeItemCount: _mapsService.getFreeItemCount(), itemCost: _mapsService.getShoppingItemCost(), sameItemCost: _mapsService.getShoppingSameItemCost()))
          ).then((value) => {
            if (value != null)
              _shopItems = value
          });
        });
      }
    }
    switch(typ) {
      case Icon: return Icon(Icons.clear, color: Colors.white);
      case Color: return Colors.red;
      case Function: return () => setState(() {
        _marketMarkers.clear();
        _placesTopic = null;
        _shopItems = null;
      });
    }
  }

  Widget _content() => Stack(
    children: [
      AnimatedPositioned(
        curve: Curves.ease,
        duration: _mapsCloseOpenDur,
        bottom: -_mapBottomPoint,
        child: _googleMapsWidget(),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top,
        child: _toolbar(),
      ),
      _topMenu(),
      _bottomCard != null? _bottomCard:Container(),
    ],
  );

  void _closeOpenMap(bool open) {
    setState(() {
      _mapBottomPoint = !open?_mapHeight:0;
      if (!_senderFieldFocusNode.hasFocus && !_receiverFieldFocusNode.hasFocus) {
        _visibleSenderField = true;
        _visibleReceiverField = true;
        return;
      }
      if (_receiverFieldFocusNode.hasFocus) {
        _visibleReceiverField = false;
        _visibleSenderField = true;
      }
      if (_senderFieldFocusNode.hasFocus) {
        setState(() {
          _visibleSenderField = false;
          _visibleReceiverField = true;
        });
      }
    });
  }

  Widget _toolbar() {
    bool showCancelOrderTypButton = _orderTyp != null && _bottomCard == null;
    return Container(
      width: MediaQuery.of(context).size.width,
      key: _toolbarKey,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.menu, color: Colors.white,), onPressed: ()=> setState((){_drawerPosition = 0;})),
            Text("APP_NAME".tr(), style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,), textAlign: TextAlign.center,),
            Opacity(
              opacity: showCancelOrderTypButton?1:0,
              child: IconButton(
                icon: Icon(_orderTyp==OrderTypEnum.SHOPPING?Icons.shopping_cart:MyFlutterApp.car_side, color: Colors.white,),
                onPressed: showCancelOrderTypButton?() => setState((){_orderTyp = null;}):null,
              )
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween ,
        ),
      )
    );
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    if (_myDriver != null && _job != null && _job.status != Status.WAITING)
      markers.add(_myDriver.getMarker(_driverLocationIcon));
    if (_packageMarker != null)
      markers.add(_packageMarker);
    if (_destinationMarker != null)
      markers.add(_destinationMarker);
    _marketMarkers.forEach((element) {
      markers.add(element);
    });
    return markers;
  }

  Widget _googleMapsWidget() => Container(
    width: MediaQuery.of(context).size.width,
    height: _mapHeight,
    key: _mapKey,
    child: ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: GoogleMap(
        mapToolbarEnabled: false,
        compassEnabled: false,
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
      ),
    ),
  );

  _setMarker(pos, {Address address, String houseNumber, PlacesSearchResult market, String name}) async {
    if (_menuTyp != MenuTyp.FROM_OR_TO && _menuTyp != null)
      return;
    if (pos is Position)
      pos = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _polyLines.clear();
      LatLng chosen = pos;
      _addAddressMarker(chosen, _isDestinationButtonChosen);
      if (_isDestinationButtonChosen) {
        _destinationAddress = Address.fromLatLng(chosen);
        _setPlaceForDestination(address: address, houseNumber: houseNumber, market: market, name: name);
      } else {
        _originAddress = Address.fromLatLng(chosen);
        _setPlaceForOrigin(address: address, houseNumber: houseNumber, market: market, name: name);
      }
      if (_isDestinationButtonChosen? _originAddress == null : _destinationAddress == null)
        _isDestinationButtonChosen = !_isDestinationButtonChosen;
    });
  }

  void _addAddressMarker(LatLng position, bool isDestination) {
    if (isDestination == null) {
      _destinationMarker = null;
      _packageMarker = null;
      return;
    }
    Marker marker = Marker(
      markerId: MarkerId(isDestination?"destination":"package"),
      position: position,
      icon: isDestination?_homeLocationIcon:_packageLocationIcon
    );
    if (isDestination)
      _destinationMarker = marker;
    else
      _packageMarker = marker;
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
      initPolyline(firstColor);
      while(isDrawableRoute()) {
        _polyLines.clear();
        initPolyline(firstColor);
        await new Future.delayed(Duration(milliseconds : 200));
        await drawPolylineHelper(colorIndex, firstColor, colors[colorIndex++ % colors.length], _draft.routes);
        await new Future.delayed(Duration(milliseconds : 500));
      }
      setState(() {
        _polyLines.clear();
      });
    }

    bool isDrawableRoute() => _menuTyp != MenuTyp.PACKAGE_PICKED && _menuTyp != MenuTyp.ACCEPTED && _menuTyp != MenuTyp.COMPLETED && _polyLines.isNotEmpty;

    drawPolylineHelper(int id, Color firstColor, Color color, List<LatLng> routeCoords) async {
      for (int i=0; i < routeCoords.length-1 && isDrawableRoute(); i++) {
        // await addLineToPolyline(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), i%2==0);
        await drawOneLine(routeCoords[i], routeCoords[i+1], color, PolylineId("Route_" + id.toString() + "_" + i.toString()), 20);
      }
      if (!isDrawableRoute())
        return;
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

      newRouteCoords.addAll(
          await _googleMapPolyline.getCoordinatesWithLocation(
              origin: origin,
              destination: destination,
              mode: mode
          )
      );

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

    Future<bool> _initMyPosition() async {
      if (await PermissionService.positionIsNotGranted(PermissionTypEnum.LOCATION, context: context))
        return false;

      const locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

      Geolocator().getPositionStream(locationOptions).listen(_onPositionChanged);

      _setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

      Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
        _myPosition = value,
        _mapsService.sendMyLocToDB(_myPosition),
        NotificationService.fetch(_user.uid, _myPosition).then((value) => {
          NotificationService.notifications.forEach((element) async {
            await _showCustomNotificationDialog(element);
            await Future.delayed(Duration(milliseconds: 300));
          })
        })
      });

      await _mapController.moveCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(_myPosition.latitude, _myPosition.longitude), zoom: 13)
      ));
      return true;
    }

    void _setMyPosition(Position pos) {
      _placesService = PlacesService(pos);
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

    void _getAddressesList(String e) async {
      _oldAddresses = _overviewService.getLastAddresses(_addressSearchField);
      if (e.isEmpty) {
        setState(() {
          _predictions.clear();
        });
        return;
      }
      _mapsService.getAutoCompleter(e).then((value) => setState((){
        _predictions = value;
      }));
    }

    Widget _addressList() {

      int getIndex(int i) => _oldAddresses.length==0?i:i%_oldAddresses.length;

      predictionAddressListElement(int i) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              _receiverFieldFocusNode.unfocus();
              _senderFieldFocusNode.unfocus();
              Address address;
              if (i >= _oldAddresses.length) {
                address = await _predictionToAddress(_predictions[getIndex(i)]);
              } else {
                address =_oldAddresses[i];
              }
              _setMarker(address.coordinates, address: address);
            },
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Text(i >= _oldAddresses.length?_predictions[getIndex(i)].description:_oldAddresses[i].getAddress(), style: TextStyle(fontSize: 16),),
            ),
          ),
        );
      }

      return Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - (MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.top + _toolbarHeight + _addressFieldHeight +40),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length + _oldAddresses.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.black38,
                ),
                itemBuilder: (context, index) {
                  return predictionAddressListElement(index);
                }
              )
            ),
          )
        ),
      );
    }

  _refreshMarkers() {
    _addAddressMarker(null, null);
    if (_originAddress != null)
      _addAddressMarker(_originAddress.coordinates, false);
    if (_destinationAddress != null)
      _addAddressMarker(_destinationAddress.coordinates, true);
  }

  _onTapButton(bool isDestination) async {
    _isDestinationButtonChosen = isDestination;
      return;
    _mapsService.setNewCameraPosition(_mapController, isDestination? _getDestination() : _getOrigin(), null, true);
    if (_isDestinationButtonChosen != isDestination) {
      setState(() {
        _isDestinationButtonChosen = isDestination;
      });
    }
    Prediction p = await PlacesAutocomplete.show(
        startText: _isDestinationButtonChosen? _getDestinationAddress() : _getOriginAddress(),
        hint: "MAPS.TYPE_ADDRESS".tr(),
        // startText: isDestination ? destinationTextController.text : originTextController.text,
        context: context,
        apiKey: ApiKeys.getGoogleApiKeyForThisPlatform(),
        logo: Image.asset("assets/none.png"),
        mode: Mode.overlay, // Mode.fullscreen
        language: 'de',
        components: [new Component(Component.country, "at")]
    );
    if (p == null)
      return;
    Address address = await _predictionToAddress(p);
    _setMarker(address.coordinates, address: address);
  }

    _getDesOrOriginButton(String activePath, String notActivePath, String activePathPressed, String notActivePathPressed, bool isDestination) {
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
                        _onTapButton(isDestination);
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
                      _onTapButton(isDestination);
                      Prediction p = await PlacesAutocomplete.show(
                        startText: _isDestinationButtonChosen? _getDestinationAddress() : _getOriginAddress(),
                        hint: "MAPS.TYPE_ADDRESS".tr(),
                        // startText: isDestination ? destinationTextController.text : originTextController.text,
                        context: context,
                        apiKey: ApiKeys.getGoogleApiKeyForThisPlatform(),
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
                    width: (MediaQuery.of(context).size.width) * (0.4),
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
              _getLastAddress(isDestination)

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
      }
      return null;
    }

    void _setPlaceForOrigin({Address address, String houseNumber, PlacesSearchResult market, String name}) async {
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
      if (market == null)
        _originAddress = await _showAddressManagerDialog(_originAddress, name: name);
      else
        _originAddress.doorName = market?.name??"";

      if (_originAddress != null)
        setState(() { _originTextController.text = _originAddress.getAddress(); });
      else
        _clearOriginAddress();
      setState(() {
        _refreshMarkers();
      });
    }

    void _setPlaceForDestination({Address address, String houseNumber, PlacesSearchResult market, String name}) async {
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
      if (market == null)
        _destinationAddress = await _showAddressManagerDialog(_destinationAddress, name: name);
      else
        _destinationAddress.doorName = market?.name??"";
      if (_destinationAddress != null)
        setState(() { _destinationTextController.text = _destinationAddress.getAddress(); });
      else
        _clearDestinationAddress();
      setState(() {
        _refreshMarkers();
      });
    }

    void _commonPiece() {
      setState(() {
        _changeMenuTyp(_destinationAddress != null && _originAddress != null ? MenuTyp.FROM_OR_TO : null);
      });
    }

    bool _visibleAllList() => _mapBottomPoint == _mapHeight;

  Widget _getFloatingButton() {
      if (_visibleAllList())
        return Container();
      if (_menuTyp == null && _bottomCard == null)
        return _positionFloatingActionButton();
      switch (_menuTyp) {
      }
      return Container();
  }

  void _changeMenuTyp(menuTyp, {bool forceRefresh = false}) async {
    if (!forceRefresh && _menuTyp == menuTyp)
      return;
    setState(() {
      _menuTyp = menuTyp;
      _changeBottomCard(_menuTyp);
    });
  }

  void _refreshBottomCard() {
    setState(() {
      _changeMenuTyp(_menuTyp, forceRefresh: true);
    });
  }

  void _changeBottomCard(menuTyp) {
    switch (menuTyp)
    {
      case MenuTyp.FROM_OR_TO:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          headerText: 'MAPS.BOTTOM_MENUS.FROM_OR_TO.TITLE'.tr(),
          mainButtonText: 'MAPS.BOTTOM_MENUS.FROM_OR_TO.MAIN_BUTTON'.tr(),
          onMainButtonPressed: () {
            goToPayButtonPressed();
          },
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
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
      case MenuTyp.PLEASE_WAIT:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          isLoading: true,
          headerText: 'PLEASE_WAIT'.tr(),
          shrinkWrap: false,
          showFooter: false,
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
          onCancelButtonPressed: () {
            _changeMenuTyp(MenuTyp.FROM_OR_TO);
          },
          body: PaymentMethods(_user, _creditCards, (PaymentMethodsEnum paymentMethod, bool useCredits, CreditCard creditCard) {
            if (_draft.price.total == 0)
              return;
            _navigateToPaymentsAndGetResult(useCredits, paymentMethod, creditCard);
          }, _draft.price.total, _credit),
          shrinkWrap: false,
          showFooter: false,
        );
        break;
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
          job: _job,
          imageUrl: _myDriver?.image,
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: true,
          showOriginAddress: true,
          chatName: _myDriver==null?null:_myDriver.name,
          phone: _myDriver?.phone,
          headerText: _myDriver?.name,
          body: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("MAPS.BOTTOM_MENUS.ACCEPTED.MESSAGE".tr()),
          ),
          defaultOpen: true,
          shrinkWrap: true,
          showFooter: false,
          settingsDialog: _getSettingsDialog(),
        );
        break;
      case MenuTyp.ON_ROAD:
        _bottomCard = new BottomCard(
          job: _job,
          imageUrl: _myDriver?.image,
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: true,
          showOriginAddress: true,
          chatName: _myDriver==null?null:_myDriver.name,
          phone: _myDriver?.phone,
          headerText: _myDriver?.name,
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
          imageUrl: _myDriver?.image,
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _positionFloatingActionButton(),
          showDestinationAddress: true,
          showOriginAddress: false,
          chatName: _myDriver?.name,
          phone: _myDriver?.phone,
          headerText: _myDriver?.name,
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

  _positionFloatingActionButton() {
    if (_myPosition == null)
      return Container();
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

  void _clearJob() {
    setState(() {
      _shopItems = null;
      _clearDestinationAddress();
      _clearOriginAddress();
      _polyLines.clear();
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

  Widget _getLastAddress(bool isDestination) {
    if (isDestination != _isDestinationButtonChosen)
      return Container();
    List<Address> addresses = _overviewService.getLastAddresses("");
    List<Widget> addressContentWidget = List();
    for (int i = 0; i < addresses.length; i++) {
      addressContentWidget.add(_getLastAddressContentWidget(addresses[i]));
    }
    return Column( children:  addressContentWidget );
  }

  Widget _getLastAddressContentWidget(Address address) {
    return Container(
        margin: EdgeInsets.only(bottom: 5),
        width: (MediaQuery.of(context).size.width) * (0.4),
        child: RaisedButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            onPressed: () {
              _setMarker(address.coordinates, address: address);
            },
            color: Colors.redAccent,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text(address.getAddress(),
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,),
                  )
                ]
            )
        )
    );
  }

  _showCustomNotificationDialog(CustomNotification customNotification) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomNotificationDialog(customNotification);
        }
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

  Future<void> _myJobListener() async {
    return _mapsService.userRef.child("currentJob").onValue.listen((Event e){
      final jobId = e.snapshot.value;
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).onValue.listen((Event e){
          Job j = Job.fromSnapshot(e.snapshot);
          _onMyJobChanged(j);
        });
      } else {
        _clearJob();
      }
    });
  }

  Future<bool> _showAreYouSureDialog({bool isPackagePicked = false}) async {
    final String amount = _mapsService.getCancelFeeAmount().toStringAsFixed(2);

    final val = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "WARNING".tr(),
          message: 'DIALOGS.ADDRESS_MANAGER.ARE_YOU_SURE_CANCEL.${isPackagePicked?'CONTENT_AFTER_PACKAGE_PICKED':'CONTENT_WITH_AMOUNT'}'.tr(namedArgs: {'amount': amount}),
          negativeButtonText: "CANCEL".tr(),
          positiveButtonText: "ACCEPT".tr(),
        );
      }
    );
    return val??false;
  }

  Future<bool> _maybeItsClosedAreYouSure(String marketName) async {
    final val = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "DIALOGS.MARKET_IS_CLOSED.TITLE".tr(namedArgs: {'market_name': marketName}),
          message: 'DIALOGS.MARKET_IS_CLOSED.MESSAGE'.tr(),
          negativeButtonText: "CANCEL".tr(),
          positiveButtonText: "CONTINUE".tr(),
        );
      }
    );
    return val??false;
  }

  Future<Address> _showAddressManagerDialog(Address address, {String name}) async {
    return await showDialog(
      context: context,

      builder: (BuildContext context) {
        return AddressManager(address, _mapsService, name: name);
      }
    );
  }

  _showTopicChooserDialog() async {
    _marketMarkers.clear();
    final topics = _mapsService.getTopics();
    String chosenToken = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TopicChooserDialog(topics);
      }
    );
    if (chosenToken == null)
      return;
    _placesTopic = "MAPS.TOPIC_SEARCHING".tr(namedArgs: {"topic": chosenToken});
    setState(() {});
    _placesTopic = chosenToken;
    LatLng cheapestPoint;
    double cheapestPrice;
    _placesService.getPlaces(_placesTopic).then((value) => {
      value.forEach((element) {
        LatLng marketLatLng = LatLng(element.geometry.location.lat, element.geometry.location.lng);
        double aroundPrice = _mapsService.calculatePrice(_myPosition, marketLatLng);
        if (aroundPrice < (cheapestPrice!=null?cheapestPrice:double.infinity)) {
          cheapestPrice = aroundPrice;
          cheapestPoint = marketLatLng;
        }
        List<String> whiteList =  RemoteConfigService.getStringList(FIREBASE_REMOTE_CONFIG_MARKET_TOPICS_WHITE_LIST);
        final bool isOpen = (element?.openingHours?.openNow??false) || whiteList.contains(element.placeId);

        if (cheapestPoint == null)
          cheapestPoint = marketLatLng;
        _marketMarkers.add(Marker(
          onTap: () => _onTapTopicMarker(element, marketLatLng, isOpen),
          icon: isOpen?_shopLocationIcon:_shopLocationIconGray,
          infoWindow: InfoWindow(
              title: element.name,
              snippet: isOpen?null:'${"MAPS.MARKET.CLOSED".tr()}',
              onTap: () => _onTapTopicMarker(element, marketLatLng, isOpen)
          ),
          markerId: MarkerId(element.placeId),
          position: marketLatLng,
        ));
      }),
      setState((){ }),
      _mapsService.setNewCameraPosition(_mapController, cheapestPoint, null, true)
    });
  }

  _onTapTopicMarker(PlacesSearchResult element, LatLng marketLatLng, bool isOpen) async {
    _bottomCard = new BottomCard(
      key: GlobalKey(),
      maxHeight: _mapKey.currentContext.size.height,
      floatingActionButton: _positionFloatingActionButton(),
      headerText: element.name,
      subTitleText: element.vicinity,
      mainButtonText: 'MAPS.BOTTOM_MENUS.MARKET_MARKER.BUTTON'.tr(),
      isCircleImage: false,
      imageUrl: element.icon,
      onCancelButtonPressed: () {
        setState(() {
          _bottomCard = null;
        });
      },

      onMainButtonPressed: () async {
        // if (!isOpen && !(await _maybeItsClosedAreYouSure(element.name))) return; // TODO add dialog messages

        final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShoppingListMakerScreen(freeItemCount: _mapsService.getFreeItemCount(), itemCost: _mapsService.getShoppingItemCost(), sameItemCost: _mapsService.getShoppingSameItemCost()))
        );
        if (result == null)
          return;
        _shopItems = result;
        _placesTopic = null;
        _isDestinationButtonChosen = false;
        _setMarker(marketLatLng, market: element);
        _marketMarkers.clear();
        _bottomCard = null;
        setState(() {});
      },
      shrinkWrap: false,
    );
    setState(() {});
  }

  Future<String> _showOrderDetailDialog(jobId) async {
    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return OrderDetailDialog(jobId);
      },
    );
  }

  _getSettingsDialog() => SettingsDialog([
    SettingsItem(
        textKey: "DIALOGS.JOB_SETTINGS.CANCEL_JOB",
        onPressed: () async {
          final bool isPackagePicked = _job.status == Status.PACKAGE_PICKED;
          if (await _showAreYouSureDialog(isPackagePicked: isPackagePicked)) {
            _changeMenuTyp(MenuTyp.PLEASE_WAIT);
            _mapsService.cancelJob(_job);
          }
        },
        icon: Icons.cancel, color: Colors.white
    ),
    SettingsItem(textKey: "CLOSE", onPressed: () {}, icon: Icons.close, color: Colors.redAccent),
  ]);

  Timer _throttle;
  _onAddressFieldChanged(String e) async {
    setState(() {
      _addressSearchField = e;
    });
    if (_throttle?.isActive ?? false) _throttle.cancel();
    _throttle = Timer(Duration(milliseconds: 500), () {
      _getAddressesList(e);
    });
  }
}