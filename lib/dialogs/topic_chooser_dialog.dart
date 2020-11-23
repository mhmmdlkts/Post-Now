import 'package:circular_check_box/circular_check_box.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/services/maps_service.dart';

class TopicChooserDialog extends StatefulWidget {
  final List<String> topics;
  final double borderRadius;
  TopicChooserDialog(this.topics, {this.borderRadius = 15});

  @override
  _TopicChooserDialogState createState() => _TopicChooserDialogState();
}

class _TopicChooserDialogState extends State<TopicChooserDialog> {

  List<Color> _c = [Colors.transparent];
  
  @override
  void initState() {
    _c.addAll(List.filled(20, Colors.white));
    _c.add(Colors.transparent);
    widget.topics.insert(0, "");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          margin: EdgeInsets.only(top: 70),
          child: Row(
            children: [
              Flexible(child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide.none

                  ),
                  isDense: true,
                  fillColor: primaryBlue,
                  filled: true,
                  hintText: "SEARCH".tr(),
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 20),
                  suffixIcon: Icon(Icons.search, color: Colors.white,),
                ),
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 20),
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) {
                  setState(() {
                    widget.topics[0] = val;
                  });
                },
              ),),
              Container(
                margin: EdgeInsets.only(left: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material (
                    color: Colors.red,
                    child: InkWell(
                      onTap: _close,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                          decoration: BoxDecoration(
                          ),
                          child: IconButton(icon: Icon(Icons.close, color: Colors.white,),)
                      ),
                    ),
                  ),
                )
              )
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _c,
            ).createShader(bounds);
          },
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: widget.topics.where((element) => element.toString().length >= 1 && element.toString().toLowerCase().contains(widget.topics[0].toLowerCase())).toList().map((e) => _singleElement(e)).toList(),
              ),
            ],
          ),
        ),
        /*Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _close(),
            child: Icon(Icons.close, color: Colors.white,),
            backgroundColor: Colors.redAccent,
          ),
        )*/
      ],
    );
  }

  void _close() => Navigator.pop(context,null);

  Widget _singleElement(String e, {double borderRadius = 10}) => Container(
    padding: EdgeInsets.all(10),
    child: Material(
      borderRadius: BorderRadius.circular(borderRadius),
      color: primaryBlue,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () {
          Navigator.pop(context, e);
        },
        child: Container(
          padding: EdgeInsets.all(10),
          child: Text(e, style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center,),
        ),
      ),
    ),
  );
}