import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/models/stripe_service.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/establishment_category.dart';
import '../../../core/theme/custom_theme.dart';

import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import '../../../features/custom_places_autocompletion/view/custom_places_autocompletion.dart'
    show CustomPlacesAutocomplete;
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../widgets/enterprise_category_cascade_selector.dart';
import '../controllers/pro_establishment_profile_screen_controller.dart';
import 'package:ventemoi/firebase_options.dart';

import '../widgets/cgu_payment_dialog.dart';

class ProEstablishmentProfileScreen extends StatelessWidget {
  const ProEstablishmentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ec = Get.put(ProEstablishmentProfileScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      fabOnPressed: ec.saveEstablishmentProfile,
      fabIcon: const Icon(Icons.save_rounded),
      fabText: const Text('Enregistrer'),
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

            final slots = data['enterprise_category_slots'] ?? 2;
            ec.enterpriseCategorySlots.value = slots;

            ec.initializeEnterpriseCategoriesFromStream(data);
          }

          return Center(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 700 : 500,
                  ),
                  child: Form(
                    key: ec.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Logo Améliorée
                        CustomCardAnimation(
                          index: 0,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.store_rounded,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Logo de l\'établissement',
                                            style: TextStyle(
                                              fontSize: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  2,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.aspect_ratio_rounded,
                                                  size: 14,
                                                  color:
                                                      CustomTheme.lightScheme()
                                                          .primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Taille recommandée : 400 x 400 px',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: CustomTheme
                                                            .lightScheme()
                                                        .primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),

                                // Zone de prévisualisation du logo sans bordure
                                Obx(() => ec.buildLogoWidget()),

                                const CustomSpace(heightMultiplier: 2),

                                // Informations sur les formats
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 16,
                                            color: Colors.amber.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Conseils pour un logo optimal',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                          'Format carré recommandé (1:1)'),
                                      _buildInfoRow(
                                          'Formats acceptés : JPG, PNG, WebP'),
                                      _buildInfoRow('Taille max : 5 MB'),
                                      _buildInfoRow(
                                          'Fond transparent pour PNG'),
                                    ],
                                  ),
                                ),

                                const CustomSpace(heightMultiplier: 2),

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CustomTheme.lightScheme().primary,
                                        CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: ec.pickLogo,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              3,
                                          vertical: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              1.5,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.photo_camera_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'CHANGER LE LOGO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Section Bannière Améliorée
                        CustomCardAnimation(
                          index: 1,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.image_rounded,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bannière',
                                            style: TextStyle(
                                              fontSize: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  2,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.aspect_ratio_rounded,
                                                  size: 14,
                                                  color:
                                                      CustomTheme.lightScheme()
                                                          .primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Taille recommandée : 1200 x 400 px (3:1)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: CustomTheme
                                                            .lightScheme()
                                                        .primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),

                                // Zone de prévisualisation de la bannière sans bordure
                                Obx(() => ec.buildBannerWidget()),

                                const CustomSpace(heightMultiplier: 2),

                                // Informations sur les formats pour bannière
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 16,
                                            color: Colors.amber.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Conseils pour une bannière attrayante',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                          'Format panoramique (3:1 ou 16:9)'),
                                      _buildInfoRow(
                                          'Résolution minimale : 1200 x 400 px'),
                                      _buildInfoRow(
                                          'Évitez le texte important sur les bords'),
                                      _buildInfoRow(
                                          'Image de haute qualité recommandée'),
                                      _buildInfoRow('Taille max : 10 MB'),
                                    ],
                                  ),
                                ),

                                const CustomSpace(heightMultiplier: 2),

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CustomTheme.lightScheme().primary,
                                        CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: ec.pickBanner,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              3,
                                          vertical: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              1.5,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.photo_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'CHANGER LA BANNIÈRE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Section Informations générales
                        CustomCardAnimation(
                          index: 2,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.business_rounded,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Informations générales',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),
                                CustomTextFormField(
                                  tag: ec.nameTag,
                                  labelText: ec.nameLabel,
                                  controller: ec.nameCtrl,
                                  iconData: Icons.store_mall_directory_rounded,
                                  maxWidth: double.infinity,
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomTextFormField(
                                  tag: ec.descriptionTag,
                                  labelText: ec.descriptionLabel,
                                  minLines: ec.descriptionMinLines,
                                  maxLines: ec.descriptionMaxLines,
                                  maxCharacters: ec.descriptionMaxCharacters,
                                  controller: ec.descriptionCtrl,
                                  iconData: Icons.description_rounded,
                                  maxWidth: double.infinity,
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomPlacesAutocomplete(
                                  controller: ec.addressCtrl,
                                  apiKey: DefaultFirebaseOptions.googleKeyAPI,
                                  hintText: "Adresse de l'établissement...",
                                  labelText: ec.addressLabel,
                                  iconData: Icons.location_on_rounded,
                                  countries: ['fr'],
                                  maxWidth: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Section Contact
                        CustomCardAnimation(
                          index: 3,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.contact_phone_rounded,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Contact',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),
                                CustomTextFormField(
                                  tag: ec.emailTag,
                                  labelText: ec.emailLabel,
                                  controller: ec.emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  iconData: Icons.email_rounded,
                                  maxWidth: double.infinity,
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomTextFormField(
                                  tag: ec.phoneTag,
                                  labelText: ec.phoneLabel,
                                  controller: ec.phoneCtrl,
                                  iconData: Icons.phone_rounded,
                                  maxWidth: double.infinity,
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomTextFormField(
                                  tag: ec.videoTag,
                                  labelText: ec.videoLabel,
                                  controller: ec.videoCtrl,
                                  keyboardType: TextInputType.url,
                                  iconData: Icons.videocam_rounded,
                                  maxWidth: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Section Catégories
                        CustomCardAnimation(
                          index: 4,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final userType = ec.currentUserType.value;
                                  if (userType != null &&
                                      userType.name == 'Entreprise') {
                                    // Pour les entreprises
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: CustomTheme.lightScheme()
                                                    .primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.category_rounded,
                                                color: CustomTheme.lightScheme()
                                                    .primary,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Catégories',
                                              style: TextStyle(
                                                fontSize: UniquesControllers()
                                                        .data
                                                        .baseSpace *
                                                    2,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: UniquesControllers()
                                                        .data
                                                        .baseSpace *
                                                    1.5,
                                                vertical: UniquesControllers()
                                                        .data
                                                        .baseSpace *
                                                    0.8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: CustomTheme.lightScheme()
                                                    .primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                border: Border.all(
                                                  color:
                                                      CustomTheme.lightScheme()
                                                          .primary
                                                          .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                '${ec.enterpriseCategorySlots.value} slots',
                                                style: TextStyle(
                                                  fontSize: UniquesControllers()
                                                          .data
                                                          .baseSpace *
                                                      1.4,
                                                  color:
                                                      CustomTheme.lightScheme()
                                                          .primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const CustomSpace(heightMultiplier: 2),
                                        _buildEnterpriseCategoriesSection(
                                            ec, data!),
                                        const CustomSpace(heightMultiplier: 2),
                                      ],
                                    );
                                  } else {
                                    // Pour les autres types
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: CustomTheme.lightScheme()
                                                    .primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.category_rounded,
                                                color: CustomTheme.lightScheme()
                                                    .primary,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Catégorie',
                                              style: TextStyle(
                                                fontSize: UniquesControllers()
                                                        .data
                                                        .baseSpace *
                                                    2,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const CustomSpace(heightMultiplier: 3),
                                        CustomDropdownStreamBuilder<
                                            EstablishmentCategory>(
                                          tag: ec.categoryTag,
                                          stream: ec.getCategoriesStream(),
                                          initialItem: ec.currentCategory,
                                          labelText: ec.categoryLabel,
                                          maxWidth: double.infinity,
                                          maxHeight: ec.categoryMaxHeight,
                                          onChanged:
                                              (EstablishmentCategory? cat) {
                                            ec.currentCategory.value = cat;
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        ),

                        // Statut de visibilité
                        const CustomSpace(heightMultiplier: 3),
                        Obx(() {
                          final isVisible = ec.hasAcceptedContract.value &&
                              ec.hasActiveSubscription.value;

                          // Vérifier si l'utilisateur a besoin de repayer
                          bool requiresPayment = false;
                          if (data != null) {
                            requiresPayment = data['requires_payment'] ?? false;
                          }

                          // Si requires_payment est true, afficher un message spécial
                          if (requiresPayment) {
                            return CustomCardAnimation(
                              index: 5,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(
                                  UniquesControllers().data.baseSpace * 2.5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.red.shade50,
                                      Colors.red.shade100.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.red.shade200.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.warning_rounded,
                                            color: Colors.red.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Abonnement requis',
                                                style: TextStyle(
                                                  fontSize: UniquesControllers()
                                                          .data
                                                          .baseSpace *
                                                      1.8,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Votre accès gratuit a été retiré. Souscrivez un abonnement pour être visible.',
                                                style: TextStyle(
                                                  fontSize: UniquesControllers()
                                                          .data
                                                          .baseSpace *
                                                      1.4,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Forcer l'ouverture du dialog de paiement
                                        Get.dialog(
                                          CGUPaymentDialog(
                                            userType: ec.currentUserType.value
                                                    ?.name ??
                                                'Boutique',
                                          ),
                                          barrierDismissible: false,
                                        );
                                      },
                                      icon: Icon(Icons.credit_card,
                                          color: Colors.white),
                                      label: Text(
                                        'SOUSCRIRE UN ABONNEMENT',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return CustomCardAnimation(
                            index: 5,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                UniquesControllers().data.baseSpace * 2.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isVisible
                                      ? [
                                          Colors.green.shade50,
                                          Colors.green.shade100
                                              .withOpacity(0.8),
                                        ]
                                      : [
                                          Colors.orange.shade50,
                                          Colors.orange.shade100
                                              .withOpacity(0.8),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isVisible
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isVisible
                                            ? Colors.green.shade200
                                            : Colors.orange.shade200)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isVisible
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: isVisible
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isVisible
                                              ? 'Établissement visible'
                                              : 'Établissement non visible',
                                          style: TextStyle(
                                            fontSize: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                1.8,
                                            fontWeight: FontWeight.w700,
                                            color: isVisible
                                                ? Colors.green.shade800
                                                : Colors.orange.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isVisible
                                              ? 'Votre établissement est visible dans le shop'
                                              : 'Complétez les CGU et le paiement pour être visible',
                                          style: TextStyle(
                                            fontSize: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                1.4,
                                            color: isVisible
                                                ? Colors.green.shade600
                                                : Colors.orange.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: CustomTheme.lightScheme().primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseMultipleSelection(
      ProEstablishmentProfileScreenController ec) {
    return Column(
      children: [
        ...List.generate(ec.enterpriseCategorySlots.value, (index) {
          final isExtraSlot = index >= 2;
          return Padding(
            padding: EdgeInsets.only(
              bottom: UniquesControllers().data.baseSpace * 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      Obx(() => CustomDropdownStreamBuilder<EnterpriseCategory>(
                            tag: 'enterprise_category_$index',
                            stream: ec.getEnterpriseCategoriesStream(),
                            initialItem:
                                index < ec.selectedEnterpriseCategories.length
                                    ? ec.selectedEnterpriseCategories[index]
                                    : Rx<EnterpriseCategory?>(null),
                            labelText: 'Catégorie ${index + 1}',
                            maxWidth: double.infinity,
                            maxHeight: ec.categoryMaxHeight,
                            noInitialItem: true,
                            onChanged: (EnterpriseCategory? cat) {
                              if (index <
                                  ec.selectedEnterpriseCategories.length) {
                                ec.selectedEnterpriseCategories[index].value =
                                    cat;
                              }
                            },
                          )),
                ),
                if (isExtraSlot) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.all(
                      UniquesControllers().data.baseSpace * 0.8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.amber.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: UniquesControllers().data.baseSpace * 1.8,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEnterpriseCategoriesSection(
    ProEstablishmentProfileScreenController ec,
    Map<String, dynamic> establishmentData,
  ) {
    // Initialiser les catégories depuis les données du stream
    ec.initializeEnterpriseCategoriesFromStream(establishmentData);

    return StreamBuilder<List<EnterpriseCategory>>(
      stream: ec.getEnterpriseCategoriesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;

        return Obx(() {
          final slots = ec.enterpriseCategorySlots.value;
          final hasModifications = ec.hasModifications.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnterpriseCategoryCascadingSelector(
                categories: categories,
                selectedIds: ec.selectedEnterpriseCategoryIds,
                onToggle: ec.toggleEnterpriseCategory,
                onRemove: ec.removeEnterpriseCategory,
                maxSelections: slots,
              ),

              // Boutons d'action si modifications
              if (hasModifications)
                ElevatedButton(
                  onPressed: ec.resetEnterpriseCategoriesChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Annuler'),
                ),

              // Option pour acheter des slots supplémentaires
              if (slots < 5) // Limite max
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Card(
                    elevation: 0,
                    color: Colors.amber[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber[200]!),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.add_circle_outline,
                          color: Colors.amber[700]),
                      title: Text(
                        'Besoin de plus de catégories ?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          Text('Achetez des slots supplémentaires (50€/slot)'),
                      trailing: TextButton(
                        onPressed: ec.showPurchaseSlotDialog,
                        child: Text('Acheter'),
                      ),
                    ),
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}
