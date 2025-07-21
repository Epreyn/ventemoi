import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/custom_divider/view/custom_divider.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field_v2.dart';
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cercles pulsants autour du container - EFFET INFINI
                            ...List.generate(3, (index) {
                              return PulsingBorder(
                                baseWidth: isTablet ? 500 : 400,
                                baseHeight:
                                    580, // Hauteur réduite pour correspondre à la nouvelle carte
                                expandScale:
                                    1.15, // Toujours la même expansion finale
                                delay: index *
                                    1.0, // Espacement temporel entre les cercles
                                opacity: 0.1, // Opacité constante
                                strokeWidth: 1.0, // Épaisseur constante
                              );
                            }),

                            // Container glassmorphique principal - BLUR RÉDUIT
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 500 : 400,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(
                                      0.35,
                                    ), // Plus opaque
                                    Colors.white.withOpacity(0.25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    0.5,
                                  ), // Bordure plus visible
                                  width: 2,
                                ),
                                boxShadow: [
                                  // Ombre orange plus subtile
                                  BoxShadow(
                                    color: CustomTheme.lightScheme()
                                        .primary
                                        .withOpacity(
                                          0.15,
                                        ), // Réduit de 0.25 à 0.15
                                    blurRadius: 30, // Réduit de 40 à 30
                                    spreadRadius: 5, // Réduit de 10 à 5
                                  ),
                                  // Ombre noire plus subtile
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
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ), // Blur réduit de 15 à 8
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                        0.15,
                                      ), // Légèrement plus opaque
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: _buildLoginForm(cc, context),
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
                      'v 1.7.7',
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

  // Modification dans lib/screens/login_screen/view/login_screen.dart
  // Remplacez votre fonction _buildLoginForm par celle-ci :

  Widget _buildLoginForm(LoginScreenController cc, BuildContext context) {
    return Column(
      children: [
        // Logo et titre intégrés
        CustomCardAnimation(
          index: 1,
          child: Column(
            children: [
              // Stack pour superposer le logo et le texte
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Logo en arrière-plan avec opacité
                  Positioned(
                    top: -20,
                    child: Opacity(
                      opacity: 0.15,
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: const CustomLogo(),
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
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Colors.black87,
                        ),
                      ),

                      // Sous-titre
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous pour continuer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Champ Email
        CustomCardAnimation(
          index: 2,
          child: CustomTextFormFieldV2(
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
          child: CustomTextFormFieldV2(
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
              // Fermer le clavier et se connecter
              FocusScope.of(context).unfocus();
              cc.login();
            },
          ),
        ),

        const SizedBox(height: 20),

        // Mot de passe oublié
        CustomCardAnimation(
          key: Key('forgot_password_card'),
          index: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: cc.passwordScreenOnPressed,
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

        const SizedBox(height: 32),

        // Bouton de connexion
        CustomCardAnimation(
          key: Key('login_screen_login_button'),
          index: 5,
          child: CustomFABButton(
            tag: cc.connectionTag,
            text: cc.connectionLabel,
            iconData: cc.connectionIconData,
            onPressed: cc.login,
          ),
        ),

        const SizedBox(height: 24),

        // Divider
        CustomCardAnimation(
          key: Key('login_screen_divider'),
          index: 6,
          child: CustomDivider(
            tag: cc.dividerTag,
            text: cc.dividerLabel,
            dividerColor: Colors.grey.withOpacity(0.3),
            dividerTextColor: Colors.grey[600],
            width: cc.dividerWidth,
          ),
        ),

        const SizedBox(height: 24),

        // Bouton d'inscription
        CustomCardAnimation(
          key: Key('login_screen_register_button'),
          index: 7,
          child: CustomFABButton(
            tag: cc.registerTag,
            text: cc.registerLabel,
            iconData: cc.registerIconData,
            onPressed: cc.registerScreenOnPressed,
            backgroundColor: Colors.white,
            foregroundColor: CustomTheme.lightScheme().primary,
          ),
        ),
      ],
    );
  }
}

// Widget pour les bordures pulsantes autour du container - AMÉLIORÉ
class PulsingBorder extends StatefulWidget {
  final double baseWidth;
  final double baseHeight;
  final double expandScale;
  final double delay;
  final double opacity;
  final double strokeWidth;

  const PulsingBorder({
    super.key,
    required this.baseWidth,
    required this.baseHeight,
    required this.expandScale,
    required this.delay,
    required this.opacity,
    this.strokeWidth = 2.0,
  });

  @override
  State<PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<PulsingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Animation qui va de 0 à 1
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // Démarrer après le délai spécifié
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;

        // Calculer le scale en fonction de la progression
        final scale = 0.98 + (widget.expandScale - 0.98) * progress;

        // Calculer l'opacité pour créer un effet de fondu
        double opacity;
        if (progress < 0.1) {
          // Apparition progressive (0% à 10%)
          opacity = widget.opacity * (progress / 0.1);
        } else if (progress > 0.7) {
          // Disparition progressive (70% à 100%)
          opacity = widget.opacity * ((1.0 - progress) / 0.3);
        } else {
          // Pleine opacité (10% à 70%)
          opacity = widget.opacity;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.baseWidth,
            height: widget.baseHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CustomTheme.lightScheme().primary.withOpacity(opacity),
                width: widget.strokeWidth,
              ),
              boxShadow: [
                // Ombre principale
                BoxShadow(
                  color: CustomTheme.lightScheme().primary.withOpacity(
                        opacity * 0.5,
                      ),
                  blurRadius: 30 * progress,
                  spreadRadius: 10 * progress,
                ),
                // Ombre secondaire plus diffuse
                BoxShadow(
                  color: CustomTheme.lightScheme().primary.withOpacity(
                        opacity * 0.3,
                      ),
                  blurRadius: 60 * progress,
                  spreadRadius: 20 * progress,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
