import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../controllers/custom_decorated_text_controller.dart';

class CustomDecoratedText extends StatelessWidget {
  final String tag;
  final RxString text;
  final String label;

  const CustomDecoratedText({
    super.key,
    required this.tag,
    required this.text,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final CustomDecoratedTextController cc = Get.put(
      CustomDecoratedTextController(),
      tag: tag,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 58,
            maxHeight: 58,
            minWidth: cc.maxWith.value,
            maxWidth: cc.maxWith.value,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
              ),
              borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace / 2),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: UniquesControllers().data.baseSpace / 2,
                vertical: UniquesControllers().data.baseSpace / 2,
              ),
              child: Center(
                child: Obx(
                  () => Text(
                    text.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                      fontSize: UniquesControllers().data.baseSpace * 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -UniquesControllers().data.baseSpace,
          left: UniquesControllers().data.baseSpace + UniquesControllers().data.baseSpace / 2,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace / 2,
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
