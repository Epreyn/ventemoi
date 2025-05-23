import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_bottom_app_bar/models/custom_bottom_app_bar_animation_model.dart';
import '../widgets/custom_bottom_app_bar_icon_button.dart';

class CustomBottomAppBarController extends GetxController {
  RxList<Widget> bottomAppBarChildren = <Widget>[].obs;

  Duration animationDuration = const Duration(milliseconds: 400);
  Duration animationDelay(int index) => Duration(milliseconds: 100 * index);
  Curve animationCurve = Curves.easeInOutBack;
  double yStartPosition = 40;
  bool isOpacity = true;

  CustomBottomAppBarAnimationModel get animationModel => CustomBottomAppBarAnimationModel(
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        yStartPosition: yStartPosition,
        isOpacity: isOpacity,
      );

  Future<void> defineBottomAppBarChildren() async {
    bottomAppBarChildren.clear();

    await UniquesControllers().data.loadIconList(
          UniquesControllers().data.firebaseAuth.currentUser!.uid,
        );

    for (int i = 0; i < UniquesControllers().data.dynamicIconList.length; i++) {
      bottomAppBarChildren.add(
        CustomBottomAppBarIconButton(
          tag: UniquesControllers().data.dynamicIconList[i].tag,
          delay: animationDelay(i),
          animationModel: animationModel,
          iconModel: UniquesControllers().data.dynamicIconList[i],
        ),
      );
    }
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    await defineBottomAppBarChildren();
  }
}
