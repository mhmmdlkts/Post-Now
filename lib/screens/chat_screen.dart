import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postnow/models/message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/screens/shopping_list_view_screen.dart';

import 'package:postnow/services/chat_service.dart';
import 'package:postnow/services/shopping_list_service.dart';
import 'package:postnow/models/shopping_item.dart';

import 'camera_screen.dart';


class ChatScreen extends StatefulWidget {
  final String _jobId, _name;
  final bool isDriverApp;
  final ShoppingListService listService;
  ChatScreen(this._jobId, this._name, this.isDriverApp, {this.listService});

  @override
  _ChatScreenState createState() => _ChatScreenState(_jobId, _name, isDriverApp);
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final double _bubbleMargin = 15.0;
  final GlobalKey _bottomTextInputKey = GlobalKey();
  final String _jobId, _name;
  final TextEditingController _textEditingController = new TextEditingController();
  final ScrollController _listViewController = new ScrollController();
  final bool _isDriverApp;
  double _footerHeight = 0;
  double _readWidgetSize = 30;
  ChatService _chatService;
  List<CameraDescription> _cameras;
  CameraController _cameraController;
  String _inputMessage = "";
  bool _isUploading = false;

  _ChatScreenState(this._jobId, this._name, this._isDriverApp) {
    _chatService = ChatService(_jobId, _onNewMessage);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
    {
      setState(() {
        _footerHeight =
            _bottomTextInputKey.currentContext.size.height + _bubbleMargin;
      })
    });

