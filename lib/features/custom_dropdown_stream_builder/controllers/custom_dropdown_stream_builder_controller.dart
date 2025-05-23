import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/nameable.dart';

class CustomDropdownStreamBuilderController<T extends Nameable> extends GetxController {
  double maxHeight = 40.0;
  double maxWith = 220.0;

  int dropDownElevation = 0;

  Color dropDownFocusColor = Colors.transparent;
  BorderRadius dropDownBorderRadius = const BorderRadius.all(Radius.circular(8));

  Icon dropDownIcon = const Icon(
    Icons.expand_more_rounded,
    size: 20,
  );

  InputDecoration dropDownDecoration(String? labelText) {
    return InputDecoration(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(90)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelText: labelText ?? '',
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
    );
  }
}
