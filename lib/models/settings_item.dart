import 'package:flutter/cupertino.dart';

class SettingsItem {
  final String textKey;
  final VoidCallback onPressed;
  final Color color;
  Icon icon;


  SettingsItem({icon, this.color, this.textKey, this.onPressed}) {
    this.icon = Icon(icon, color: this.color);
  }
}