import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/models/shopping_item.dart';
import 'package:postnow/services/shopping_list_service.dart';

class ShoppingListViewScreen extends StatefulWidget {
  final ShoppingListService listService;
  final bool isEditable;
  ShoppingListViewScreen(this.listService, this.isEditable);

  @override
  _ShoppingListViewScreenState createState() => _ShoppingListViewScreenState();
}

class _ShoppingListViewScreenState extends State<ShoppingListViewScreen> {

  @override
  void initState() {
    super.initState();
    widget.listService.subscribe(() => setState((){}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("SHOPPING_LIST.TITLE".tr(), style: TextStyle(color: Colors.white),),
          brightness: Brightness.dark,
          iconTheme:  IconThemeData( color: Colors.white)
      ),
      body: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10),
          shrinkWrap: true,
          itemCount: widget.listService.shoppingList.length,
          itemBuilder: (_, int index) {
            return _getSingleItem(widget.listService.shoppingList[index]);
          }
      ),
    );
  }

  Widget _getSingleItem(ShoppingItem item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        onTap: widget.isEditable?() {
          item.isChecked = !item.isChecked;
          widget.listService.changeItemStatus(item.id, item.isChecked);
        }:null,
        child: Container(
          decoration: BoxDecoration(
              color: item.isChecked?primaryBlue.withAlpha(60):Colors.black.withAlpha(30),
              borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.count.toString() + " x " + item.name, style: TextStyle(fontSize: 24)),
              IconButton(icon: Icon(Icons.check_circle, color: !item.isChecked?Colors.white:primaryBlue,))
            ],
          ),
        ),
      ),
    );
  }
}