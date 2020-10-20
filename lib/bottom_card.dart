import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:postnow/dialogs/settings_dialog.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/presentation/my_flutter_app_icons.dart';
import 'package:postnow/screens/chat_screen.dart';
import 'package:postnow/services/chat_service.dart';
import 'package:postnow/services/global_service.dart';
import 'package:swipebuttonflutter/swipebuttonflutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomCard extends StatefulWidget {
  final FloatingActionButton floatingActionButton;
  final double maxHeight;
  final Widget centerWidget;
  final Widget body;
  final bool isCenterWidgetFixed;
  final Job job;
  final bool showOriginAddress;
  final bool showDestinationAddress;
  final bool shrinkWrap;
  final bool showFooter;
  final SettingsDialog settingsDialog;
  final String chatName;
  final String headerText;
  final String phone;
  final String mainButtonText;
  final bool isSwipeButton;
  final bool isLoading;
  final bool defaultOpen;
  final VoidCallback onMainButtonPressed;
  final VoidCallback onCancelButtonPressed;

  BottomCard({
    key,
    this.maxHeight,
    this.floatingActionButton,
    this.centerWidget,
    this.isCenterWidgetFixed = true,
    this.job,
    this.body,
    this.showOriginAddress = false,
    this.shrinkWrap = true,
    this.headerText,
    this.showDestinationAddress = false,
    this.phone,
    this.chatName,
    this.mainButtonText,
    this.isSwipeButton = false,
    this.defaultOpen = false,
    this.onMainButtonPressed,
    this.onCancelButtonPressed,
    this.showFooter = true,
    this.settingsDialog,
    this.isLoading = false
  }) : super(key: key);

  @override
  BottomState createState() => BottomState();
}

class BottomState extends State<BottomCard> {
  final GlobalKey _settingsMenuKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  bool _isVisible = true;
  double _minHeight;
  double _maxHeight;
  Offset _offset;
  ChatService _chatService;

  BottomState();

