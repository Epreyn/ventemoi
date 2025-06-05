import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../custom_icon_button/view/custom_icon_button.dart';
import '../../custom_loader/view/custom_loader.dart';
import '../../custom_logo/view/custom_logo.dart';
import '../controllers/custom_profile_image_picker_controller.dart';

class CustomProfileImagePicker extends StatelessWidget {
  final String tag;
  final bool? haveToReset;
  final double? size;

  const CustomProfileImagePicker({
    super.key,
    required this.tag,
    this.haveToReset,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      CustomProfileImagePickerController(haveToReset: haveToReset),
      tag: tag,
    );

    final avatarSize = size ?? UniquesControllers().data.baseSpace * 15;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Cercle extérieur avec gradient
          Container(
            width: avatarSize + 16,
            height: avatarSize + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomTheme.lightScheme().primary,
                  CustomTheme.lightScheme().primary.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Cercle intérieur blanc
          Container(
            width: avatarSize + 8,
            height: avatarSize + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // Container de l'image
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: ClipOval(
              child: Obx(() {
                // Si l'user a choisi un nouveau fichier
                if (UniquesControllers().data.isPickedFile.value) {
                  // 1) ProfileImageFile
                  if (UniquesControllers().data.profileImageFile.value !=
                      null) {
                    return Image.file(
                      UniquesControllers().data.profileImageFile.value!,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                    );
                  }
                  // 2) ProfileImageBytes
                  else if (UniquesControllers().data.profileImageBytes.value !=
                      null) {
                    return Image.memory(
                      UniquesControllers().data.profileImageBytes.value!,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                    );
                  }
                }

                // L'user n'a pas pick => on regarde oldImageUrl
                final oldUrl = UniquesControllers().data.oldImageUrl.value;
                if (oldUrl.isNotEmpty) {
                  // On affiche l'ancienne photo
                  return Image.network(
                    oldUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CustomLoader(
                          size: avatarSize * 0.3,
                          color: CustomTheme.lightScheme().primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(avatarSize);
                    },
                  );
                }

                // Ni isPickedFile, ni oldImage => placeholder
                return _buildPlaceholder(avatarSize);
              }),
            ),
          ),

          // Bouton pour changer la photo
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    CustomTheme.lightScheme().primary,
                    CustomTheme.lightScheme().primary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => cc.pickImage(),
                  child: Container(
                    padding: EdgeInsets.all(
                        UniquesControllers().data.baseSpace * 1.5),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: UniquesControllers().data.baseSpace * 2.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
