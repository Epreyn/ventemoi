import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/mixins/animation_mixin.dart';
import '../../../core/mixins/interactive_mixin.dart';

class CustomFilledButtonController extends GetxController with AnimationMixin, InteractiveMixin {
  RxDouble height = 50.0.obs;
  RxDouble width = 200.0.obs;

  // animationDuration inherited from AnimationMixin
  // isHovered and isPressed inherited from InteractiveMixin

  double spacingMultiplier = 1;

  Color blankColor = Colors.white;

  Alignment begin = Alignment.centerLeft;
  Alignment end = Alignment.centerRight;

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
