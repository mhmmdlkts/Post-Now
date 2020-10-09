import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_package;
import 'package:path_provider/path_provider.dart';
import 'package:postnow/models/message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io' as i;

import 'package:postnow/services/chat_service.dart';


class ChatScreen extends StatefulWidget {
  final String _jobId, _name;
  final bool _isDriverApp;
  ChatScreen(this._jobId, this._name, this._isDriverApp);

  @override
  _ChatScreenState createState() => _ChatScreenState(_jobId, _name, _isDriverApp);
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
  // Future<void> _initializeControllerFuture;
  List<CameraDescription> _cameras;
  CameraController _cameraController;
  String _inputMessage = "";
  String _imagePath = "";
  bool _isUploading = false;
  bool _isCameraOpen = false;
  bool _showCapturedPhoto = false;
  bool _isBackCamera = true;

  _ChatScreenState(this._jobId, this._name, this._isDriverApp) {
    _chatService = ChatService(_jobId, _onNewMessage);
  }

  @override
  void initState() {
    super.initState();
    _isCameraOpen = false;
    _showCapturedPhoto = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => {
      setState(() {
        _footerHeight = _bottomTextInputKey.currentContext.size.height + _bubbleMargin;
      })
    });

    _getNextCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cameraController != null) {
      // _initializeControllerFuture = _cameraController.initialize();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  _getNextCamera() async {
    if (_cameras == null)
      _cameras = await availableCameras();
    _cameraController = CameraController(_isBackCamera ? _cameras.first : _cameras.last,ResolutionPreset.high);
    // _initializeControllerFuture = _cameraController.initialize();
    if (!mounted)
      return;
  }

  _onNewMessage() async { // TODO belki yeni gelen mesaj daha listede yok ayar cekmen gerekebilir
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
              Positioned(
                child: _isCameraOpen ? _cameraOrImageField() : _conversationField(),
              ),
              Positioned(
                  child: new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: _bottomTextInput()
                  )
              )
            ],
          ),
        )
    );
  }

  Widget _conversationField() => Container(
      height: MediaQuery.of(context).size.height,
      child: new ListView.builder (
          padding: EdgeInsets.only(bottom: _footerHeight),
          controller: _listViewController,
          itemCount: _chatService.messageCount(),
          itemBuilder: (BuildContext ctxt, int index) {
            Message msg = _chatService.readMessage(index);
            return _conversationBubble(msg);
          }
      )
  );

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
                  child: Image.network(
                      msg.img,
                      fit: BoxFit.fill),
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
          color: Colors.blue,
          child: SafeArea(
              child: Container(
                padding: EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 4),
                decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(width: 0.5, color: Colors.white70),
                      bottom: BorderSide(width: 0.5, color: Colors.white70),
                    )
                ),
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
                    _isCameraOpen ? SizedBox.shrink() :
                    IconButton(
                      onPressed: () {
                        _openCameraWindow();
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

  _openCameraWindow() async {
    setState(() {
      _isCameraOpen = true;
    });
  }

  _cameraPrev() => Stack(
    children: <Widget>[
      CameraPreview(_cameraController,),
      /*Positioned.fill(
          top: 10,
          right: 10,
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.switch_camera, color: Colors.white,),
              onPressed: () => {
                setState(() {
                  isBackCamera = !isBackCamera; // TODO ...
                })
              },
            ),
          )
      ),*/
      Positioned.fill(
          bottom: 130,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              child: Icon(Icons.photo_camera, color: Colors.white,),
              onPressed: _onCaptureButtonPressed,
            ),
          )
      ),
    ],
  );


  _onCaptureButtonPressed() async {  //on camera button presstry {
    try {
      final path = path_package.join(
        (await getTemporaryDirectory()).path, //Temporary path
        '${DateTime.now()}.png',
      );
      _imagePath = path;
      await _cameraController.takePicture(_imagePath); //take photo
      print(_showCapturedPhoto);
      setState(() {
        _showCapturedPhoto = true;
      });
    } catch (e) {
      print(e);
    }
  }


  Widget _cameraOrImageField() => Stack(
      children: <Widget>[
        _showCapturedPhoto? Image.file(i.File(_imagePath)):_cameraPrev(),
        Positioned.fill(
            top: 10,
            left: 10,
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(_showCapturedPhoto? Icons.arrow_back_ios : Icons.clear, color: Colors.white,),
                onPressed: () => {
                  setState(() {
                    _showCapturedPhoto = false;
                    if (!_showCapturedPhoto)
                      _isCameraOpen = false;
                  })
                },
              ),
            )
        ),
        !_isUploading ? Container():
        Positioned.fill(
            top: 10,
            left: 10,
            child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator()
            )
        ),
      ]
  );

  bool _isMessageSendable() => _isCameraOpen ? _showCapturedPhoto : true;

  _sendMessage() async {
    if (!_isMessageSendable())
      return;
    if (_inputMessage.length == 0 && _imagePath.length == 0)
      return;
    String dbImagePath;
    if (_imagePath != "") {
      setState(() {
        _isUploading = true;
      });
      dbImagePath = await _chatService.startUpload(_imagePath);
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
      _imagePath = "";
      _inputMessage = "";
      _isCameraOpen = false;
      _showCapturedPhoto = false;
    });
  }
}
