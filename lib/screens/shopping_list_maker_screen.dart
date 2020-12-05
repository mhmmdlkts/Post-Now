import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/models/shopping_item.dart';

class ShoppingListMakerScreen extends StatefulWidget {
  List<ShoppingItem> items;
  final int freeItemCount;
  final double itemCost, sameItemCost;

  ShoppingListMakerScreen({this.items, this.itemCost, this.freeItemCount, this.sameItemCost}) {
    if (this.items == null)
      this.items = [];
  }

  @override
  _ShoppingListMakerScreenState createState() => _ShoppingListMakerScreenState();
}

class _ShoppingListMakerScreenState extends State<ShoppingListMakerScreen> {

  TextEditingController _inputController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  double _padding = 20;
  bool _isAdding = true;
  bool _isDecTapDown = false;
  bool _isIncTapDown = false;
  final List<ShoppingItem> copyList = List();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isAdding = _focusNode.hasFocus;
      });
    });
    for (int i = 0; i < widget.items.length; i++)
      copyList.add(ShoppingItem.copy(widget.items[i]));
    _isAdding = copyList.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showAreYouSureDialog,
      child: Scaffold(
        appBar: AppBar(
          title: Text("SHOPPING_LIST_MAKER.TITLE".tr(), style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
          brightness: Brightness.dark,
          actions: [
            _isAdding?IconButton(icon: Icon(Icons.check), onPressed: () => setState((){
              _isAdding = false;
            }),)
                : IconButton(icon: Icon(Icons.add_shopping_cart), onPressed: _addItem,),
          ],
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              copyList.length == 0? _getInfoTextContent():
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: copyList.length,
                  itemBuilder: (_, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: _padding, vertical: 10),
                      child: _singleElement(index)
                  ),
                  separatorBuilder: (_, index) => Divider(),
                ),
              ),
              Divider(height: 0),
              _getBottomWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showAreYouSureDialog() async {
    if (!_someThingChanged())
      return true;
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return false;
    }
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "WARNING".tr(),
            message: "SHOPPING_LIST_MAKER.DIALOGS.BACK.CONTENT".tr(namedArgs: {'size': copyList.length.toString()}),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "ACCEPT".tr(),
          );
        }
    ) ?? false;
  }

  Widget _getInfoTextContent() {
    Color darkColor = Colors.black87;
    double fontSize = 20;
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'SHOPPING_LIST_MAKER.BAR_PAYING_INFO.PART1'.tr() + ' ',
            style: TextStyle(
              color: darkColor,
              fontSize: fontSize
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'SHOPPING_LIST_MAKER.BAR_PAYING_INFO.PART2'.tr(),
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' ' + 'SHOPPING_LIST_MAKER.BAR_PAYING_INFO.PART3'.tr(),
                style: TextStyle(color: darkColor, fontSize: fontSize)
              ),
            ]
          ),
        )
      )
    );
  }



  Widget _getBottomWidget() {
    return _isAdding ? Row(
        children: [
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: _isAdding,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: _padding),
                  hintText: "SHOPPING_LIST_MAKER.TEXT_FIELD_HINT".tr(),
                  hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  border: InputBorder.none
              ),
              onChanged: (val) => setState((){}),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: Material(
                color: _inputController.text.length>0?primaryBlue:Colors.green,
                child: InkWell(
                  onTap: _inputController.text.length>0?_onAddButtonClick:() => setState((){ _isAdding = false;}),
                  child: Container(
                      margin: EdgeInsets.all(10),
                      child: _inputController.text.length>0?Icon(Icons.add, color: Colors.white,): Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white)
                  ),
                ),
              ),
            )
          )
        ],
      ):Container(
        padding: EdgeInsets.only(left: _padding, right: _padding, top: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TOTAL".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
                Text(ShoppingItem.calcPrice(copyList, widget.freeItemCount, widget.itemCost, widget.sameItemCost).toStringAsFixed(2) + " €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
              ],
            ),
            Container(height: 15,),
            Text("SHOPPING_LIST_MAKER.LEGAL".tr(namedArgs: {"amount": widget.freeItemCount.toString(), "price": widget.itemCost.toStringAsFixed(2)})),
            Container(height: 15,),
            ButtonTheme(
              minWidth: double.infinity,
              height: 56,
              child: RaisedButton (
                color: primaryBlue,
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                child: Text("APPLY".tr(), style: TextStyle(color: Colors.white, fontSize: 24),),
                onPressed: copyList.isNotEmpty?_apply:null,
              ),
            ),
          ],
        ),
      );
  }

  Widget _singleElement(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(copyList[index].name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
              widget.freeItemCount > index?Text(copyList[index].count<=1?"FREE".tr():(ShoppingItem.calcSamePrice(copyList[index], widget.sameItemCost).toStringAsFixed(2) + " €") , style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),)
                  :Text((widget.itemCost + ShoppingItem.calcSamePrice(copyList[index], widget.sameItemCost)).toStringAsFixed(2) + " €"),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onLongPress: () async {
                _isDecTapDown = true;
                while(_isDecTapDown&& copyList[index].count > 1) {
                  setState(() { copyList[index].count--; });
                  await Future.delayed(Duration(milliseconds: 30));
                }
              },
              onLongPressEnd: (_) { _isDecTapDown = false; },
              onTap: () => copyList[index].count <= 1?_onClickRemove(index):_onClickDec(index),
              child: _getAddRemoveWidget(icon: Icons.remove, bgColor: copyList[index].count <= 1?Colors.red.withOpacity(0.6):Colors.grey.withOpacity(0.6), textColor: copyList[index].count <= 1?Colors.white:Colors.white, leftBorder: 5),
            ),
            _getAddRemoveWidget(text: copyList[index].count.toString(), bgColor: primaryBlue, textColor: Colors.white),
            GestureDetector(
              onLongPress: () async {
                _isIncTapDown = true;
                while(_isIncTapDown) {
                  setState(() { copyList[index].count++; });
                  await Future.delayed(Duration(milliseconds: 30));
                }
              },
              onLongPressEnd: (_) { _isIncTapDown = false; },
              onTap: () => _onClickInc(index),
              child: _getAddRemoveWidget(icon: Icons.add, bgColor: Colors.grey.withOpacity(0.6), textColor: Colors.white,  rightBorder: 5),
            ),
          ],
        )
      ],
    );
  }
  
  Widget _getAddRemoveWidget({String text, IconData icon, Color bgColor, Color textColor, double rightBorder=0, double leftBorder=0}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(leftBorder), right: Radius.circular(rightBorder)),
      ),
      height: 40,
      width: 40,
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Center(
        child:  text!=null?Text(text, style: TextStyle(color: textColor, fontSize: 20), textAlign: TextAlign.center,):Icon(icon, color: textColor,),
      )
    );
  }

  _apply() {
    Navigator.pop(context, copyList);
  }

  _addItem() {
    setState(() {
      _isAdding = true;
    });
  }

  _onClickInc(int index) {
    setState((){
      copyList[index].count++;
    });
  }

  _onClickRemove(int index) {
    setState(() {
      copyList.removeAt(index);
    });
  }

  _onClickDec(int index) {
    setState((){
      copyList[index].count--;
    });
  }

  _onAddButtonClick() {
    _focusNode.requestFocus();
    String val = _inputController.text;
    if (val.length < 1)
      return;
    setState(() {
      copyList.add(ShoppingItem(count: 1, name: val));
      _clearInputField();
    });
  }

  _clearInputField() {
    _inputController.text = "";
  }

  bool _someThingChanged() {
    if (widget.items.length != copyList.length)
      return true;
    if (widget.items.length == 0)
      return false;
    for (int i = 0; i < widget.items.length; i++)
      if (copyList[i] != widget.items[i])
        return true;
    return false;
  }
}