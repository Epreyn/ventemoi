import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_animation/view/custom_animation.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final double? leadingWidgetNumber;
  final Widget? title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.leading,
    this.leadingWidgetNumber,
    this.title,
    this.actions,
  }) : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leadingWidth: leadingWidgetNumber == null
          ? UniquesControllers().data.baseAppBarHeight
          : UniquesControllers().data.baseAppBarHeight * leadingWidgetNumber!,
      leading: leading != null
          ? CustomAnimation(
              duration: UniquesControllers().data.baseAnimationDuration,
              delay: UniquesControllers().data.baseAnimationDuration,
              curve: Curves.easeOutQuart,
              xStartPosition: -UniquesControllers().data.baseAppBarHeight / 2,
              isOpacity: true,
              child: leading!,
            )
          : null,
      title: title != null
          ? CustomAnimation(
              duration: UniquesControllers().data.baseAnimationDuration,
              delay: UniquesControllers().data.baseAnimationDuration,
              curve: Curves.easeOutQuart,
              yStartPosition: -UniquesControllers().data.baseAppBarHeight / 2,
              isOpacity: true,
              child: title!,
            )
          : null,
      actions: actions?.map((action) {
        var index = actions!.indexOf(action) + 1;
        return CustomAnimation(
          duration: UniquesControllers().data.baseAnimationDuration,
          delay: UniquesControllers().data.baseAnimationDuration * index,
          curve: Curves.easeOutQuart,
          xStartPosition: UniquesControllers().data.baseAppBarHeight / 2,
          isOpacity: true,
          child: action,
        );
      }).toList(),
    );
  }
}
