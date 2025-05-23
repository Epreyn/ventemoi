import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../features/custom_navigation_menu/controllers/custom_navigation_menu_controller.dart';
import 'custom_data.dart';

class UniquesControllers extends GetxController {
  static final UniquesControllers _instance = UniquesControllers._();
  factory UniquesControllers() => _instance;
  UniquesControllers._();

  CustomData data = Get.put(CustomData());
  GetStorage getStorage = GetStorage('Storage');
}