  @override
  void initState() {
    super.initState();
    _initSize();

    if (widget.job != null)
      _chatService = ChatService(widget.job.key, _onNewMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isVisible?1.0:0.0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Visibility(
            visible: widget.centerWidget != null,
            child: Positioned(
                bottom:  (widget.isCenterWidgetFixed?_minHeight:_offset.dy) + 36,
                child: widget.centerWidget
            ),
          ),
          Align(),
          GestureDetector(
            onPanEnd: (details) {
              if (!widget.shrinkWrap)
                return;
              if (details.velocity.pixelsPerSecond.dy > 0)
                _open();
              else if (details.velocity.pixelsPerSecond.dy < 0)
                _close();
            },
            onPanUpdate: (details) {
              if (!widget.shrinkWrap)
                return;
              _offset = Offset(0, _offset.dy - details.delta.dy * 4);
              const double tmp = 30;
              if (_offset.dy < _minHeight) {
                _offset = Offset(0, _minHeight);
              } else if (_offset.dy > _maxHeight) {
                _offset = Offset(0, _maxHeight);
              }
              setState(() {});
            },
            child: AnimatedContainer(
              key: _containerKey,
              duration: Duration.zero,
              curve: Curves.easeOut,
              height: _offset.dy,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 5, blurRadius: 10)]
              ),
              child: ListView(
                key: _contentKey,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _getHeader(),
                  _getSubHeader(),
                  _addressWidget(false),
                  widget.showOriginAddress ? Container(height: 10) : Container(),
                  _addressWidget(true),
                  (widget.showOriginAddress || widget.showDestinationAddress) && widget.onMainButtonPressed != null ? Divider(thickness: 1, height: 25,) : Container(),
                  _getBody(),
                  _getMainButton(widget.isSwipeButton),
                  widget.job != null && widget.showFooter ? Divider(thickness: 1, height: 25,) : Container(),
                  _getCustomerName(),
                  Container(height: widget.body==null?10 + MediaQuery.of(context).padding.bottom:0),
                ],
              ),
            ),
          ),
          Positioned(
            left: 28,
            bottom: _offset.dy - 28,
            child: Row(
              children: [
                widget.onCancelButtonPressed == null? Container() : Container(
                  margin: EdgeInsets.only(right: 14),
                  child: FloatingActionButton(
                    heroTag: "cancel_fab",
                    child: Icon(Icons.close, color: Colors.white,),
                    onPressed: () {
                      widget.onCancelButtonPressed.call();
                    },
                    backgroundColor: Colors.redAccent,
                  ),
                ),
                widget.phone == null? Container() : Container(
                  margin: EdgeInsets.only(right: 14),
                  child: FloatingActionButton(
                    heroTag: "call_customer_fab",
                    child: Icon(Icons.phone, color: Colors.white,),
                    onPressed: _callCustomer,
                  ),
                ),
                widget.chatName != null ?_sendMessageFab(_chatService.getUnreadMessageCount()): Container(),
              ],
            ),
          ),
          Visibility(
            visible: widget.floatingActionButton != null,
            child: Positioned(
                right: 14,
                bottom:  _offset.dy + 14,
                child: widget.floatingActionButton
            ),
          ),
          Visibility(
            visible: widget.settingsDialog != null,
            child: Positioned(
                right: 10,
                bottom:  _offset.dy - 45 - 10,
                child: Material(
                  child: InkWell(
                      key: _settingsMenuKey,
                      customBorder: CircleBorder(),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return widget.settingsDialog;
                            }
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.more_horiz, size: 35,),
                      )
                  ),
                  color: Colors.transparent,
                )
            ),
          ),
        ],
      ),
    );
  }

  void _initSize() {
    setState(() {
      _isVisible = false;
    });
    _minHeight = 50;
    _maxHeight = widget.maxHeight;

    _offset = Offset(0, _maxHeight);

    WidgetsBinding.instance.addPostFrameCallback((_) => _setMaxMin());
  }

  _setMaxMin() async {
    await Future.delayed(Duration(milliseconds: 300)); // Todo dont know why this is needed
    if (_contentKey.currentContext == null && _containerKey.currentContext.size.height != widget.maxHeight) {
      Future.delayed(Duration(milliseconds: 50), _setMaxMin);
      return;
    }
    _setMaxHeight(_contentKey.currentContext.size.height);
    _setMinHeight(widget.shrinkWrap?_headerKey.currentContext.size.height:_maxHeight);

    if (widget.defaultOpen)
      _close(ms: 0);
    else
      _open(ms: 0);
  }

  void _callCustomer() async {
    final url = 'tel:${widget.phone}';
    await launch(url);
  }

  void _openMessageScreen() async {
    if (widget.job == null)
      return;
    bool _isDriverApp = await GlobalService.isDriverApp();
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(widget.job.key, widget.chatName, _isDriverApp))
    );
  }

  _setMaxHeight(double h) {
    setState(() {
      _maxHeight = h;
      if (_offset.dy > h) {
        _offset = Offset(0, h);
      }
    });
  }

  _setMinHeight(double h) {
    setState(() {
      _minHeight = h;
      if (_offset.dy < h) {
        _offset = Offset(0, h);
      }
    });
  }

  _onNewMessage() {
    setState(() {

    });
  }

  void _open({int ms = 15}) {
    Timer.periodic(Duration(milliseconds: ms), (timer) {
      double value = _offset.dy - 10; // we decrement the height by 10 here
      _offset = Offset(0, value);
      if (_offset.dy < _minHeight) {
        _offset = Offset(0, _minHeight); // makes sure it doesn't go beyond minHeight
        _isVisible = true;
        timer.cancel();
      }
      setState(() {});
    });
    //_setMaxHeight(_contentKey.currentContext.size.height+ 50);
    setState(() { });
  }

  void _close({int ms = 15}) {
    Timer.periodic(Duration(milliseconds: ms), (timer) {
      double value = _offset.dy + 10; // we increment the height of the Container by 10 every 5ms
      _offset = Offset(0, value);
      if (_offset.dy > _maxHeight) {
        _offset = Offset(0, _maxHeight); // makes sure it does't go above maxHeight
        _isVisible = true;
        timer.cancel();
      }
      setState(() {});
    });
    setState(() { });
  }

  Widget _getHeader() {
    return Container(
        margin: EdgeInsets.only(top: _anyFab()?36:12, bottom: 12),
        key: _headerKey,
        child: Column(
          children: [
            widget.headerText == null ? _getTargetName() : _getCustomHeaderText(),
            Visibility(
              visible: widget.isLoading,
              child: Container(
                  padding: EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(minHeight: 20,),
                  )
              ),
            )
          ],
        )
    );
  }

  Widget _getSubHeader() {
    if (widget.job == null || widget.job.price.toBePaid > 0 || widget.job.status == Status.WAITING)
      return Container();
    return Container(
        margin: EdgeInsets.only(bottom: 30, top: 20),
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(MyFlutterApp.money_bill_alt, color: Colors.green,),
            Container(width: 20,),
            Expanded(
              child: Text('MAPS.BOTTOM_MENUS.ON_JOB.CASH'.tr(namedArgs: {'cash': widget.job.price.toBePaid.toStringAsFixed(2)}),
                  style: TextStyle(color: Colors.green, fontSize: 20)),
            )
          ],
        )
    );
  }

  bool _anyFab() => widget.chatName != null || widget.phone != null || widget.onCancelButtonPressed != null;

  Widget _getTargetName() {
    if (widget.job == null)
      return Container();
    return Text(
      widget.job.status == Status.PACKAGE_PICKED? widget.job.destinationAddress.doorName : widget.job.originAddress.doorName,
      style: TextStyle(fontSize: 24,),
      textAlign: TextAlign.center,
    );
  }

  Widget _getCustomHeaderText() {
    return Text(
      widget.headerText,
      style: TextStyle(fontSize: 24,),
      textAlign: TextAlign.center,
    );
  }

  Widget _getBody() {
    if (widget.body == null)
      return Container();
    return widget.body;
  }

  Widget _getMainButton(bool isSwipeButton) {
    if (widget.onMainButtonPressed == null)
      return Container();
    if (isSwipeButton) {
      return SwipingButton(
        text: widget.mainButtonText,
        onSwipeCallback: () {
          widget.onMainButtonPressed.call();
        },
        height: 56,
        swipeButtonColor: Colors.black,
        backgroundColor: Colors.lightBlueAccent,
      );
    }
    return ButtonTheme(
      height: 56,
      child: RaisedButton (
        color: Colors.lightBlueAccent,
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
        child: Text(widget.mainButtonText, style: TextStyle(color: Colors.white),),
        onPressed: () {
          widget.onMainButtonPressed.call();
        },
      ),
    );
  }

  Widget _getCustomerName() {
    if (widget.job == null || !widget.showFooter)
      return Container();
    return Text(
      'MAPS.BOTTOM_MENUS.ON_JOB.YOUR_CUSTOMER'.tr(namedArgs: {'name': widget.job.name}),
      style: TextStyle(fontSize: 18),
      textAlign: TextAlign.center,
    );
  }

  Widget _addressWidget(bool isDestination) {
    if (widget.job == null)
      return Container();
    isVisible() => isDestination?widget.showDestinationAddress:widget.showOriginAddress;
    isEnabled() => isDestination?widget.job.status == Status.PACKAGE_PICKED:widget.job.status == Status.ON_ROAD;
    getDestinationAddressText() => (widget.job.destinationAddress.hasDoorNumber()?
    'MAPS.BOTTOM_MENUS.PACKAGE_PICKED.PACKAGE_ADDRESS_EXTRA_SERVICE':'MAPS.BOTTOM_MENUS.PACKAGE_PICKED.PACKAGE_ADDRESS')
        .tr(namedArgs: {'address': widget.job.getDestinationAddress(), 'name': widget.job.destinationAddress.doorName});
    getOriginAddressText() => (widget.job.originAddress.hasDoorNumber()?
    'MAPS.BOTTOM_MENUS.ON_JOB.PACKAGE_ADDRESS_EXTRA_SERVICE':'MAPS.BOTTOM_MENUS.ON_JOB.PACKAGE_ADDRESS')
        .tr(namedArgs: {'address': widget.job.getOriginAddress(), 'name': widget.job.originAddress.doorName});
    if (isDestination == null)
      return Container();
    Widget getRow(markerPath, visible, enabled, text) {
      const double opacity = 0.6;
      return Row(
        children: [
          Visibility(
            visible: visible,
            child: Opacity(
              opacity: enabled?1.0:opacity,
              child: Image.asset(markerPath, width: MediaQuery.of(context).size.width/6),
            ),
          ),
          Visibility(
              visible: isVisible(),
              child: Expanded(
                child: Opacity(
                    opacity: enabled?1.0:opacity,
                    child: Text(text)
                ),
              )
          )
        ],
      );
    }
    return getRow(
        isDestination ?"assets/home_map_marker.png":"assets/package_map_marker.png",
        isVisible(),
        isEnabled(),
        isDestination? getDestinationAddressText() : getOriginAddressText()
    );
  }

  Widget _sendMessageFab(int count) {
    return FloatingActionButton(
      heroTag: "send_message_fab",
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(Icons.message, color: Colors.white,),
          ),
          (count > 0) ?
          Align(

            alignment: Alignment.bottomRight,
            child: Container(
              width: 24,
              height: 24,
              child: Center(
                child: Text(count.toString(),style: TextStyle(color: Colors.white),),
              ),
              decoration: new BoxDecoration(
                color: Colors.redAccent,
                borderRadius: new BorderRadius.all(const Radius.circular(50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
            ),
          ) : Container(),
        ],
      ),
      onPressed: _openMessageScreen,
    );
  }
}