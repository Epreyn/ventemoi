import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomProfileImagePickerController extends GetxController {
  final bool? haveToReset;

  CustomProfileImagePickerController({this.haveToReset});

  // Remet à zéro les variables "globales" (dans UniquesControllers().data)
  void resetValues() {
    UniquesControllers().data.isPickedFile.value = false;
    UniquesControllers().data.profileImageFile.value = null;
    UniquesControllers().data.profileImageBytes.value = null;
  }

  @override
  void onReady() {
    super.onReady();
    // Si haveToReset == true => on appelle resetValues()
    if (haveToReset == true) {
      resetValues();
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;

    // On signale qu’on a un "picked file"
    UniquesControllers().data.isPickedFile.value = true;

    if (!kIsWeb && f.path != null) {
      // Mode mobile/desktop
      UniquesControllers().data.profileImageFile.value = File(f.path!);
      UniquesControllers().data.profileImageBytes.value = null;
    } else if (kIsWeb && f.bytes != null) {
      // Mode web
      UniquesControllers().data.profileImageFile.value = null;
      UniquesControllers().data.profileImageBytes.value = f.bytes;
    }
  }
}
