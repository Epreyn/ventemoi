import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/custom_filled_button_controller.dart';

class CustomFilledButton extends StatelessWidget {
  final String tag;
  final String text;
  final List<Color> backgroundColors;
  final List<Color> foregroundColors;
  final bool? isEmpty;
  final Function() onPressed;

  const CustomFilledButton({
    super.key,
    required this.tag,
    required this.text,
    required this.backgroundColors,
    required this.foregroundColors,
    this.isEmpty,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    CustomFilledButtonController cc = Get.put(
      CustomFilledButtonController(),
      tag: tag,
    );

    return Obx(
      () => AnimatedContainer(
        duration: cc.animationDuration,
        width: cc.width.value,
        height: cc.height.value,
        decoration: cc.buildDecoration(isEmpty, backgroundColors, foregroundColors, cc.isPressed.value),
        child: MouseRegion(
          onEnter: (_) {
            cc.isHovered.value = true;
          },
          onExit: (_) {
            cc.isHovered.value = false;
          },
          child: GestureDetector(
            onTap: onPressed,
            onTapDown: (_) {
              cc.isPressed.value = true;
            },
            onTapUp: (_) {
              cc.isPressed.value = false;
            },
            onTapCancel: () {
              cc.isHovered.value = false;
              cc.isPressed.value = false;
            },
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: cc.begin,
                end: cc.end,
                colors: cc.isPressed.value == false
                    ? (isEmpty == true ? backgroundColors : foregroundColors)
                    : (isEmpty == true ? foregroundColors : backgroundColors),
              ).createShader(bounds),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: cc.animationDuration,
                  curve: Curves.elasticOut,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: cc.isPressed.value ? FontWeight.w800 : FontWeight.w400,
                    fontFamily: 'SpaceGrotesk',
                    letterSpacing: cc.isHovered.value == true
                        ? cc.isPressed.value == true
                            ? 2
                            : 4
                        : 2,
                  ),
                  child: Text(
                    text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
