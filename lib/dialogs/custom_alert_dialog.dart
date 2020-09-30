import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final double borderRadius;
  final String positiveButtonText;
  final String negativeButtonText;
  final String title;
  final String message;
  CustomAlertDialog({this.positiveButtonText = "", this.negativeButtonText, this.title, this.message, this.borderRadius = 15, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
        elevation: 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          child:  Container(
            color: Colors.white,
            child: ListView (
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  child: Text(title, style: TextStyle(fontSize: 24)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  child: Text(message, style: TextStyle(fontSize: 16)),
                ),
                Row(
                  children: [
                    _getButton(Colors.redAccent, negativeButtonText, () {Navigator.pop(context, false);}),
                    _getButton(Colors.lightBlueAccent, positiveButtonText, () {Navigator.pop(context, true);}),
                  ],
                ),
              ],
            )
          ),
        )
    );
  }

  _getButton(Color bgColor, String text, VoidCallback call) {
    if (text == null)
      return Container();
    return Expanded(
        child: Material(
          color: bgColor,
          child: InkWell(
              onTap: call,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
              )
          ),
        )
    );
  }
}