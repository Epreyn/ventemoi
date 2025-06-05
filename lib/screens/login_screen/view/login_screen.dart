import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/unique_controllers.dart';

import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
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
                        // Logo et titre
                        _buildLogo(cc),
                        const SizedBox(height: 60),

                        // Formulaire
                        _buildLoginForm(cc),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

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

  Widget _buildLogo(LoginScreenController cc) {
    return Column(
      children: [
        // Logo avec ombre simple
        CustomCardAnimation(
          index: 0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CustomLogo(),
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Titre
        CustomCardAnimation(
          index: 1,
          child: Column(
            children: [
              Text(
                'VENTE MOI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: CustomTheme.lightScheme().primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildLoginForm(LoginScreenController cc) {
    return Column(
      children: [
        // Champ Email
        CustomCardAnimation(
          index: 2,
          child: _buildTextField(
            controller: cc.emailController,
            label: cc.emailLabel,
            icon: Icons.email_outlined,
            keyboardType: cc.emailInputType,
            textInputAction: cc.emailInputAction,
            onFieldSubmitted: (_) => cc.login(),
          ),
        ),
        const SizedBox(height: 20),

        // Champ Mot de passe
        CustomCardAnimation(
          index: 3,
          child: Obx(() => _buildTextField(
                controller: cc.passwordController,
                label: cc.passwordLabel,
                icon: Icons.lock_outline,
                isPasswordField: true,
                obscureText: !cc.isPasswordVisible.value,
                keyboardType: cc.passwordInputType,
                textInputAction: cc.passwordInputAction,
                onFieldSubmitted: (_) => cc.login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    cc.isPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: cc.togglePasswordVisibility,
                ),
              )),
        ),
        const SizedBox(height: 16),

        // Mot de passe oublié
        CustomCardAnimation(
          index: 4,
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

        // Bouton de connexion
        CustomCardAnimation(
          index: 5,
          child: _buildButton(
            text: cc.connectionLabel,
            onPressed: cc.login,
            isPrimary: true,
            icon: Icons.login_rounded,
          ),
        ),
        const SizedBox(height: 30),

        // Divider
        CustomCardAnimation(
          index: 6,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.3),
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
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Bouton d'inscription
        CustomCardAnimation(
          index: 7,
          child: _buildButton(
            text: cc.registerLabel,
            onPressed: cc.registerScreenOnPressed,
            isPrimary: false,
            icon: Icons.person_add_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool isPasswordField = false,
    bool obscureText = false,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
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
          suffixIcon: suffixIcon,
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? CustomTheme.lightScheme().primary : Colors.grey[900],
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                (isPrimary ? CustomTheme.lightScheme().primary : Colors.black)
                    .withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
}
