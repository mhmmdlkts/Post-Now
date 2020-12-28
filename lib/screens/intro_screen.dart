import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intro_slider/dot_animation_enum.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onDoneClick;
  IntroScreen(this.onDoneClick, {Key key}) : super(key: key);

  @override
  _IntroScreenState createState() => new _IntroScreenState(onDoneClick);
}

class _IntroScreenState extends State<IntroScreen> {
  final VoidCallback onDoneClick;
  final List<Slide> slides = new List();

  Function goToTab;

  _IntroScreenState(this.onDoneClick);

  @override
  void initState() {
    super.initState();

    slides.add(
      new Slide(
        title: "INTRO.PAGE1.TITLE".tr(),
        styleTitle: TextStyle(
            color: Colors.white,
            fontSize: 30.0,
            fontWeight: FontWeight.bold),
        description: "INTRO.PAGE1.DESCRIPTION".tr(),
        styleDescription: TextStyle(
            color: Colors.white70,
            fontSize: 20.0),
        pathImage: "assets/package_map_marker.png",

      ),
    );
    slides.add(
      new Slide(
        title: "INTRO.PAGE2.TITLE".tr(),
        styleTitle: TextStyle(
            color: Colors.white,
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono'),
        description: "INTRO.PAGE2.DESCRIPTION".tr(),
        styleDescription: TextStyle(
            color: Colors.white70,
            fontSize: 20.0,),
        pathImage: "assets/home_map_marker.png",
      ),
    );
    slides.add(
      new Slide(
        title: "INTRO.PAGE3.TITLE".tr(),
        styleTitle: TextStyle(
            color: Colors.white,
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono'),
        description: "INTRO.PAGE3.DESCRIPTION".tr(),
        styleDescription: TextStyle(
            color: Colors.white70,
            fontSize: 20.0,),
        pathImage: "assets/driver_map_marker.png",
      ),
    );
  }

  void onDonePress() {
    onDoneClick.call();
  }

  void onTabChangeCompleted(index) {
    // Index of current tab is focused
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: Colors.lightBlueAccent,
      size: 35.0,
    );
  }

  Widget renderDoneBtn() {
    return Icon(
      Icons.done,
      color: Colors.lightBlueAccent,
    );
  }

  Widget renderPrevBtn() {
    return Icon(
      Icons.navigate_before,
      color: Colors.lightBlueAccent,
    );
  }

  List<Widget> renderListCustomTabs() {
    List<Widget> tabs = new List();
    for (int i = 0; i < slides.length; i++) {
      Slide currentSlide = slides[i];
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          margin: EdgeInsets.only(bottom: 60.0, top: 60.0),
          child: ListView(
            children: <Widget>[
              GestureDetector(
                  child: Image.asset(
                    currentSlide.pathImage,
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.contain,
                  )),
              Container(
                child: Text(
                  currentSlide.title,
                  style: currentSlide.styleTitle,
                  textAlign: TextAlign.center,
                ),
                margin: EdgeInsets.only(top: 20.0),
              ),
              Container(
                child: Text(
                  currentSlide.description,
                  style: currentSlide.styleDescription,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                margin: EdgeInsets.only(top: 20.0),
              ),
            ],
          ),
        ),
      ));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return getSlides();
  }

  Widget getSlides() => new IntroSlider(
    isScrollable: false,
    isShowSkipBtn: false,
    isShowPrevBtn: true,
    // List slides
    slides: this.slides,

    // Next button
    renderNextBtn: this.renderNextBtn(),
    renderPrevBtn: this.renderPrevBtn(),

    colorPrevBtn: Colors.white,
    highlightColorPrevBtn: Colors.white70,

    // Done button
    renderDoneBtn: this.renderDoneBtn(),
    onDonePress: () => Navigator.of(context).pop(),
    colorDoneBtn: Colors.white,
    highlightColorDoneBtn: Colors.white70,

    // Dot indicator
    colorDot: Colors.white,
    sizeDot: 10.0,
    typeDotAnimation: dotSliderAnimation.SIZE_TRANSITION,

    // Tabs
    listCustomTabs: this.renderListCustomTabs(),
    backgroundColorAllSlides: Colors.lightBlueAccent,
    refFuncGoToTab: (refFunc) {
      this.goToTab = refFunc;
    },

    // Show or hide status bar
    shouldHideStatusBar: true,

    // On tab change completed
    onTabChangeCompleted: this.onTabChangeCompleted,
  );
}