    if (widget.listService != null)
      widget.listService.subscribe(() => setState((){}));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  _onNewMessage() async {
    setState(() { });
    await Future.delayed(Duration(milliseconds: 30));
    setState(() {
      _listViewController.animateTo(
        _listViewController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold (
          appBar: AppBar(
            title: Text(_name, style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
            brightness: Brightness.dark,
            centerTitle: false,
          ),
          body: Stack(
            children: <Widget>[
              _conversationField(),
              Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: _bottomTextInput()
              )
            ],
          ),
        )
    );
  }

  Widget _conversationField() => Container(
      height: MediaQuery.of(context).size.height,
      child: ListView(
        children: [
          _conversationBubbleShoppingList(widget.listService.shoppingList),
          ListView.builder (
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: _footerHeight + MediaQuery.of(context).padding.bottom),
              itemCount: _chatService.messageCount(),
              controller: _listViewController,
              itemBuilder: (BuildContext ctxt, int index) {
                Message msg = _chatService.readMessage(index);
                return _conversationBubble(msg);
              }
          )
        ],
      )
  );

  Widget _conversationBubbleShoppingList(List<ShoppingItem> items) {
    if (items == null || items.isEmpty)
      return Container();
    return Stack(
      children: [
        Row(
          mainAxisAlignment: _isDriverApp ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width/5*4),
                decoration: new BoxDecoration(
                    color: _isDriverApp ? Colors.blue : Colors.blueGrey,
                    borderRadius: new BorderRadius.only(
                        topLeft: Radius.circular(_isDriverApp ? 12.0 : 0.0),
                        topRight: Radius.circular(_isDriverApp ? 0.0 : 12.0),
                        bottomLeft: const Radius.circular(12.0),
                        bottomRight: const Radius.circular(12.0)
                    )
                ),
                alignment: _isDriverApp ? Alignment.topRight : Alignment.topLeft,
                margin: EdgeInsets.only(top: _bubbleMargin, right: _isDriverApp? _readWidgetSize : 4, left: 4),
                child : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ShoppingListViewScreen(widget.listService, _isDriverApp))
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 10, bottom: 20, left: 12, right: 12),
                      child: Column(
                        verticalDirection: VerticalDirection.up,
                        crossAxisAlignment: _isDriverApp ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: items.map((e) => Row(
                          mainAxisAlignment: _isDriverApp ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(e.name + " x " + e.count.toString(), style: TextStyle(fontSize: 16, color: Colors.white)),
                            Container(width:15,),
                            e.isChecked?Icon(Icons.check, color: Colors.white,):Icon(Icons.clear, color: Colors.white,)
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                )
            ),
          ],
        ),
        Positioned(child: _isDriverApp? _readWidget(true):Container(), bottom: 0, right: 0,),
      ],
    );
  }

  Widget _conversationBubble(Message msg) => Stack(
    children: [
      Row(
        mainAxisAlignment: _isDriverApp == msg.from_driver ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width/5*4),
            decoration: new BoxDecoration(
                color: _isDriverApp == msg.from_driver ? Colors.blue : Colors.blueGrey,
                borderRadius: new BorderRadius.only(
                    topLeft: Radius.circular(_isDriverApp == msg.from_driver ? 12.0 : 0.0),
                    topRight: Radius.circular(_isDriverApp == msg.from_driver ? 0.0 : 12.0),
                    bottomLeft: const Radius.circular(12.0),
                    bottomRight: const Radius.circular(12.0)
                )
            ),
            alignment: _isDriverApp == msg.from_driver ? Alignment.topRight : Alignment.topLeft,
            padding: msg.img == null ? EdgeInsets.only(top: 10, bottom: 20, left: 12, right: 12) : EdgeInsets.only(top: 10, bottom: 20, left: 6, right: 6),
            margin: EdgeInsets.only(top: _bubbleMargin, right: _isDriverApp == msg.from_driver? _readWidgetSize : 4, left: 4),
            child : Column(
              crossAxisAlignment: _isDriverApp == msg.from_driver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                msg.img == null ? Container() : Padding(
                  child: Image.network(msg.img, fit: BoxFit.fill),
                  padding: EdgeInsets.only(bottom: 10),
                ),

                Text(msg.message, style: TextStyle(fontSize: 16, color: Colors.white), ),
              ],
            ),
          ),
        ],
      ),
      Positioned(child: Text(msg.getMessageSendTimeReadable(), style: TextStyle(color: Colors.white70, fontSize: 11),), bottom: 4, right: _isDriverApp == msg.from_driver? _readWidgetSize + 8: null, left:_isDriverApp == msg.from_driver?null:12),
      Positioned(child: _isDriverApp != msg.from_driver? Container():_readWidget(msg.read), bottom: 0, right: 0,)
    ],
  );

  Widget _readWidget(bool isRead) => Container(
    width: _readWidgetSize,
    height: _readWidgetSize,
    child: Stack(
      children: [
        Center(
          child: Icon(Icons.adjust, color: Colors.grey, size: 17,),
        ),
        Center(
          child: Icon(Icons.circle, color: isRead? Colors.blue:Colors.white, size: 7,),
        ),
      ],
    ),
  );

  Widget _bottomTextInput() => Container(
      alignment: Alignment.bottomCenter,
      child: Container(
          key: _bottomTextInputKey,
          color: Colors.black,
          child: SafeArea(
              child: Container(
                padding: EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 4),
                child: Row (
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            hintText: "CHAT.TYPE_MESSAGE_HERE".tr(),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none
                        ),
                        onChanged: (value) => {
                          _inputMessage = value
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CameraScreen())
                        ).then((value) => {
                          _sendMessage(imagePath: value)
                        });
                      },
                      icon: Icon(Icons.photo_camera, color: Colors.white,),
                    ),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: Colors.white,),
                    )
                  ],
                ),
              )
          )
      )
  );

  _sendMessage({String imagePath}) async {
    if (_inputMessage.length == 0 && imagePath == null)
      return;
    String dbImagePath;
    if (imagePath != null) {
      setState(() {
        _isUploading = true;
      });
      dbImagePath = await _chatService.startUpload(imagePath);
      setState(() {
        _isUploading = false;
      });
    }
    Message message = new Message(from_driver: _isDriverApp, message: _inputMessage, img: dbImagePath);
    _chatService.sendMessage(message);
    _clearField();
  }

  _clearField() {
    setState(() {
      _textEditingController.clear();
      _inputMessage = "";
    });
  }
}