import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CustomTextFormFieldController extends GetxController {
  final TextEditingController? controller;
  final int? maxCharacters;

  CustomTextFormFieldController({this.controller, this.maxCharacters});

  double maxWidth = 350.0;

  double maxWidthPercentage = 0.9;
  RxBool isObscure = false.obs;

  final RxInt currentLength = 0.obs;
  final List<TextInputFormatter> inputFormatters = [];

  void initIsPassword(bool? isPassword) {
    if (isPassword != null) {
      isObscure.value = isPassword;
    }
  }

  void maxCharactersListener() {
    if (maxCharacters != null) {
      inputFormatters.add(LengthLimitingTextInputFormatter(maxCharacters));
      currentLength.value = controller!.text.length;
    }
  }
}
