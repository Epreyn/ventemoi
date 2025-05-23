import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_bottom_app_bar/models/custom_bottom_app_bar_icon_button_model.dart';

class CustomNavigationMenuController extends GetxController {
  RxList<CustomBottomAppBarIconButtonModel> items =
      <CustomBottomAppBarIconButtonModel>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadItems();
  }

  Future<void> loadItems() async {
    await UniquesControllers().data.loadIconList(
          UniquesControllers().data.firebaseAuth.currentUser!.uid,
        );
    items.value = UniquesControllers().data.dynamicIconList;
  }

  void onItemTap(int index) {
    if (index < 0 || index >= items.length) return;
    UniquesControllers().data.currentNavigationMenuIndex.value = index;
    final item = items[index];
    item.onPressed();
  }
}
