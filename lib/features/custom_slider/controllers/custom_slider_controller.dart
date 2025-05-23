import 'package:get/get.dart';

class CustomSliderController extends GetxController {
  RxDouble maxWith = 350.0.obs;

  RxBool isExpanded = false.obs;
  Duration duration = const Duration(milliseconds: 400);
}
