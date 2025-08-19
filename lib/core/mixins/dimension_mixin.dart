import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin DimensionMixin on GetxController {
  RxDouble maxWidth = 350.0.obs;
  double maxWidthPercentage = 0.9;
  double maxHeight = 400.0;
  double minHeight = 0.0;
  double minWidth = 0.0;
  
  BoxConstraints getConstraints({
    double? customMaxWidth,
    double? customMaxHeight,
    double? customMinWidth,
    double? customMinHeight,
  }) {
    return BoxConstraints(
      maxWidth: customMaxWidth ?? maxWidth.value,
      maxHeight: customMaxHeight ?? maxHeight,
      minWidth: customMinWidth ?? minWidth,
      minHeight: customMinHeight ?? minHeight,
    );
  }
  
  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = screenWidth * maxWidthPercentage;
    return calculatedWidth > maxWidth.value ? maxWidth.value : calculatedWidth;
  }
  
  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }
  
  bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 && width <= 1200;
  }
  
  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= 600;
  }
}