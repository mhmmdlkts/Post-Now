import 'package:circular_check_box/circular_check_box.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/services/order_detail_dialog_service.dart';

class OrderDetailDialog extends StatefulWidget {
  final String jobId;
  final double borderRadius;
  OrderDetailDialog(this.jobId, {this.borderRadius = 15, Key key}) : super(key: key);

  @override
  _OrderDetailDialogState createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  OrderDetailDialogService _detailDialogService;
  TextEditingController _messageController = new TextEditingController();
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _detailDialogService = OrderDetailDialogService(widget.jobId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
      child: Container(
          padding: EdgeInsets.only(top: 8),
          decoration: new BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (c){setState(() {

                      });},
                      maxLines: 5,
                      minLines: 5,
                      autofocus: true,
                      controller: _messageController,
                      decoration: InputDecoration(border: InputBorder.none, hintText: 'DIALOGS.ORDER_DETAILS.MESSAGE'.tr(), counterText: _messageController.text.trim().length.toString()),
                    ),
                    Flexible(
                      child:Text(_errorMessage, style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: Material(
                    color: Colors.lightBlue,
                    child: InkWell(
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text('SEND'.tr(), style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                      onTap: _onNextButtonClick,
                    ),
                  )
              ),
            ],
          )
      ),
    );
  }

  _onNextButtonClick() {
    setState(() {
      _errorMessage = _getErrorMessage();
    });
    if (_messageController.text.trim().length == 0)
      return;
    _detailDialogService.sendDetails(_messageController.text);
    Navigator.pop(context, _messageController.text);
  }

  String _getErrorMessage() {
    if (_messageController.text.isEmpty)
      return "DIALOGS.ORDER_DETAILS.ERROR_MESSAGES.MESSAGE_IS_EMPTY".tr();
    return "";
  }
}