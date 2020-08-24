import 'package:camera/camera.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_package;
import 'package:path_provider/path_provider.dart';
import 'package:postnow/core/service/model/message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io' as i;


class Chat_Screen extends StatefulWidget {
  final String jobId, name;
  final bool isDriverApp;
  Chat_Screen(this.jobId, this.name, this.isDriverApp);

  @override
  _Chat_ScreenState createState() => _Chat_ScreenState(jobId, name, isDriverApp);
}

class _Chat_ScreenState extends State<Chat_Screen> {
  final String jobId, name;
  final bool isDriverApp;
  DatabaseReference ref;
  String inputMessage = "";
  TextEditingController textEditingController = new TextEditingController();
  ScrollController listViewController = new ScrollController();
  List<Message> messages = new List();
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  bool isCameraOpen = false;
  bool showCapturedPhoto = false;
  var imagePath = "";
  List<CameraDescription> cameras;
  bool isBackCamera = true;

  _Chat_ScreenState(this.jobId, this.name, this.isDriverApp);

  @override
  void initState() {
    super.initState();
    isCameraOpen = false;
    showCapturedPhoto = false;

    ref = FirebaseDatabase.instance.reference().child('jobs_chat').child(jobId);
    ref.onChildAdded.listen(onNewMessage);
    getNextCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cameraController != null
          ? _initializeControllerFuture = _cameraController.initialize()
          : null; //on pause camera is disposed, so we need to call again "issue is only for android"
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  getNextCamera() async {
    if (cameras == null)
      cameras = await availableCameras();
    _cameraController = CameraController(isBackCamera ? cameras.first : cameras.last,ResolutionPreset.high);
    _initializeControllerFuture = _cameraController.initialize();
    if (!mounted)
      return;
  }

  onNewMessage(event) {
    Message message = Message.fromSnapshot(event.snapshot);
    listViewController.animateTo(
      listViewController.position.maxScrollExtent + 20,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );

    setState(() {
      messages.add(message);
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
            title: Text(name, style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
            brightness: Brightness.dark,
            centerTitle: false,
          ),
          body: Stack(
            children: <Widget>[
              Positioned(
                child: isCameraOpen ? cameraOrImageField() : conversationField(),
              ),
              Positioned(
                  child: new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: bottomTextInput()
                  )
              )
            ],
          ),
        )
    );
  }

  Widget conversationField() => Container(
      height: MediaQuery.of(context).size.height,
      child: new ListView.builder (
          controller: listViewController,
          itemCount: messages.length,
          itemBuilder: (BuildContext ctxt, int index) {
            return Stack(
                children: <Widget>[
                  conversationBubble(messages[index].message, messages[index].img, messages[index].send_time.toString(), messages[index].from_driver),
                  Container(height: messages.length-1 == index?160:null,)
                ]
            );
          }
      )
  );

  Widget conversationBubble(String message, String imgPath, String sendTime, bool fromDriver) => Row(
    mainAxisAlignment: isDriverApp == fromDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: <Widget>[
      Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width/5*4),
        decoration: new BoxDecoration(
            color: isDriverApp == fromDriver ? Colors.blue : Colors.blueGrey,
            borderRadius: new BorderRadius.only(
                topLeft: Radius.circular(isDriverApp == fromDriver ? 12.0 : 0.0),
                topRight: Radius.circular(isDriverApp == fromDriver ? 0.0 : 12.0),
                bottomLeft: const Radius.circular(12.0),
                bottomRight: const Radius.circular(12.0)
            )
        ),
        alignment: isDriverApp == fromDriver ? Alignment.topRight : Alignment.topLeft,
        padding: imgPath == null ? EdgeInsets.all(12) : EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        margin: EdgeInsets.only(top: 15, right: 4, left: 4),
        child : Column(
          crossAxisAlignment: isDriverApp == fromDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            imgPath == null ? Container() : Padding(
              child: Image.network(
                  imgPath,
                  fit: BoxFit.fill),
              padding: EdgeInsets.only(bottom: 10),
            ),

            Text(message, style: TextStyle(fontSize: 16, color: Colors.white), ),
          ],
        ),
      )
    ],
  );

  Widget bottomTextInput() => Container(
      alignment: Alignment.bottomCenter,
      child: Container(
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
                        controller: textEditingController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            hintText: "CHAT.TYPE_MESSAGE_HERE".tr(),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none
                        ),
                        onChanged: (value) => {
                          inputMessage = value
                        },
                      ),
                    ),
                    isCameraOpen ? SizedBox.shrink() :
                    IconButton(
                      onPressed: () {
                        openCameraWindow();
                      },
                      icon: Icon(Icons.photo_camera, color: Colors.white,),
                    ),
                    IconButton(
                      onPressed: sendMessage,
                      icon: Icon(Icons.send, color: Colors.white,),
                    )
                  ],
                ),
              )
          )
      )
  );

  void openCameraWindow() async {
    setState(() {
      isCameraOpen = true;
    });
  }

  cameraPrev() => Stack(
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
              onPressed: onCaptureButtonPressed,
            ),
          )
      ),
    ],
  );


  void onCaptureButtonPressed() async {  //on camera button presstry {
    try {
      final path = path_package.join(
        (await getTemporaryDirectory()).path, //Temporary path
        '${DateTime.now()}.png',
      );
      imagePath = path;
      await _cameraController.takePicture(imagePath); //take photo
      print(showCapturedPhoto);
      setState(() {
        showCapturedPhoto = true;
      });
    } catch (e) {
      print(e);
    }
  }


  Widget cameraOrImageField() => Stack(
      children: <Widget>[
        showCapturedPhoto? Image.file(i.File(imagePath)):cameraPrev(),
        Positioned.fill(
            top: 10,
            left: 10,
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(showCapturedPhoto? Icons.arrow_back_ios : Icons.clear, color: Colors.white,),
                onPressed: () => {
                  setState(() {
                    showCapturedPhoto = false;
                    if (!showCapturedPhoto)
                      isCameraOpen = false;
                  })
                },
              ),
            )
        ),
        _uploadTask == null ? Container():
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

  bool isMessageSendable() => isCameraOpen ? showCapturedPhoto : true;

  sendMessage() async {
    if (!isMessageSendable())
      return;
    if (inputMessage.length == 0 && imagePath.length == 0)
      return;
    String dbImagePath;
    if (imagePath != "") {
      dbImagePath = await startUpload('chat/images/$jobId/${DateTime.now()}.png', imagePath);
    }
    Message message = new Message(from_driver: isDriverApp, message: inputMessage, img: dbImagePath);
    ref.push().set(message.toMap());
    clearField();
  }

  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://post-now-f3c53.appspot.com');
  StorageUploadTask _uploadTask;

  Future<String> startUpload(dbImagePath, imagePath) async {
    if (imagePath == null || dbImagePath == null) {
      return null;
    }
    setState(() {
      _uploadTask = _storage.ref().child(dbImagePath).putFile(i.File(imagePath));
    });
    var snapshot = await _uploadTask.onComplete;
    setState(() {
      _uploadTask = null;
    });
    return await snapshot.ref.getDownloadURL();
  }

  void clearField() {
    setState(() {
      textEditingController.clear();
      imagePath = "";
      inputMessage = "";
      isCameraOpen = false;
      showCapturedPhoto = false;
    });
  }
}
