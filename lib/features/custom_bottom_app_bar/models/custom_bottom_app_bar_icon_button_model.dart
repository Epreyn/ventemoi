import 'package:flutter/material.dart';

class CustomBottomAppBarIconButtonModel {
  final String tag;
  final IconData? iconData;
  final String? text;
  final VoidCallback onPressed;

  CustomBottomAppBarIconButtonModel({
    required this.tag,
    this.iconData,
    this.text,
    required this.onPressed,
  });
}
