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

          // Version badge
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
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
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
                      'v 1.9.7',
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

                // Se souvenir de moi et Mot de passe oublié
                CustomCardAnimation(
                  key: const Key('remember_forgot_row'),
                  index: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isSmallScreen = constraints.maxWidth < 400;

                      if (isSmallScreen) {
                        // Sur petit écran, mettre en colonne
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox Se souvenir de moi
                            InkWell(
                              onTap: cc.toggleRememberMe,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(() => SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: cc.rememberMe.value,
                                          onChanged: (_) =>
                                              cc.toggleRememberMe(),
                                          activeColor:
                                              CustomTheme.lightScheme().primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Se souvenir de moi',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Mot de passe oublié
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: cc.passwordScreenOnPressed,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                          ],
                        );
                      } else {
                        // Sur grand écran, garder en ligne
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Checkbox Se souvenir de moi
                            Flexible(
                              child: InkWell(
                                onTap: cc.toggleRememberMe,
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Obx(() => SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: cc.rememberMe.value,
                                            onChanged: (_) =>
                                                cc.toggleRememberMe(),
                                            activeColor:
                                                CustomTheme.lightScheme()
                                                    .primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        )),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Se souvenir de moi',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Mot de passe oublié
                            TextButton(
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
                          ],
                        );
                      }
                    },
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

                // Bouton d'inscription
                CustomCardAnimation(
                  key: const Key('login_screen_register_button'),
                  index: 7,
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
