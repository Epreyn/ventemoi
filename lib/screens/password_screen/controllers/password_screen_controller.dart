import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firebase_email_service.dart';

class PasswordScreenController extends GetxController {
  String pageTitle = 'Mot de passe oublié ?'.toUpperCase();

  String customBottomAppBarTag = 'password-bottom-app-bar';

  String emailTag = 'password-email';
  String emailLabel = 'Email';
  String emailError = 'Veuillez entrer une adresse mail valide';
  TextInputType emailInputType = TextInputType.emailAddress;
  TextEditingController emailController = TextEditingController();
  IconData emailIconData = Icons.email_outlined;

  String resetPasswordTag = 'password-reset-password';
  String resetPasswordLabel = 'Réinitialiser'.toUpperCase();
  IconData resetPasswordIconData = Icons.lock_reset_outlined;

  Widget resetText() {
    return SizedBox(
      width: UniquesControllers().data.baseMaxWidth, //Get.width * 0.9,
      child: Text(
        'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe',
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: UniquesControllers().data.baseSpace * 2,
          letterSpacing: 1.5,
          wordSpacing: 2,
          //color: CustomColors.caribbeanCurrent,
        ),
      ),
    );
  }

  void loginScreenOnPressed() {
    Get.offAllNamed(Routes.login);
  }

  void resetPassword() async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Récupérer le nom de l'utilisateur si possible
      String userName = '';
      try {
        final userQuery = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('users')
            .where('email', isEqualTo: emailController.text.trim())
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userName = userQuery.docs.first.data()['name'] ?? '';
        }
      } catch (e) {
        // Ignorer l'erreur si on ne peut pas récupérer le nom
      }

      // Envoyer l'email de réinitialisation avec template personnalisé
      final emailService = FirebaseEmailService();
      await emailService.sendCustomPasswordResetEmail(
        emailController.text.trim(),
        userName,
      );

      UniquesControllers().data.isInAsyncCall.value = false;
      Get.offAllNamed(Routes.login);
      UniquesControllers().data.snackbar(
          'Demande de réinitialisation de mot de passe',
          'Un email de réinitialisation de mot de passe vous a été envoyé',
          false);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar(
          'Erreur lors de la réinitialisation de mot de passe',
          'L\'adresse mail entrée n\'existe pas ou n\'est pas associée à un compte',
          true);
    }
  }

  @override
  void onReady() {
    super.onReady();
    emailController.text = UniquesControllers().getStorage.read('email') ?? '';
  }
}
