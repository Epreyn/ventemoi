import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Type d'utilisateur
  String userTypeTag = 'register-user-type';
  String userTypeLabel = 'Je suis un(e)';
  double userTypeMaxWidth = 350.0;
  double userTypeMaxHeight = 50.0;

  // Champs du formulaire
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

  // Association parrainage
  String associationSearchTag = 'association-search';
  String associationSearchLabel = 'Rechercher une association (optionnel)';
  TextEditingController associationSearchController = TextEditingController();

  // Email d'invitation
  String invitationEmailTag = 'invitation-email';
  String invitationEmailLabel = 'Email de l\'association à inviter';
  TextEditingController invitationEmailController = TextEditingController();

  RxBool isConfirmedPassword = true.obs;
  RxBool isPressedRegisterButton = false.obs;

  RxString profileImageName = ''.obs;

  // Association sélectionnée
  Rx<Map<String, dynamic>?> selectedAssociation =
      Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  RxBool showInviteOption = false.obs;
  RxBool isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentUserType.value = null;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    associationSearchController.clear();
    invitationEmailController.clear();
    isConfirmedPassword.value = true;
    isPressedRegisterButton.value = false;
    selectedAssociation.value = null;
    searchResults.clear();
    showInviteOption.value = false;
  }

  bool checkPasswordConfirmation() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  // Recherche d'associations
  Future<void> searchAssociations(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;

    try {
      // D'abord, récupérer l'ID du type "Association"
      final userTypeSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .where('name', isEqualTo: 'Association')
          .limit(1)
          .get();

      if (userTypeSnap.docs.isEmpty) {
        searchResults.clear();
        showInviteOption.value = true;
        isSearching.value = false;
        return;
      }

      final associationTypeId = userTypeSnap.docs.first.id;

      // Rechercher les utilisateurs de type Association
      final usersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('user_type_id', isEqualTo: associationTypeId)
          .where('isVisible', isEqualTo: true)
          .get();

      // Filtrer par nom
      final lowerQuery = query.toLowerCase();
      final filteredUsers = usersSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery);
      }).toList();

      // Si aucun résultat, montrer l'option d'invitation
      if (filteredUsers.isEmpty) {
        searchResults.clear();
        showInviteOption.value = true;
      } else {
        // Transformer en Map avec les infos nécessaires
        searchResults.value = filteredUsers.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'image_url': data['image_url'] ?? '',
          };
        }).toList();
        showInviteOption.value = false;
      }
    } catch (e) {
      print('Erreur lors de la recherche d\'associations: $e');
      searchResults.clear();
      showInviteOption.value = true;
    } finally {
      isSearching.value = false;
    }
  }

  // Sélectionner une association
  void selectAssociation(Map<String, dynamic> association) {
    selectedAssociation.value = association;
    associationSearchController.text = association['name'];
    searchResults.clear();
    showInviteOption.value = false;
  }

  // Afficher l'option d'invitation
  void showInviteAssociation() {
    showInviteOption.value = true;
    searchResults.clear();
    selectedAssociation.value = null;
  }

  // Envoyer une invitation par email
  Future<void> sendInvitationEmail(String associationEmail) async {
    if (associationEmail.trim().isEmpty) return;

    try {
      final userName = nameController.text.trim();
      final userEmail = emailController.text.trim();

      await sendMailSimple(
        toEmail: associationEmail,
        subject: 'Invitation à rejoindre VenteMoi',
        htmlBody: _buildInvitationEmailHtml(userName, userEmail),
      );

      UniquesControllers().data.snackbar(
            'Invitation envoyée',
            'Un email d\'invitation a été envoyé à $associationEmail',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible d\'envoyer l\'invitation: $e',
            true,
          );
    }
  }

  String _buildInvitationEmailHtml(String userName, String userEmail) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Invitation VenteMoi</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        margin: 0; padding: 0;
        background-color: #fafafa;
        color: #333;
      }
      .header {
        background-color: #f8b02a;
        padding: 16px;
        text-align: center;
      }
      .header img {
        max-height: 50px;
      }
      .content {
        margin: 16px;
      }
      h1 { color: #f8b02a; }
      p { line-height: 1.5; }
      .button {
        display: inline-block;
        background-color: #f8b02a;
        color: white;
        padding: 12px 24px;
        text-decoration: none;
        border-radius: 5px;
        margin: 20px 0;
      }
      .footer {
        margin: 16px;
        font-size: 12px;
        color: #666;
      }
    </style>
  </head>
  <body>
    <div class="header">
      <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media"
           alt="Logo Vente Moi" />
    </div>
    <div class="content">
      <h1>Rejoignez VenteMoi !</h1>
      <p>
        Bonjour,<br><br>
        <strong>$userName</strong> ($userEmail) souhaite vous inviter à rejoindre
        la plateforme VenteMoi en tant qu'association partenaire.
      </p>
      <p>
        VenteMoi est une plateforme solidaire qui permet aux associations de
        recevoir des dons de la part des particuliers grâce à un système de points innovant.
      </p>
      <p>
        En rejoignant VenteMoi, vous pourrez :
      </p>
      <ul>
        <li>Recevoir des dons directs de la part des utilisateurs</li>
        <li>Présenter vos projets et actions</li>
        <li>Développer votre visibilité auprès de nouveaux donateurs</li>
        <li>Participer à l'économie solidaire locale</li>
      </ul>
      <p style="text-align: center;">
        <a href="https://ventemoi.com/register" class="button">
          S'inscrire sur VenteMoi
        </a>
      </p>
      <p>
        À très bientôt sur VenteMoi !<br>
        L'équipe VenteMoi
      </p>
    </div>
    <div class="footer">
      Cet e-mail vous a été envoyé par un utilisateur de VenteMoi.<br>
      Pour toute question, contactez
      <a href="mailto:support@ventemoi.com">support@ventemoi.com</a>.
    </div>
  </body>
</html>
''';
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Envoyer l'invitation si nécessaire
    if (showInviteOption.value && invitationEmailController.text.isNotEmpty) {
      await sendInvitationEmail(invitationEmailController.text.trim());
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
          'enterprise_category_slots': 2,
          'video_url': '',
          'has_accepted_contract': false,
        });
      }

      // Créer le document sponsorship
      final sponsoredEmails = <String>[];

      // Si une association a été sélectionnée, ajouter l'utilisateur comme filleul
      if (selectedAssociation.value != null) {
        final associationId = selectedAssociation.value!['id'];

        // Récupérer le document sponsorship de l'association
        final sponsorshipSnap = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('sponsorships')
            .where('user_id', isEqualTo: associationId)
            .limit(1)
            .get();

        if (sponsorshipSnap.docs.isNotEmpty) {
          // Ajouter l'email de l'utilisateur aux emails sponsorisés
          await sponsorshipSnap.docs.first.reference.update({
            'sponsored_emails': FieldValue.arrayUnion(
                [emailController.text.trim().toLowerCase()])
          });
        }
      }

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc()
          .set({
        'user_id': user.uid,
        'sponsored_emails': sponsoredEmails,
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
