import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_loader/view/custom_loader.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_space/view/custom_space.dart';
import '../controllers/custom_text_stream_controller.dart';

class CustomTextStream extends StatelessWidget {
  final String collectionName;
  final String? documentId;
  final String fieldToDisplay;
  final bool? isTitle;

  const CustomTextStream({
    super.key,
    required this.collectionName,
    required this.documentId,
    required this.fieldToDisplay,
    this.isTitle,
  });

  @override
  Widget build(BuildContext context) {
    final String controllerTag = '$collectionName-$fieldToDisplay';
    CustomTextStreamController controller;
    if (Get.isRegistered<CustomTextStreamController>(tag: controllerTag)) {
      controller = Get.find<CustomTextStreamController>(tag: controllerTag);
    } else {
      controller = Get.put(
        CustomTextStreamController(
          collectionName: collectionName,
          initialDocumentId: documentId,
          fieldToDisplay: fieldToDisplay,
        ),
        tag: controllerTag,
      );
    }

    if (documentId != null && documentId != controller.documentIdRx.value) {
      controller.documentIdRx.value = documentId!;
    }

    return Obx(() {
      final text = controller.textValue.value;

      if (controller.documentIdRx.value.isEmpty) {
        return CustomLoader(
          size: UniquesControllers().data.baseSpace * 2,
        );
      }

      if (text.isEmpty) {
        return const Row(
          children: [
            CustomSpace(widthMultiplier: 2),
            Text('Entrez votre nom dans votre profil.'),
          ],
        );
      }

      if (text.startsWith('Erreur:')) {
        return Text(text);
      }

      if (text == 'Document introuvable.') {
        return const Text('Document introuvable.');
      }

      return (isTitle ?? false)
          ? Center(
              child: Row(
                children: [
                  const CustomSpace(widthMultiplier: 2),
                  Text(
                    text,
                    style: TextStyle(
                      //color: CustomColors.caribbeanCurrent,

                      fontWeight: FontWeight.w500,
                      letterSpacing: UniquesControllers().data.baseSpace / 4,
                      wordSpacing: UniquesControllers().data.baseSpace / 2,
                      fontSize: UniquesControllers().data.baseSpace * 2.5,
                    ),
                  ),
                ],
              ),
            )
          : Text(text);
    });
  }
}
