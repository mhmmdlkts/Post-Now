import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:postnow/models/settings_item.dart';

class SettingsDialog extends StatelessWidget {
  final List<SettingsItem> settingsItems;
  final double borderRadius;
  SettingsDialog(this.settingsItems, {this.borderRadius = 15, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius))
      ),
      elevation: 0.0,
      backgroundColor: Colors.black87,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        child:  Container(
          child: ListView.separated (
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.white60,
              ),
              itemCount: settingsItems.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return _buildMenuItem(settingsItems[index], context);
              }
          ),
        ),
      )
    );
  }

  Widget _buildMenuItem(SettingsItem item, BuildContext ctx) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          item.onPressed();
          await Future.delayed(Duration(milliseconds: 400));
          Navigator.of(ctx).pop();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              item.icon == null? Container() : item.icon,
              Container(width: 10),
              Flexible(
                child: Text(item.textKey.tr(), style: TextStyle(fontSize: 18, color: item.color)),
              )
            ],
          ),
        ),
      ),
    );
  }

}