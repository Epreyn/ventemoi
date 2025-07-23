import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user_type.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import '../../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../../features/custom_profile_image_picker/view/custom_profile_image_picker.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/register_screen_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(RegisterScreenController(), tag: 'register-screen');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenLayout(
      noAppBar: true,
      noFAB: true,
      body: Stack(
        children: [
          // Bouton retour
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CustomCardAnimation(
              index: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: CustomTheme.lightScheme().primary,
                  ),
                  onPressed: () => Get.offNamed(Routes.login),
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isTablet ? 60 : 24,
                    right: isTablet ? 60 : 24,
                    top: 80,
                    bottom: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Container glassmorphique
                      CustomCardAnimation(
                        index: 1,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Container glassmorphique
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isTablet ? 500 : 400,
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        child: _buildRegisterForm(cc, context),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(RegisterScreenController cc, BuildContext context) {
    return Form(
      key: cc.formKey,
      child: Column(
        children: [
          // Titre
          CustomCardAnimation(
            index: 2,
            child: Column(
              children: [
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez la communauté VenteMoi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Message si l'utilisateur a des points en attente
          Obx(() => cc.hasPendingPoints.value
              ? CustomCardAnimation(
                  index: 2,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.1),
                          Colors.green.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Des points vous attendent !',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cc.pendingPointsAmount.value} points seront crédités automatiquement',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          const SizedBox(height: 30),

          // Photo de profil
          CustomCardAnimation(
            index: 3,
            child: const CustomProfileImagePicker(
              tag: 'profile-image-picker',
              haveToReset: true,
            ),
          ),

          const SizedBox(height: 8),

          CustomCardAnimation(
            index: 4,
            child: Text(
              'Photo de profil (optionnel)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Type d'utilisateur
          CustomCardAnimation(
            index: 5,
            child: CustomDropdownStreamBuilder<UserType>(
              tag: cc.userTypeTag,
              stream: cc.getUserTypesStreamExceptAdmin(),
              initialItem: cc.currentUserType,
              labelText: cc.userTypeLabel,
              maxWith: cc.userTypeMaxWidth,
              maxHeight: cc.userTypeMaxHeight,
              iconData: Icons.badge_outlined,
              onChanged: (UserType? value) {
                cc.currentUserType.value = value;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Description du type
          Obx(() => cc.currentUserType.value != null
              ? CustomCardAnimation(
                  index: 6,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      cc.currentUserType.value?.description ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          const SizedBox(height: 24),

          // Nom
          CustomCardAnimation(
            index: 7,
            child: CustomTextFormField(
              tag: cc.nameTag,
              controller: cc.nameController,
              iconData: cc.nameIconData,
              labelText: cc.nameLabel,
              errorText: cc.nameError,
              textInputAction: cc.nameTextInputAction,
              keyboardType: cc.nameInputType,
              validatorPattern: cc.nameValidatorPattern,
            ),
          ),

          const SizedBox(height: 20),

          // Email
          CustomCardAnimation(
            index: 8,
            child: CustomTextFormField(
              tag: cc.emailTag,
              controller: cc.emailController,
              iconData: cc.emailIconData,
              labelText: cc.emailLabel,
              errorText: cc.emailError,
              textInputAction: cc.emailTextInputAction,
              keyboardType: cc.emailInputType,
              validatorPattern: cc.emailValidatorPattern,
            ),
          ),

          const SizedBox(height: 20),

          // Mot de passe
          CustomCardAnimation(
            index: 9,
            child: CustomTextFormField(
              tag: cc.passwordTag,
              controller: cc.passwordController,
              iconData: cc.passwordIconData,
              labelText: cc.passwordLabel,
              errorText: cc.passwordError,
              isPassword: true,
              textInputAction: cc.passwordTextInputAction,
              keyboardType: cc.passwordInputType,
              validatorPattern: cc.passwordValidatorPattern,
            ),
          ),

          const SizedBox(height: 20),

          // Confirmer mot de passe
          CustomCardAnimation(
            index: 10,
            child: CustomTextFormField(
              tag: cc.confirmPasswordTag,
              controller: cc.confirmPasswordController,
              iconData: cc.confirmPasswordIconData,
              labelText: cc.confirmPasswordLabel,
              errorText: cc.confirmPasswordError,
              isPassword: true,
              textInputAction: cc.confirmPasswordTextInputAction,
              keyboardType: cc.confirmPasswordInputType,
              validatorPattern: cc.confirmPasswordValidatorPattern,
            ),
          ),

          // Erreur si mots de passe ne correspondent pas
          Obx(() => !cc.isConfirmedPassword.value
              ? CustomCardAnimation(
                  index: 11,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Les mots de passe ne correspondent pas',
                      style: TextStyle(
                        color: CustomTheme.lightScheme().error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          const SizedBox(height: 24),

          // Section Code de parrainage
          _buildReferralCodeSection(cc),

          const SizedBox(height: 24),

          // Section Parrainage Association (pour tous les types d'utilisateurs)
          _buildAssociationSection(cc),

          const SizedBox(height: 32),

          // Bouton d'inscription
          CustomCardAnimation(
            index: 16,
            child: CustomFABButton(
              tag: 'register-button',
              iconData: Icons.app_registration_rounded,
              text: 'S\'INSCRIRE',
              onPressed: () {
                cc.isPressedRegisterButton.value = true;
                if (cc.isPressedRegisterButton.value &&
                    cc.checkPasswordConfirmation()) {
                  cc.isConfirmedPassword.value = true;
                  cc.register();
                } else {
                  cc.isConfirmedPassword.value = false;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(RegisterScreenController cc) {
    return Column(
      children: [
        // Champ de code de parrainage
        CustomCardAnimation(
          index: 12,
          child: CustomTextFormField(
            tag: cc.referralCodeTag,
            controller: cc.referralCodeController,
            labelText: cc.referralCodeLabel,
            iconData: Icons.card_giftcard_rounded,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              if (value.length == 6) {
                cc.validateReferralCode(value);
              } else {
                cc.hasValidReferralCode.value = false;
                cc.sponsorInfo.value = null;
              }
            },
            suffixIcon: Obx(() => cc.hasValidReferralCode.value
                ? Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : const SizedBox.shrink()),
          ),
        ),

        // Message de validation du code
        Obx(() => cc.hasValidReferralCode.value && cc.sponsorInfo.value != null
            ? CustomCardAnimation(
                index: 13,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.celebration_rounded,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parrainage de ${cc.sponsorInfo.value!['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildAssociationSection(RegisterScreenController cc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        CustomCardAnimation(
          index: 14,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CustomTheme.lightScheme().primary.withOpacity(0.1),
                  CustomTheme.lightScheme().primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: CustomTheme.lightScheme().primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Affilier une association',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soutenez une association gratuitement et sans frais',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Recherche d'association
        CustomCardAnimation(
          index: 15,
          child: Column(
            children: [
              // Conteneur pour centrer le CustomTextFormField
              SizedBox(
                width: double.infinity,
                child: CustomTextFormField(
                  tag: cc.associationSearchTag,
                  controller: cc.associationSearchController,
                  labelText: cc.associationSearchLabel,
                  iconData: Icons.search,
                  onChanged: (value) => cc.searchAssociations(value),
                ),
              ),

              // Indicateur de recherche
              Obx(() => cc.isSearching.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(
                        color: CustomTheme.lightScheme().primary,
                      ),
                    )
                  : const SizedBox.shrink()),

              // Résultats de recherche
              Obx(() => cc.searchResults.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: cc.searchResults.map((association) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  association['image_url'].isNotEmpty
                                      ? NetworkImage(association['image_url'])
                                      : null,
                              child: association['image_url'].isEmpty
                                  ? Icon(
                                      Icons.group,
                                      color: CustomTheme.lightScheme().primary,
                                    )
                                  : null,
                            ),
                            title: Text(association['name']),
                            subtitle: Text(
                              association['email'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => cc.selectAssociation(association),
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink()),

              // Association sélectionnée
              Obx(() => cc.selectedAssociation.value != null
                  ? Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous deviendrez filleul de ${cc.selectedAssociation.value!['name']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              cc.selectedAssociation.value = null;
                              cc.associationSearchController.clear();
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),

              // Option d'invitation
              Obx(() => cc.showInviteOption.value &&
                      cc.selectedAssociation.value == null
                  ? Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: CustomTheme.lightScheme().primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Association non trouvée ?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Invitez-la à rejoindre VenteMoi !',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CustomTextFormField(
                              tag: cc.invitationEmailTag,
                              controller: cc.invitationEmailController,
                              labelText: cc.invitationEmailLabel,
                              iconData: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validatorPattern:
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              errorText: 'Email invalide',
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );
  }
}
