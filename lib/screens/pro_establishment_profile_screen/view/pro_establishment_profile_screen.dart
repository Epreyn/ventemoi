import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/establishment_category.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/pro_establishment_profile_screen_controller.dart';

class ProEstablishmentProfileScreen extends StatelessWidget {
  const ProEstablishmentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ec = Get.put(ProEstablishmentProfileScreenController());

    return ScreenLayout(
      fabOnPressed: ec.saveEstablishmentProfile,
      fabIcon: const Icon(Icons.save),
      fabText: const Text('Enregistrer les modifications'),

      // On écoute le flux du doc "establishment"
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: ec.getEstablishmentDocStream(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          // Quand on reçoit les données, on remplit le form
          if (data != null) {
            ec.nameCtrl.text = data['name'] ?? '';
            ec.descriptionCtrl.text = data['description'] ?? '';
            ec.addressCtrl.text = data['address'] ?? '';
            ec.emailCtrl.text = data['email'] ?? '';
            ec.phoneCtrl.text = data['telephone'] ?? '';
            ec.videoCtrl.text = data['video_url'] ?? '';

            // Bannières / logos
            if (!ec.isPickedBanner.value) {
              ec.bannerUrl.value = data['banner_url'] ?? '';
            }
            if (!ec.isPickedLogo.value) {
              ec.logoUrl.value = data['logo_url'] ?? '';
            }

            // Catégorie unique
            final catId = data['category_id'] ?? '';
            if (catId.isNotEmpty &&
                (ec.currentCategory.value == null ||
                    ec.currentCategory.value?.id != catId)) {
              ec.getCategoryById(catId).then((cat) {
                ec.currentCategory.value = cat;
              });
            }

            // Catégories multiples (entreprise)
            final List<dynamic>? entCats =
                data['enterprise_categories'] as List<dynamic>?;
            if (entCats != null) {
              final strList = entCats.map((e) => e.toString()).toList();
              ec.enterpriseCatsIds.value = strList;
            }
          }

          return Center(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ec.maxFormWidth),
                  child: Form(
                    key: ec.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO
                        CustomCardAnimation(
                          index: 0,
                          child: Obx(() => ec.buildLogoWidget()),
                        ),
                        const CustomSpace(heightMultiplier: 1),
                        CustomCardAnimation(
                          index: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: ec.pickLogo,
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Changer le logo'),
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // BANNIÈRE
                        CustomCardAnimation(
                          index: 2,
                          child: Obx(() => ec.buildBannerWidget()),
                        ),
                        const CustomSpace(heightMultiplier: 1),
                        CustomCardAnimation(
                          index: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: ec.pickBanner,
                              icon: const Icon(Icons.photo),
                              label: const Text('Changer la bannière'),
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Nom
                        CustomCardAnimation(
                          index: 4,
                          child: CustomTextFormField(
                            tag: ec.nameTag,
                            labelText: ec.nameLabel,
                            controller: ec.nameCtrl,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Description
                        CustomCardAnimation(
                          index: 5,
                          child: CustomTextFormField(
                            tag: ec.descriptionTag,
                            labelText: ec.descriptionLabel,
                            minLines: ec.descriptionMinLines,
                            maxLines: ec.descriptionMaxLines,
                            maxCharacters: ec.descriptionMaxCharacters,
                            controller: ec.descriptionCtrl,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Adresse
                        CustomCardAnimation(
                          index: 6,
                          child: CustomTextFormField(
                            tag: ec.addressTag,
                            labelText: ec.addressLabel,
                            controller: ec.addressCtrl,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Email
                        CustomCardAnimation(
                          index: 7,
                          child: CustomTextFormField(
                            tag: ec.emailTag,
                            labelText: ec.emailLabel,
                            controller: ec.emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Téléphone
                        CustomCardAnimation(
                          index: 8,
                          child: CustomTextFormField(
                            tag: ec.phoneTag,
                            labelText: ec.phoneLabel,
                            controller: ec.phoneCtrl,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Champ vidéo
                        CustomCardAnimation(
                          index: 9,
                          child: CustomTextFormField(
                            tag: ec.videoTag,
                            labelText: ec.videoLabel,
                            controller: ec.videoCtrl,
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 2),

                        // Catégories
                        CustomCardAnimation(
                          index: 10,
                          child: Obx(() {
                            final userType = ec.currentUserType.value;
                            if (userType != null &&
                                userType.name == 'Entreprise') {
                              // Checklist multiple
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catégories (max ${ec.maxEnterpriseCats})',
                                    style: TextStyle(
                                      fontSize:
                                          UniquesControllers().data.baseSpace *
                                              1.6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 1),
                                  _buildEnterpriseMultipleSelection(ec),
                                ],
                              );
                            } else {
                              // Dropdown "category"
                              return CustomDropdownStreamBuilder<
                                  EstablishmentCategory>(
                                tag: ec.categoryTag,
                                stream: ec.getCategoriesStream(),
                                initialItem: ec.currentCategory,
                                labelText: ec.categoryLabel,
                                maxWith: ec.categoryMaxWidth,
                                maxHeight: ec.categoryMaxHeight,
                                onChanged: (EstablishmentCategory? cat) {
                                  ec.currentCategory.value = cat;
                                },
                              );
                            }
                          }),
                        ),

                        const CustomSpace(heightMultiplier: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit la checklist multiple pour les "enterprise_categories"
  Widget _buildEnterpriseMultipleSelection(
      ProEstablishmentProfileScreenController ec) {
    return StreamBuilder<List<EnterpriseCategory>>(
      stream: ec.getEnterpriseCategoriesStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Text('Chargement...');
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Text('Aucune catégorie entreprise disponible');
        }

        return Column(
          children: List.generate(list.length, (i) {
            final entCat = list[i];
            return Obx(() {
              final isSelected = ec.enterpriseCatsIds.contains(entCat.id);
              return CheckboxListTile(
                title: Text(entCat.name),
                value: isSelected,
                onChanged: (val) {
                  if (val == true) {
                    // On veut cocher => vérifier max 2
                    if (ec.enterpriseCatsIds.length >= ec.maxEnterpriseCats) {
                      UniquesControllers().data.snackbar(
                            'Limite atteinte',
                            'Vous ne pouvez pas sélectionner plus de 2 catégories',
                            true,
                          );
                      return;
                    }
                    ec.enterpriseCatsIds.add(entCat.id);
                  } else {
                    ec.enterpriseCatsIds.remove(entCat.id);
                  }
                },
              );
            });
          }),
        );
      },
    );
  }
}
