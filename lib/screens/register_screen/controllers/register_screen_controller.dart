import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';

class RegisterScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Inscription'.toUpperCase();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String userTypeTag = 'register-user-type';
  String userTypeLabel = 'Je suis un(e)';
  double userTypeMaxWidth = 350.0;
  double userTypeMaxHeight = 50.0;

  String nameTag = 'register-name';
  String nameLabel = 'Nom & Prénom';
  String nameError = 'Veuillez entrer un nom valide';
  TextInputAction nameTextInputAction = TextInputAction.next;
  TextInputType nameInputType = TextInputType.text;
  IconData nameIconData = Icons.person_outlined;
  String nameValidatorPattern = r'^[a-zA-ZÀ-ÖØ-öø-ÿ\s]{2,}$';
  TextEditingController nameController = TextEditingController();

  String emailTag = 'register-email';
  String emailLabel = 'Email';
  String emailError = 'Veuillez entrer une adresse mail valide';
  TextInputAction emailTextInputAction = TextInputAction.next;
  TextInputType emailInputType = TextInputType.emailAddress;
  IconData emailIconData = Icons.email_outlined;
  String emailValidatorPattern =
      r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$';
  TextEditingController emailController = TextEditingController();

  String passwordTag = 'register-password';
  String passwordLabel = 'Mot de Passe';
  String passwordError = 'Veuillez entrer un mot de passe';
  TextInputAction passwordTextInputAction = TextInputAction.next;
  TextInputType passwordInputType = TextInputType.visiblePassword;
  IconData passwordIconData = Icons.lock_outlined;
  String passwordValidatorPattern = r'^.{8,}$';
  TextEditingController passwordController = TextEditingController();

  String confirmPasswordTag = 'register-confirm-password';
  String confirmPasswordLabel = 'Confirmer le mot de passe';
  String confirmPasswordError = 'Veuillez confirmer votre mot de passe';
  TextInputAction confirmPasswordTextInputAction = TextInputAction.done;
  TextInputType confirmPasswordInputType = TextInputType.visiblePassword;
  IconData confirmPasswordIconData = Icons.lock_outlined;
  String confirmPasswordValidatorPattern = r'^.{8,}$';
  TextEditingController confirmPasswordController = TextEditingController();

  RxBool isConfirmedPassword = true.obs;
  RxBool isPressedRegisterButton = false.obs;

  RxString profileImageName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentUserType.value = null;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    isConfirmedPassword.value = true;
    isPressedRegisterButton.value = false;
  }

  bool checkPasswordConfirmation() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      final userCredential = await UniquesControllers()
          .data
          .firebaseAuth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Erreur lors de la création de l'utilisateur");
      }

      String imageUrl = '';
      if (UniquesControllers().data.isPickedFile.value) {
        if (UniquesControllers().data.profileImageFile.value != null) {
          imageUrl = await uploadProfileImage(
              UniquesControllers().data.profileImageFile.value!, user.uid);
        } else if (UniquesControllers().data.profileImageBytes.value != null) {
          imageUrl = await uploadProfileImageWeb(
              UniquesControllers().data.profileImageBytes.value!,
              profileImageName.value,
              user.uid);
        }
      }

      final userData = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'user_type_id': currentUserType.value?.id,
        'image_url': imageUrl,
        'isVisible': true,
        'isEnable': true,
      };

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set(userData);

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': user.uid,
        'points': 0,
        'coupons': 0,
        'bank_details': Map<String, dynamic>.from({
          'iban': '',
          'bic': '',
          'holder': '',
        }),
      });

      if (currentUserType.value?.name != 'Particulier') {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc()
            .set({
          'name': '',
          'user_id': user.uid,
          'description': '',
          'address': '',
          'telephone': '',
          'email': '',
          'logo_url': '',
          'banner_url': '',
          'category_id': '',
          'enterprise_categories': [],
          'enterprise_category_slots': 2, // Valeur par défaut
          'video_url': '',
          'has_accepted_contract': false,
        });
      }

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc()
          .set({
        'user_id': user.uid,
        'sponsoredEmails': [],
      });

      UniquesControllers().getStorage.write('email', emailController.text);
      UniquesControllers()
          .getStorage
          .write('password', passwordController.text);

      UniquesControllers().data.isInAsyncCall.value = false;

      await sendWelcomeEmail(user.email ?? '', nameController.text.trim());

      Get.toNamed(Routes.login);
      UniquesControllers().data.snackbar(
            'Inscription réussie',
            'Vous pouvez maintenant vous connecter !',
            false,
          );
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers()
          .data
          .snackbar('Erreur lors de l\'inscription', e.toString(), true);
    }
  }

  Future<String> uploadProfileImage(File file, String uid) async {
    String imageUrl = '';
    try {
      final fileName = p.basename(file.path);
      final dest = 'avatars/$uid/$fileName';

      final task =
          UniquesControllers().data.firebaseStorage.ref(dest).putFile(file);
      await task.whenComplete(() async {
        imageUrl = await task.snapshot.ref.getDownloadURL();
      });
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur image', e.toString(), true);
    }
    return imageUrl;
  }

  Future<String> uploadProfileImageWeb(
      Uint8List bytes, String fileName, String uid) async {
    String imageUrl = '';
    try {
      final dest = 'avatars/$uid/$fileName';
      final task =
          UniquesControllers().data.firebaseStorage.ref(dest).putData(bytes);
      await task.whenComplete(() async {
        imageUrl = await task.snapshot.ref.getDownloadURL();
      });
    } catch (e) {
      UniquesControllers()
          .data
          .snackbar('Erreur image Web', e.toString(), true);
    }
    return imageUrl;
  }
}
