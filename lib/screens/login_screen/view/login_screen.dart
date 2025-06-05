import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/modern_button/view/modern_button.dart';
import '../../../features/modern_text_field/view/modern_text_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/login_screen_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(LoginScreenController(), tag: 'login_screen');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
          // Contenu principal avec effet glassmorphism
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
                      // Logo animé
                      _buildAnimatedLogo(),
                      const SizedBox(height: 50),

                      // Container glassmorphique pour le formulaire
                      CustomCardAnimation(
                        index: 2,
                        child: Container(
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
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: _buildLoginForm(cc),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Version flottante
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildVersionBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercles concentriques avec effet pulse
              ...List.generate(3, (index) {
                return PulsingCircle(
                  size: 100 + (index * 30),
                  delay: index * 0.3,
                  opacity: 0.3 - (index * 0.08),
                );
              }),

              // Logo principal statique
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: CustomLogo(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(LoginScreenController cc) {
    return Column(
      children: [
        // Titre avec animation de typing
        const TypingAnimatedText(
          text: 'VENTE MOI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),

        // Sous-titre avec fade in
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          builder: (context, opacity, _) {
            return Opacity(
              opacity: opacity,
              child: Text(
                'Le Don des Affaires',
                style: TextStyle(
                  fontSize: 16,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        // Champ Email avec icône animée
        _buildAnimatedField(
          index: 3,
          child: GlowingTextField(
            tag: cc.emailTag,
            controller: cc.emailController,
            labelText: cc.emailLabel,
            hintText: 'exemple@email.com',
            prefixIcon: Icons.email_rounded,
            keyboardType: cc.emailInputType,
            textInputAction: cc.emailInputAction,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'L\'email est requis';
              }
              final emailRegex =
                  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value)) {
                return cc.emailError;
              }
              return null;
            },
            onFieldSubmitted: (_) => cc.login(),
          ),
        ),

        const SizedBox(height: 24),

        // Champ Mot de passe avec indicateur de force
        _buildAnimatedField(
          index: 4,
          child: GlowingTextField(
            tag: cc.passwordTag,
            controller: cc.passwordController,
            labelText: cc.passwordLabel,
            hintText: '••• ••• •••',
            prefixIcon: Icons.lock_rounded,
            isPassword: true,
            keyboardType: cc.passwordInputType,
            textInputAction: cc.passwordInputAction,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le mot de passe est requis';
              }
              if (value.length < 6) {
                return 'Minimum 6 caractères';
              }
              return null;
            },
            onFieldSubmitted: (_) => cc.login(),
          ),
        ),

        const SizedBox(height: 20),

        // Options avec animation
        _buildAnimatedField(
          index: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember me avec switch custom
              Row(
                children: [
                  AnimatedCheckbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Se souvenir',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Mot de passe oublié
              TextButton(
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
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Bouton de connexion 3D
        _buildAnimatedField(
          index: 6,
          child: SizedBox(
            width: double.infinity,
            child: ThreeDButton(
              text: cc.connectionLabel,
              onPressed: cc.login,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Divider animé
        _buildAnimatedField(
          index: 7,
          child: const AnimatedDivider(),
        ),

        const SizedBox(height: 24),

        // Bouton d'inscription avec effet néon
        _buildAnimatedField(
          index: 8,
          child: SizedBox(
            width: double.infinity,
            child: NeonButton(
              text: cc.registerLabel,
              onPressed: cc.registerScreenOnPressed,
              icon: Icons.person_add_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildVersionBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 1),
      curve: Curves.elasticOut,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CustomTheme.lightScheme().primary.withOpacity(0.8),
                  CustomTheme.lightScheme().primary.withOpacity(0.6),
                ],
              ),
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
        );
      },
    );
  }
}

// Cercle avec effet de pulsation
class PulsingCircle extends StatefulWidget {
  final double size;
  final double delay;
  final double opacity;

  const PulsingCircle({
    super.key,
    required this.size,
    required this.delay,
    required this.opacity,
  });

  @override
  State<PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CustomTheme.lightScheme()
                    .primary
                    .withOpacity(widget.opacity.clamp(0.0, 1.0)),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

// TextField avec effet de lueur
class GlowingTextField extends StatelessWidget {
  final String tag;
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Function(String)? onFieldSubmitted;

  const GlowingTextField({
    super.key,
    required this.tag,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Animation globale du container
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    CustomTheme.lightScheme().primary.withOpacity(0.08 * value),
                blurRadius: 15,
                spreadRadius: -8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ModernTextField(
            tag: tag,
            controller: controller,
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            isPassword: isPassword,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
          ),
        );
      },
    );
  }
}

// Bouton 3D avec effet de profondeur
class ThreeDButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;

  const ThreeDButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.icon,
  });

  @override
  State<ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<ThreeDButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final primary = CustomTheme.lightScheme().primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        transform: Matrix4.identity()..translate(0.0, _isPressed ? 4.0 : 0.0),
        child: Stack(
          children: [
            // Ombre du bouton
            Positioned(
              left: 0,
              right: 0,
              bottom: _isPressed ? 0 : 4,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            // Bouton principal
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 24,
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
    );
  }
}

// Bouton avec effet néon
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.icon,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (context, _) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2 * _animation.value),
                blurRadius: 15,
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1 * _animation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ModernButton(
            text: widget.text,
            onPressed: widget.onPressed,
            icon: widget.icon,
            size: ModernButtonSize.large,
            type: ModernButtonType.secondary,
          ),
        );
      },
    );
  }
}

// Divider animé
class AnimatedDivider extends StatelessWidget {
  const AnimatedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withOpacity(0.3 * value),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.scale(
                scale: value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'OU',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.3 * value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Checkbox animée
class AnimatedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? CustomTheme.lightScheme().primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                value ? CustomTheme.lightScheme().primary : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: value ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

// Texte avec animation de typing
class TypingAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypingAnimatedText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypingAnimatedText> createState() => _TypingAnimatedTextState();
}

class _TypingAnimatedTextState extends State<TypingAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _textAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 100),
      vsync: this,
    );
    _textAnimation = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, _) {
        return Text(
          widget.text.substring(0, _textAnimation.value),
          style: widget.style.copyWith(
            color: CustomTheme.lightScheme().primary,
          ),
        );
      },
    );
  }
}
