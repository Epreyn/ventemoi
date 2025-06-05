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
                            // Cercles pulsants autour du container
                            ...List.generate(3, (index) {
                              return PulsingBorder(
                                baseWidth: isTablet ? 500 : 400,
                                baseHeight: 650,
                                expandScale: 1.0 +
                                    (index * 0.15), // Expansion progressive
                                delay: index * 0.4,
                                opacity:
                                    (0.15 - (index * 0.04)).clamp(0.0, 1.0),
                              );
                            }),

                            // Container glassmorphique principal
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 500 : 400,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
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
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      'v1.3.3',
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

  Widget _buildLoginForm(LoginScreenController cc, BuildContext context) {
    return Form(
      child: Column(
        children: [
          // Logo et titre intégrés
          CustomCardAnimation(
            index: 1,
            child: Column(
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const CustomLogo(),
                ),
                const SizedBox(height: 20),

                // Titre principal
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      CustomTheme.lightScheme().primary,
                      CustomTheme.lightScheme().primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'VENTE MOI',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Sous-titre
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Le Don des Affaires',
                    style: TextStyle(
                      fontSize: 14,
                      color: CustomTheme.lightScheme().primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Champ Email
          CustomCardAnimation(
            index: 2,
            child: CustomTextFormField(
              tag: cc.emailTag,
              controller: cc.emailController,
              labelText: cc.emailLabel,
              iconData: cc.emailIconData,
              keyboardType: cc.emailInputType,
              textInputAction: cc.emailInputAction,
              validatorPattern:
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              errorText: cc.emailError,
            ),
          ),

          const SizedBox(height: 24),

          // Champ Mot de passe
          CustomCardAnimation(
            index: 3,
            child: CustomTextFormField(
              tag: cc.passwordTag,
              controller: cc.passwordController,
              labelText: cc.passwordLabel,
              iconData: cc.passwordIconData,
              isPassword: true,
              keyboardType: cc.passwordInputType,
              textInputAction: cc.passwordInputAction,
              validatorPattern: r'^.{6,}$',
              errorText: cc.passwordError,
            ),
          ),

          const SizedBox(height: 20),

          // Mot de passe oublié
          CustomCardAnimation(
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
            index: 7,
            child: CustomFABButton(
              tag: cc.registerTag,
              text: cc.registerLabel,
              iconData: cc.registerIconData,
              onPressed: cc.registerScreenOnPressed,
              backgroundColor: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour les bordures pulsantes autour du container
class PulsingBorder extends StatefulWidget {
  final double baseWidth;
  final double baseHeight;
  final double expandScale;
  final double delay;
  final double opacity;

  const PulsingBorder({
    super.key,
    required this.baseWidth,
    required this.baseHeight,
    required this.expandScale,
    required this.delay,
    required this.opacity,
  });

  @override
  State<PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<PulsingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleAnimation = Tween(
      begin: 1.0,
      end: widget.expandScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween(
      begin: widget.opacity,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.baseWidth,
            height: widget.baseHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CustomTheme.lightScheme()
                    .primary
                    .withOpacity(_opacityAnimation.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CustomTheme.lightScheme()
                      .primary
                      .withOpacity(_opacityAnimation.value * 0.3),
                  blurRadius: 50 * _scaleAnimation.value,
                  spreadRadius: 20 * _scaleAnimation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
