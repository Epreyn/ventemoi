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

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

    return Obx(() {
      final text = controller.textValue.value;

      if (controller.documentIdRx.value.isEmpty) {
        return CustomLoader(
          size: UniquesControllers().data.baseSpace * 2,
        );
      }

      if (text.isEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomSpace(widthMultiplier: 2),
            Flexible(
              child: Text(
                isSmallScreen
                    ? 'Entrez votre nom'
                    : 'Entrez votre nom dans votre profil.',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        );
      }

      if (text.startsWith('Erreur:')) {
        return Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }

      if (text == 'Document introuvable.') {
        return const Text(
          'Document introuvable.',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }

      // Calculate responsive font size
      double responsiveFontSize;
      if (isTitle ?? false) {
        if (isSmallScreen) {
          responsiveFontSize =
              UniquesControllers().data.baseSpace * 2; // Smaller on mobile
        } else if (isMediumScreen) {
          responsiveFontSize = UniquesControllers().data.baseSpace * 2.3;
        } else {
          responsiveFontSize = UniquesControllers().data.baseSpace * 2.5;
        }
      } else {
        responsiveFontSize = UniquesControllers().data.baseSpace * 1.8;
      }

      return (isTitle ?? false)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomSpace(widthMultiplier: 2),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      letterSpacing: UniquesControllers().data.baseSpace / 4,
                      wordSpacing: UniquesControllers().data.baseSpace / 2,
                      fontSize: responsiveFontSize,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: responsiveFontSize,
              ),
            );
    });
  }
}
