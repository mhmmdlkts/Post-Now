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
  final Widget floatingActionButton;
  final double maxHeight;
  final Widget body;
  final Job job;
  final bool showOriginAddress;
  final bool showDestinationAddress;
  final bool shrinkWrap;
  final bool showFooter;
  final bool showCash;
  final SettingsDialog settingsDialog;
  final String chatName;
  final String headerText;
  final String phone;
  final String mainButtonText;
  final String imageUrl;
  final bool isSwipeButton;
  final bool isLoading;
  final bool defaultOpen;
  final VoidCallback onMainButtonPressed;
  final VoidCallback onCancelButtonPressed;

  BottomCard({
    key,
    this.imageUrl,
    this.maxHeight,
    this.floatingActionButton,
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
    this.showCash = false,
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
  ChatService _chatService;
  double _height = -100;

  BottomState();

  @override
  void initState() {
    super.initState();

    if (widget.job != null)
      _chatService = ChatService(widget.job.key, _onNewMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(Duration(milliseconds: 300), ()=> setState(() {
      _height = _contentKey.currentContext.size.height;
    })));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(top: 70),
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
            Positioned(
              left: 28,
              top: 42,
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
                  widget.imageUrl != null ?_circularImage(widget.imageUrl): Container(),
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
              visible: widget.settingsDialog != null,
              child: Positioned(
                  right: 10,
                  top:  64,
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
            Visibility(
              visible: widget.floatingActionButton != null,
              child: Positioned(
                  right: 14,
                  top: 0,
                  child: widget.floatingActionButton
              ),
            ),
          ],
        ),
      ),
    );
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

  _onNewMessage() {
    setState(() {

    });
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
    if (!widget.showCash || widget.job == null || widget.job.price.toBePaid <= 0 || widget.job.status == Status.WAITING)
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
    return Container(
      margin: EdgeInsets.only(right: 14),
      child: FloatingActionButton(
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
      )
    );
  }

  Widget _circularImage(String imgUrl) {
    return Container(
      margin: EdgeInsets.only(right: 14),
      child: CircleAvatar(
        radius: 30.0,
        backgroundImage: NetworkImage(imgUrl),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}