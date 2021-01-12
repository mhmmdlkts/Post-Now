import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path_package;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as i;

import 'package:postnow/enums/permission_typ_enum.dart';
import 'package:postnow/services/permission_service.dart';

class CameraScreen extends StatefulWidget {

  CameraScreen();

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController controller;
  bool _showCapturedPhoto = false;
  String _imagePath = "";

  @override
  void initState() {
    super.initState();

    PermissionService.positionIsNotGranted(PermissionTypEnum.CAMERA, context: context).then((value) => {
      if (value)
        Navigator.pop(context, null)
      else
        initCamera()
    });
  }

  initCamera() {
    availableCameras().then((value) => {
      controller = CameraController(value[0], ResolutionPreset.high, enableAudio: false),
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black,);
    }

    return Material(
      child: Stack(
        children: [
          _cameraImage(),
          Positioned.fill(
              bottom: 50,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _showCapturedPhoto? acceptPhotoFab():takePhotoFab(),
              )
          ),
          Positioned.fill(
              top: 10,
              left: 10,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white,),
                    onPressed: () => {
                      Navigator.pop(context, null),
                    },
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }


  _onCaptureButtonPressed() async {
    try {
      _imagePath = path_package.join( (await getTemporaryDirectory()).path, '${DateTime.now()}.png',);
      await controller.takePicture(_imagePath);
      setState(() {
        _showCapturedPhoto = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget acceptPhotoFab() {
    return FloatingActionButton(
      child: Icon(Icons.send, color: Colors.white,),
      onPressed: () {
        Navigator.pop(context, _imagePath);
      },
    );
  }

  Widget takePhotoFab() {
    return FloatingActionButton(
      child: Icon(Icons.photo_camera, color: Colors.white,),
      onPressed: _onCaptureButtonPressed,
    );
  }
  
  Widget _cameraImage() {
    final deviceRatio = MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    return Transform.scale(
      scale: controller.value.aspectRatio / deviceRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: _showCapturedPhoto? Image.file(i.File(_imagePath)):CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class Post extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Post"),
    );
  }
}
