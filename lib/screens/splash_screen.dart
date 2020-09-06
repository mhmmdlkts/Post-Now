import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    Key key
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeAsyncDependencies();
  }

  Future<void> _initializeAsyncDependencies() async {
    // >>> initialize async dependencies <<<
    // >>> register favorite dependency manager <<<
    // >>> reap benefits <<<
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Screen',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: _buildBody(),
    );
  }

  Widget _buildBody() {
    return new Scaffold(
      backgroundColor: Color.fromARGB(255, 41, 171, 226),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset('assets/postnow_icon.png', width: 120),
          )
        ],
      )
    );
  }
}