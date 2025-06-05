import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:ventemoi/core/classes/unique_controllers.dart';

import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/login_screen_controller.dart';
import '../models/particles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(LoginScreenController(), tag: 'login_screen');
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenLayout(
      noAppBar: true,
      noFAB: true,
      body: Stack(
        children: [
          // Background animé avec gradient dynamique
          Obx(() => AnimatedContainer(
                duration: const Duration(seconds: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(cc.backgroundAngle.value),
                      math.sin(cc.backgroundAngle.value),
                    ),
                    end: Alignment(
                      -math.cos(cc.backgroundAngle.value),
                      -math.sin(cc.backgroundAngle.value),
                    ),
                    colors: [
                      Colors.white,
                      CustomTheme.lightScheme().primary.withOpacity(0.1),
                      CustomTheme.lightScheme().primary.withOpacity(0.05),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              )),

          // Particules flottantes
          // Obx(() {
          //   cc.particleUpdate.value; // Force rebuild
          //   return CustomPaint(
          //     painter: ParticlePainter(
          //       particles: cc.particles,
          //       color: CustomTheme.lightScheme().primary,
          //     ),
          //     size: Size(screenWidth, screenHeight),
          //   );
          // }),

          // Formes géométriques animées
          _buildAnimatedShapes(cc),

          // Contenu principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 30,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : 400,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo et titre animés
                        _buildAnimatedLogo(cc),
                        const SizedBox(height: 60),

                        // Formulaire animé
                        Obx(() => AnimatedOpacity(
                              opacity: cc.formOpacity.value,
                              duration: const Duration(milliseconds: 800),
                              child: AnimatedSlide(
                                offset: Offset(0, cc.formSlideOffset.value),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                child: _buildLoginForm(cc),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Effet de lumière animé
          _buildLightEffect(cc, screenWidth, screenHeight),

          // Version en bas à droite
          const Positioned(
            bottom: 16,
            right: 16,
            child: Text(
              '1.3.3',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedShapes(LoginScreenController cc) {
    return Obx(() => Stack(
          children: [
            // Cercle animé en haut à droite
            AnimatedPositioned(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              top: -100 + 20 * math.sin(cc.shapeAnimation.value),
              right: -100 + 20 * math.cos(cc.shapeAnimation.value),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.2),
                      CustomTheme.lightScheme().primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Forme organique animée
            AnimatedPositioned(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              bottom: -150,
              left: -150,
              child: Transform.rotate(
                angle: cc.shapeAnimation.value * 0.5,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(150),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Hexagone animé
            Positioned(
              top: Get.height * 0.3,
              right: -50,
              child: Transform.rotate(
                angle: -cc.shapeAnimation.value,
                child: ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomTheme.lightScheme().primary.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildLightEffect(
      LoginScreenController cc, double screenWidth, double screenHeight) {
    return Obx(() => AnimatedPositioned(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          top: screenHeight * 0.2,
          left: screenWidth * 0.5 + 100 * math.cos(cc.lightPosition.value * 2),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildAnimatedLogo(LoginScreenController cc) {
    return Obx(() => Transform.scale(
          scale: cc.logoScale.value,
          child: Transform.rotate(
            angle: cc.logoRotation.value,
            child: Column(
              children: [
                // Logo avec effet de pulsation
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  width: 120 * cc.logoPulse.value,
                  height: 120 * cc.logoPulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(-10, -10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CustomLogo(),
                  ),
                ),
                const SizedBox(height: 30),

                // Titre avec animation de fade
                AnimatedOpacity(
                  opacity: cc.formOpacity.value,
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            CustomTheme.lightScheme().primary,
                            Colors.orange,
                            CustomTheme.lightScheme().primary,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          'VENTE MOI',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.1),
                              Colors.orange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.3),
                            width: 1,
                          ),
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
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildLoginForm(LoginScreenController cc) {
    return Column(
      children: [
        // Champ Email avec effet hover
        _buildAnimatedTextField(
          controller: cc.emailController,
          label: cc.emailLabel,
          icon: Icons.email_outlined,
          keyboardType: cc.emailInputType,
          textInputAction: cc.emailInputAction,
          onFieldSubmitted: (_) => cc.login(),
          delay: 100,
          isPasswordField: false,
          cc: cc,
        ),
        const SizedBox(height: 20),

        // Champ Mot de passe
        _buildAnimatedTextField(
          controller: cc.passwordController,
          label: cc.passwordLabel,
          icon: Icons.lock_outline,
          isPasswordField: true,
          keyboardType: cc.passwordInputType,
          textInputAction: cc.passwordInputAction,
          onFieldSubmitted: (_) => cc.login(),
          delay: 200,
          cc: cc,
        ),
        const SizedBox(height: 16),

        // Mot de passe oublié
        CustomCardAnimation(
          index: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: cc.passwordScreenOnPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                cc.forgotPasswordLabel,
                style: TextStyle(
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Bouton de connexion avec effet 3D
        CustomCardAnimation(
          index: 4,
          child: _buildAnimatedButton(
            text: cc.connectionLabel,
            onPressed: cc.login,
            isPrimary: true,
            icon: Icons.login_rounded,
          ),
        ),
        const SizedBox(height: 30),

        // Divider animé
        CustomCardAnimation(
          index: 5,
          child: _buildAnimatedDivider(),
        ),
        const SizedBox(height: 30),

        // Bouton d'inscription
        CustomCardAnimation(
          index: 6,
          child: _buildAnimatedButton(
            text: cc.registerLabel,
            onPressed: cc.registerScreenOnPressed,
            isPrimary: false,
            icon: Icons.person_add_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required LoginScreenController cc,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool isPasswordField = false,
    Function(String)? onFieldSubmitted,
    int delay = 0,
  }) {
    return CustomCardAnimation(
      index: delay ~/ 100,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Effet de gradient animé
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      CustomTheme.lightScheme().primary.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // Champ de texte
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: isPasswordField && !cc.isPasswordVisible.value,
              onFieldSubmitted: onFieldSubmitted,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: CustomTheme.lightScheme().primary,
                ),
                suffixIcon: isPasswordField
                    ? Obx(() => IconButton(
                          icon: Icon(
                            cc.isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: cc.togglePasswordVisibility,
                        ))
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: CustomTheme.lightScheme().primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  CustomTheme.lightScheme().primary,
                  CustomTheme.lightScheme().primary.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.grey[900],
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                (isPrimary ? CustomTheme.lightScheme().primary : Colors.black)
                    .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Clipper pour forme hexagonale
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
