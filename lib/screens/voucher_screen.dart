import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrText = "";
  QRViewController controller;

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
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                Container(
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
              ],
            )
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(qrText, style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      _voucherService.enCashVoucher(scanData, widget.uid).then((value) => {
        setState((){
          if (value['errorCode'] != 0) {
            qrText = _voucherService.getErrorMessage(value['errorCode']);
          } else {
            qrText = "VOUCHER.SUCCESS_MESSAGE".tr(namedArgs: {'value': value['value'].toString()});
            controller.pauseCamera();
            Future.delayed(Duration(seconds: 2), () {
              Navigator.pop(context);
            });
          }
        })
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}