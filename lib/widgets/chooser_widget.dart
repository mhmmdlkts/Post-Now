import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/enums/order_typ_enum.dart';
import 'package:postnow/presentation/my_flutter_app_icons.dart';

class ChooserWidget extends StatelessWidget {
  final void Function(OrderTypEnum) callback;
  ChooserWidget(this.callback, { Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _getButtonWidget(
                context,
                onPressed: () => callback.call(OrderTypEnum.PACKAGE),
                icon: MyFlutterApp.car_side,
                text: "CHOOSER_MENU.PACKAGE".tr()
              ),
              _getButtonWidget(
                context,
                onPressed: () => callback.call(OrderTypEnum.SHOPPING),
                icon: Icons.shopping_cart,
                text: "CHOOSER_MENU.SHOP".tr()
              )
            ],
          )
        ),
      ),
    );
  }

  Widget _getButtonWidget(BuildContext context, {VoidCallback onPressed, IconData icon, String text}) {
    BorderRadius borderRadius = BorderRadius.all(Radius.circular(10));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: Colors.white70,
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.width * 0.3,
          decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.9),
              borderRadius: borderRadius
          ),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white,),
                Container(height: 10,),
                Text(text, style: TextStyle(color: Colors.white),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}