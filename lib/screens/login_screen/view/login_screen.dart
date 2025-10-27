import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../widgets/reusable/reusable_widgets_getx.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_divider/view/custom_divider.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/login_screen_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(LoginScreenController(), tag: 'login_screen');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                      // Container glassmorphique avec effet pulsar
                      CustomCardAnimation(
                        index: 0,
                        child: _buildLoginCard(context, cc, isTablet),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Version badge (masqué quand le clavier est visible)
          if (!isKeyboardVisible)
            Positioned(
              bottom: 20,
              right: 20,
              child: CustomCardAnimation(
                index: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'v 2.0.1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(
      BuildContext context, LoginScreenController cc, bool isTablet) {
    return Container(
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
            color: CustomTheme.lightScheme().primary.withOpacity(0.15),
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
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),

                // Logo et titre intégrés
                CustomCardAnimation(
                  index: 1,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Logo en arrière-plan avec dégradé d'opacité
                          Positioned(
                            top: -30,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(1),
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(1),
                                  ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: const SizedBox(
                                width: 140,
                                child: CustomLogo(),
                              ),
                            ),
                          ),

                          // Contenu principal
                          Column(
                            children: [
                              const SizedBox(height: 20),

                              // Titre principal en noir
                              const Text(
                                'VENTE MOI',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.1,
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xffebe1ce),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CustomTheme.lightScheme().primary,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Le Don des Affaires',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: CustomTheme.lightScheme().primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 78),

                // Champ Email
                CustomCardAnimation(
                  index: 2,
                  child: ReusableTextFieldX(
                    tag: cc.emailTag,
                    controller: cc.emailController,
                    labelText: cc.emailLabel,
                    iconData: cc.emailIconData,
                    keyboardType: cc.emailInputType,
                    textInputAction: cc.emailInputAction,
                    validatorPattern: r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    errorText: cc.emailError,
                  ),
                ),
                const SizedBox(height: 24),

                // Champ Mot de passe
                CustomCardAnimation(
                  index: 3,
                  child: ReusableTextFieldX(
                    tag: cc.passwordTag,
                    controller: cc.passwordController,
                    labelText: cc.passwordLabel,
                    iconData: cc.passwordIconData,
                    isPassword: true,
                    keyboardType: cc.passwordInputType,
                    textInputAction: cc.passwordInputAction,
                    validatorPattern: r'^.{6,}$',
                    errorText: cc.passwordError,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      cc.login();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe oublié
                CustomCardAnimation(
                  key: const Key('forgot_password_row'),
                  index: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: cc.passwordScreenOnPressed,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        cc.forgotPasswordLabel,
                        style: TextStyle(
                          color: CustomTheme.lightScheme().primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton de connexion
                CustomCardAnimation(
                  key: const Key('login_screen_login_button'),
                  index: 5,
                  child: ReusableButtonX(
                    tag: cc.connectionTag,
                    text: cc.connectionLabel,
                    icon: cc.connectionIconData,
                    onPressed: cc.login,
                  ),
                ),
                const SizedBox(height: 8),

                // Divider
                CustomCardAnimation(
                  key: const Key('login_screen_divider'),
                  index: 6,
                  child: CustomDivider(
                    tag: cc.dividerTag,
                    text: cc.dividerLabel,
                    dividerColor: Colors.grey.withOpacity(0.3),
                    dividerTextColor: Colors.grey[600],
                    width: cc.dividerWidth,
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Google Sign In
                CustomCardAnimation(
                  key: const Key('login_screen_google_button'),
                  index: 7,
                  child: ReusableButtonX(
                    tag: 'google-signin-button',
                    onPressed: cc.signInWithGoogle,
                    outlined: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey[700]!,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF4285F4),
                                Color(0xFF34A853),
                                Color(0xFFFBBC05),
                                Color(0xFFEA4335),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continuer avec Google',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton d'inscription
                CustomCardAnimation(
                  key: const Key('login_screen_register_button'),
                  index: 8,
                  child: ReusableButtonX(
                    tag: cc.registerTag,
                    text: cc.registerLabel,
                    icon: cc.registerIconData,
                    onPressed: cc.registerScreenOnPressed,
                    outlined: true,
                    backgroundColor: Colors.white,
                    foregroundColor: CustomTheme.lightScheme().primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
