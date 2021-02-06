import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/models/custom_notification.dart';

class CustomNotificationDialog extends StatefulWidget {
  final CustomNotification customNotification;

  CustomNotificationDialog(this.customNotification);

  @override
  State<StatefulWidget> createState() => CustomNotificationDialogState();

}

class CustomNotificationDialogState extends State<CustomNotificationDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(14),
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the card compact
        children: <Widget>[
          Text(
            widget.customNotification.title,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          widget.customNotification.image == null?Container(height: 10,):Image.network(widget.customNotification.image, height: 100),
          Text(
            widget.customNotification.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
          Opacity(
            opacity: isLoading?1:0,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: CircularProgressIndicator(),
            )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getButtonList(),
          )
        ],
      ),
    );
  }

  List<Widget> _getButtonList() {
    List<Widget> buttons = List();
    if (widget.customNotification.negativeText != null)
      buttons.add(FlatButton(
        child: Text(widget.customNotification.negativeText),
        onPressed: isLoading?null:() => {
          setState((){ isLoading = true; }),
          widget.customNotification.decline().then((value) => Navigator.pop(context)),
        },
      ));
    if (widget.customNotification.positiveText != null)
      buttons.add(FlatButton(
        child: Text(widget.customNotification.positiveText),
        onPressed: isLoading?null:() => {
          setState((){ isLoading = true; }),
          widget.customNotification.accept().then((value) => Navigator.pop(context)),
        },
      ));
    return buttons;
  }
}
