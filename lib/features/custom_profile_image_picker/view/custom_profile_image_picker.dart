import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../custom_icon_button/view/custom_icon_button.dart';
import '../../custom_logo/view/custom_logo.dart';
import '../controllers/custom_profile_image_picker_controller.dart';

class CustomProfileImagePicker extends StatelessWidget {
  final String tag;

  /// Si [haveToReset] == true, on appelle `resetValues()` dans onReady().
  final bool? haveToReset;

  const CustomProfileImagePicker({
    super.key,
    required this.tag,
    this.haveToReset,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      CustomProfileImagePickerController(haveToReset: haveToReset),
      tag: tag,
    );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Premier cercle “background”
          CircleAvatar(
            radius: UniquesControllers().data.baseSpace * 8,
          ),

          // Second cercle (contient l'image)
          CircleAvatar(
            radius: UniquesControllers().data.baseSpace * 7.5,
            backgroundColor: CustomTheme.lightScheme().surface,
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: UniquesControllers().data.baseSpace * 15,
                    height: UniquesControllers().data.baseSpace * 15,
                  ),
                  // On observe isPickedFile / oldImageUrl
                  Obx(() {
                    // Si l'user a choisi un nouveau fichier
                    if (UniquesControllers().data.isPickedFile.value) {
                      // 1) ProfileImageFile
                      if (UniquesControllers().data.profileImageFile.value != null) {
                        return CircleAvatar(
                          radius: UniquesControllers().data.baseSpace * 7.5,
                          backgroundImage: FileImage(
                            UniquesControllers().data.profileImageFile.value!,
                          ),
                        );
                      }
                      // 2) ProfileImageBytes
                      else if (UniquesControllers().data.profileImageBytes.value != null) {
                        return CircleAvatar(
                          radius: UniquesControllers().data.baseSpace * 7.5,
                          backgroundImage: MemoryImage(
                            UniquesControllers().data.profileImageBytes.value!,
                          ),
                        );
                      }
                      // Sinon, rien => pas d’image
                      return const SizedBox.shrink();
                    } else {
                      // L'user n'a pas pick => on regarde oldImageUrl
                      final oldUrl = UniquesControllers().data.oldImageUrl.value;
                      if (oldUrl.isNotEmpty) {
                        // On affiche l’ancienne photo
                        return CircleAvatar(
                          radius: UniquesControllers().data.baseSpace * 7.5,
                          backgroundImage: NetworkImage(oldUrl),
                        );
                      } else {
                        // Ni isPickedFile, ni oldImage => le logo
                        return const CustomLogo();
                      }
                    }
                  }),
                ],
              ),
            ),
          ),

          // Le bouton en position bottom-right
          Positioned(
            bottom: -UniquesControllers().data.baseSpace * 1.5,
            right: -UniquesControllers().data.baseSpace * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: UniquesControllers().data.baseSpace * 3,
                ),
                CircleAvatar(
                  radius: UniquesControllers().data.baseSpace * 2.5,
                  backgroundColor: CustomTheme.lightScheme().surface,
                ),
                CustomIconButton(
                  tag: 'pick-product-image-button-$tag',
                  iconData: Icons.add_a_photo_outlined,
                  onPressed: () => cc.pickImage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
