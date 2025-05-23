import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/unique_controllers.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

import '../controllers/custom_bottom_app_bar_controller.dart';

class CustomBottomAppBar extends StatelessWidget {
  final String tag;

  const CustomBottomAppBar({
    Key? key,
    required this.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomBottomAppBarController(), tag: tag);

    return Obx(() {
      if (cc.bottomAppBarChildren.isEmpty) {
        return const BottomAppBar(color: Colors.transparent);
      } else {
        return BottomAppBar(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated divider (optional)
              CustomCardAnimation(
                direction: Direction.bottom,
                index: 0,
                child: Divider(
                  height: 1,
                  indent: UniquesControllers().data.baseSpace * 4,
                  endIndent: UniquesControllers().data.baseSpace * 4,
                  color: CustomTheme.lightScheme().onPrimary,
                ),
              ),
              const CustomSpace(heightMultiplier: 2),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: UniquesControllers().data.baseSpace * 2),
                    child: ConstrainedBox(
                      // Force the Row to be at least as wide as the screen
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: cc.bottomAppBarChildren.map((child) {
                          return Padding(
                            // ensures at least some space around each button
                            padding: EdgeInsets.symmetric(
                              horizontal: UniquesControllers().data.baseSpace,
                            ),
                            child: child,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    });
  }
}
