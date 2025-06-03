import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/establishment_category.dart';

import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import '../../../features/custom_places_autocompletion/view/custom_places_autocompletion.dart'
    show CustomPlacesAutocomplete;
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/pro_establishment_profile_screen_controller.dart';
import 'package:ventemoi/firebase_options.dart';

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
                          child: CustomPlacesAutocomplete(
                            controller: ec.addressCtrl,
                            apiKey: DefaultFirebaseOptions.googleKeyAPI,
                            hintText: "Adresse de l'établissement...",
                            countries: ['fr'],
                            decoration: InputDecoration(
                              labelText: ec.addressLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(90),
                              ),
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                        ),

                        // CustomCardAnimation(
                        //   index: 6,
                        //   child: GooglePlaceAutoCompleteTextField(
                        //     textEditingController: ec.addressCtrl,
                        //     language: 'fr',
                        //     googleAPIKey: DefaultFirebaseOptions.googleKeyAPI,
                        //     inputDecoration: InputDecoration(
                        //       hintText: "Entrez une adresse...",
                        //       border: OutlineInputBorder(),
                        //       suffixIcon: Icon(Icons.search),
                        //     ),
                        //     debounceTime: 800,
                        //     countries: ['fr'],
                        //     placeType: PlaceType.address,
                        //     itemClick: (prediction) {
                        //       ec.addressCtrl.text =
                        //           prediction.description ?? '';
                        //       ec.addressCtrl.selection =
                        //           TextSelection.fromPosition(
                        //         TextPosition(
                        //             offset: ec.addressCtrl.text.length),
                        //       );
                        //     },
                        //   ),
                        // ),
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
                              // Dropdowns multiples pour les entreprises
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catégories (${ec.enterpriseCategorySlots.value} slots disponibles)',
                                    style: TextStyle(
                                      fontSize:
                                          UniquesControllers().data.baseSpace *
                                              1.6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  _buildEnterpriseMultipleSelection(ec),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: ec.addCategorySlot,
                                      icon: const Icon(Icons.add),
                                      label:
                                          const Text('Ajouter une catégorie'),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Dropdown unique pour les autres types
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

                        const CustomSpace(heightMultiplier: 8),
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

  /// Construit les dropdowns multiples pour les "enterprise_categories"
  Widget _buildEnterpriseMultipleSelection(
      ProEstablishmentProfileScreenController ec) {
    return Column(
      children: [
        // Afficher les dropdowns en fonction du nombre de slots
        ...List.generate(ec.enterpriseCategorySlots.value, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Obx(() => CustomDropdownStreamBuilder<EnterpriseCategory>(
                  tag: 'enterprise_category_$index',
                  stream: ec.getEnterpriseCategoriesStream(),
                  initialItem: index < ec.selectedEnterpriseCategories.length
                      ? ec.selectedEnterpriseCategories[index]
                      : Rx<EnterpriseCategory?>(null),
                  labelText: 'Catégorie ${index + 1}',
                  maxWith: ec.categoryMaxWidth,
                  maxHeight: ec.categoryMaxHeight,
                  noInitialItem: true,
                  onChanged: (EnterpriseCategory? cat) {
                    if (index < ec.selectedEnterpriseCategories.length) {
                      ec.selectedEnterpriseCategories[index].value = cat;
                    }
                  },
                )),
          );
        }),
      ],
    );
  }
}
