import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomFilledButtonController extends GetxController {
  RxDouble height = 50.0.obs;
  RxDouble width = 200.0.obs;

  Duration animationDuration = const Duration(milliseconds: 400);

  double spacingMultiplier = 1;

  Color blankColor = Colors.white;

  Alignment begin = Alignment.centerLeft;
  Alignment end = Alignment.centerRight;

  RxBool isHovered = false.obs;
  RxBool isPressed = false.obs;

  Decoration buildDecoration(
      bool? isEmpty, List<Color> backgroundColors, List<Color> foregroundColors, bool isPressed) {
    BoxDecoration? beginDecoration;
    BoxDecoration? endDecoration;
    DecorationTween? decorationTween;

    beginDecoration = isEmpty == true
        ? BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: const [
                Colors.transparent,
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: backgroundColors[0],
            ),
          )
        : BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: backgroundColors,
            ),
            border: null,
          );

    endDecoration = isEmpty == true
        ? BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: backgroundColors,
            ),
            border: null,
          )
        : BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: foregroundColors,
            ),
            border: Border.all(
              color: backgroundColors[0],
            ),
          );

    decorationTween = DecorationTween(
      begin: beginDecoration,
      end: endDecoration,
    );

    return decorationTween
        .animate(isPressed ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.0))
        .value;
  }
}
