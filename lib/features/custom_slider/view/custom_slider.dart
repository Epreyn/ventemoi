import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../controllers/custom_slider_controller.dart';

class CustomSlider extends StatelessWidget {
  final String tag;
  final RxDouble value;
  final String sliderLabel;

  final Function(double) onChanged;

  const CustomSlider({
    super.key,
    required this.tag,
    required this.value,
    required this.sliderLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final CustomSliderController cc = Get.put(
      CustomSliderController(),
      tag: tag,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
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
              child: Obx(
                () => Slider(
                  value: value.value,
                  onChanged: onChanged,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: value.value.round().toString(),
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
              sliderLabel,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
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
