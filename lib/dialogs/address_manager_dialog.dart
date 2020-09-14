import 'package:circular_check_box/circular_check_box.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/models/address.dart';

class AddressManager extends StatefulWidget {
  final Address address;
  AddressManager(this.address, {Key key}) : super(key: key);

  @override
  _AddressManager createState() => _AddressManager(address);
}

class _AddressManager extends State<AddressManager> {
  final Address _address;
  String _errorMessage = "";
  bool _extraService = true;
  TextEditingController _houseNumberController, _doorNumberController, _doorNameController;

  _AddressManager(this._address) : assert(_address != null);

  @override
  void initState() {
    super.initState();
    _houseNumberController = new TextEditingController(text: _address.houseNumber);
    _doorNumberController = new TextEditingController(text: _address.doorNumber);
    _doorNameController = new TextEditingController(text: _address.doorName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Container(
      width: 300,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        shrinkWrap: true,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("DIALOGS.ADDRESS_MANAGER.TITLE".tr(), style: TextStyle(fontSize: 24),),
              Divider(thickness: 1),
              Row(
                children: [
                  Flexible(
                    child: Text("DIALOGS.ADDRESS_MANAGER.I_WILL_COME".tr()),
                  ),
                  CircularCheckBox(
                    onChanged: (value) {
                      setState(() {
                        _extraService = value;
                        if (!value) {
                          _doorNumberController.clear();
                          _address.doorNumber = null;
                        }
                      });
                    },
                    value: _extraService,
                  ),
                ],
              ),
              Divider(thickness: 1),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      maxLength: 5,
                      autofocus: !Address.isStringNotEmpty(_address.houseNumber),
                      keyboardType: TextInputType.numberWithOptions(signed: true),
                      controller: _houseNumberController,
                      onChanged: (val) {
                        setState(() {
                          _address.houseNumber = val;
                        });
                      },
                      decoration: InputDecoration(labelText: 'DIALOGS.ADDRESS_MANAGER.HOUSE_NUMBER'.tr(), hintText: 'DIALOGS.ADDRESS_MANAGER.HOUSE_NUMBER'.tr(), counterText: ""),
                    ),
                  ),
                  Container(
                    width: 10,
                  ),
                  Flexible(
                    child: TextField(
                      enabled: _extraService,
                      maxLength: 5,
                      autofocus: Address.isStringNotEmpty(_address.houseNumber) && !Address.isStringNotEmpty(_address.doorNumber),
                      keyboardType: TextInputType.numberWithOptions(signed: true),
                      controller: _doorNumberController,
                      onChanged: (val) {
                        setState(() {
                          _address.doorNumber = val;
                        });
                      },
                      decoration: InputDecoration(labelText: 'DIALOGS.ADDRESS_MANAGER.DOOR_NUMBER'.tr(), hintText: 'DIALOGS.ADDRESS_MANAGER.DOOR_NUMBER'.tr(), counterText: ""),
                    ),
                  ),
                ],
              ),
              TextField(
                maxLength: 25,
                autofocus: Address.isStringNotEmpty(_address.houseNumber) && Address.isStringNotEmpty(_address.doorNumber) && !Address.isStringNotEmpty(_address.doorName),
                controller: _doorNameController,
                onChanged: (val) {
                  setState(() {
                    _address.doorName = val;
                  });
                },
                decoration: InputDecoration(labelText: 'DIALOGS.ADDRESS_MANAGER.DOOR_NAME'.tr(), hintText: 'DIALOGS.ADDRESS_MANAGER.DOOR_NAME'.tr(), counterText: ""),
              ),
              Container(height: 14,),
              Flexible(
                child:Text(_errorMessage, style: TextStyle(color: Colors.redAccent)),
              ),
              Divider(thickness: 1),
              Flexible(
                child: Text(_address.getAddress(), style: TextStyle(fontSize: 16)),
              ),
              Divider(thickness: 1,
                height: 24,),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: FlatButton(
                  color: Colors.lightBlue,
                  child: Text('ACCEPT'.tr(), style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: _onAcceptButtonClick,
                ),
              ),
            ],
          ),
        ],
      )
    );
  }

  _onAcceptButtonClick() {
    setState(() {
      _errorMessage = _getErrorMessage();
    });
    if (_errorMessage.length != 0)
      return;
    Navigator.pop(context, _address);
  }

  String _getErrorMessage() {
    if (!Address.isStringNotEmpty(_address.houseNumber))
      return "DIALOGS.ADDRESS_MANAGER.ERROR_MESSAGES.HOUSE_NUMBER_IS_NEEDED".tr();
    if (!Address.isStringNotEmpty(_address.doorNumber) && _extraService)
      return "DIALOGS.ADDRESS_MANAGER.ERROR_MESSAGES.DOOR_NUMBER_IS_NEEDED".tr();
    if (!Address.isStringNotEmpty(_address.doorName))
      return "DIALOGS.ADDRESS_MANAGER.ERROR_MESSAGES.DOOR_NAME_IS_NEEDED".tr();
    return "";
  }
}