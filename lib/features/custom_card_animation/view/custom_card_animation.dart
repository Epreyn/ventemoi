import 'package:flutter/material.dart';

import '../../../features/custom_animation/view/custom_animation.dart';

enum Direction { left, right, top, bottom }

class CustomCardAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Direction? direction;
  final int? delayGap;
  final String? refreshKey;

  const CustomCardAnimation({
    super.key,
    required this.index,
    required this.child,
    this.direction,
    this.delayGap,
    this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    var delayGap = this.delayGap ?? 100;

    // Inclure refreshKey dans le tag pour forcer la recréation de l'animation
    final uniqueTag = refreshKey != null
        ? 'card_animation_${refreshKey}_$index'
        : 'card_animation_$index';

    return CustomAnimation(
      key: ValueKey(uniqueTag),
      fixedTag: uniqueTag,
      delay: Duration(milliseconds: delayGap * index),
      duration: Duration(milliseconds: 6 * delayGap),
      isOpacity: true,
      xStartPosition: direction == Direction.left
          ? delayGap.toDouble() / 4
          : direction == Direction.right
              ? -delayGap.toDouble() / 4
              : 0,
      // yStartPosition: delayGap.toDouble() / 4,
      yStartPosition: direction == null
          ? delayGap.toDouble() / 4
          : direction == Direction.top
              ? delayGap.toDouble() / 4
              : direction == Direction.bottom
                  ? -delayGap.toDouble() / 4
                  : 0,
      curve: Curves.easeInOutBack,
      child: child,
    );
  }
}
