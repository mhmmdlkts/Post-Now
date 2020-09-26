import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final double borderRadius;
  final VoidCallback onPositiveButtonPressed;
  final VoidCallback onNegativeButtonPressed;
  final String positiveButtonText;
  final String negativeButtonText;
  final String message;
  CustomAlertDialog({this.onPositiveButtonPressed, this.positiveButtonText, this.onNegativeButtonPressed, this.negativeButtonText, this.message, this.borderRadius = 15, Key key}) : super(key: key);

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
                  child: Text("message", style: TextStyle(fontSize: 24)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  child: Text(message, style: TextStyle(fontSize: 16)),
                ),
                Row(
                  children: [
                    _getButton(Colors.redAccent, negativeButtonText, onNegativeButtonPressed),
                    _getButton(Colors.lightBlueAccent, positiveButtonText, onPositiveButtonPressed),
                  ],
                ),
              ],
            )
          ),
        )
    );
  }

  _getButton(Color bgColor, String text, VoidCallback call) => Expanded(
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