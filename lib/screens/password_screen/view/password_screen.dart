import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/password_screen_controller.dart';

class PasswordScreen extends StatelessWidget {
  const PasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(PasswordScreenController(), tag: 'password-screen');
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
          // Bouton retour en haut à gauche
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Container glassmorphique principal
                      CustomCardAnimation(
                        index: 1,
                        child: Stack(
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
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: _buildResetForm(cc, context),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildResetForm(PasswordScreenController cc, BuildContext context) {
    return Column(
      children: [
        // Logo et titre
        CustomCardAnimation(
          index: 2,
          child: Column(
            children: [
              // Stack pour le logo et le texte
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Logo en arrière-plan
                  Positioned(
                    top: -20,
                    child: Opacity(
                      opacity: 0.15,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: const CustomLogo(),
                      ),
                    ),
                  ),

                  // Contenu principal
                  Column(
                    children: [
                      const SizedBox(height: 20),

                      // Titre
                      const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Texte d'explication
        CustomCardAnimation(
          index: 3,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 2,
            ),
            child: Text(
              'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Champ Email
        CustomCardAnimation(
          index: 4,
          child: CustomTextFormField(
            tag: cc.emailTag,
            controller: cc.emailController,
            labelText: cc.emailLabel,
            iconData: cc.emailIconData,
            keyboardType: cc.emailInputType,
            validatorPattern:
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            errorText: cc.emailError,
          ),
        ),

        const SizedBox(height: 40),

        // Bouton réinitialiser
        CustomCardAnimation(
          index: 5,
          child: CustomFABButton(
            tag: cc.resetPasswordTag,
            text: cc.resetPasswordLabel,
            iconData: cc.resetPasswordIconData,
            onPressed: cc.resetPassword,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
