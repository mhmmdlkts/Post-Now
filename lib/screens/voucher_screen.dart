import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:postnow/services/voucher_service.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class VoucherScreen extends StatefulWidget {
  final String uid;
  VoucherScreen(this.uid, {Key key}) : super(key: key);

  @override
  _VoucherScreen createState() => _VoucherScreen();
}

class _VoucherScreen extends State<VoucherScreen> {
  final VoucherService _voucherService = VoucherService();
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  bool _typing = false;
  String _qrText = "";
  QRViewController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        brightness: Brightness.dark,
        iconTheme:  IconThemeData(color: Colors.white),
        title: Text('VOUCHER.TITLE'.tr()),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                Visibility(
                  visible: !_typing,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    child: Container(
                      decoration: new BoxDecoration(
                        shape: BoxShape.rectangle,
                        border: Border.all(color: Colors.black45, width: 15, style: BorderStyle.solid),
                        borderRadius: BorderRadius.all(Radius.circular(35.0)),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 0,
                  child: TextField(
                    onTap: () {
                      setState(() {
                        _typing = false;
                        _controller?.dispose();
                      });
                    },
                    onChanged: (val) {
                      if (val.trim().length == 20)
                        _tryCode(val.trim());
                    },
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: new InputDecoration(
                      hintText: "VOUCHER.TEXT_FIELD_MESSAGE".tr(),
                      hintStyle: TextStyle(color: Colors.white60),
                      contentPadding: new EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                )
              ],
            )
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(_qrText, style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this._controller = controller;
    controller.scannedDataStream.listen(_tryCode);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _tryCode(scanData) {
    _voucherService.enCashVoucher(scanData, widget.uid).then((value) => {
      setState((){
        if (value['errorCode'] != 0) {
          _qrText = _voucherService.getErrorMessage(value['errorCode']);
        } else {
          _qrText = "VOUCHER.SUCCESS_MESSAGE".tr(namedArgs: {'value': value['value'].toString()});
          _controller.pauseCamera();
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context);
          });
        }
      })
    });
  }
}