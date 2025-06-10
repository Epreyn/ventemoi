import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:ventemoi/core/classes/email_templates.dart';

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

  // Code de parrainage
  String referralCodeTag = 'referral-code';
  String referralCodeLabel = 'Code de parrainage (optionnel)';
  TextEditingController referralCodeController = TextEditingController();
  RxBool hasValidReferralCode = false.obs;
  Rx<Map<String, dynamic>?> sponsorInfo = Rx<Map<String, dynamic>?>(null);

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

  // Variables pour les points en attente
  RxBool hasPendingPoints = false.obs;
  RxInt pendingPointsAmount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentUserType.value = null;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    referralCodeController.clear();
    associationSearchController.clear();
    invitationEmailController.clear();
    isConfirmedPassword.value = true;
    isPressedRegisterButton.value = false;
    selectedAssociation.value = null;
    searchResults.clear();
    showInviteOption.value = false;
    hasValidReferralCode.value = false;
    sponsorInfo.value = null;
    hasPendingPoints.value = false;
    pendingPointsAmount.value = 0;

    // Vérifier si un code de parrainage est passé en paramètre URL
    final referralCode = Get.parameters['code'];
    if (referralCode != null && referralCode.isNotEmpty) {
      referralCodeController.text = referralCode;
      validateReferralCode(referralCode);
    }

    // Vérifier si c'est une invitation avec des points (token dans l'URL)
    final invitationToken = Get.parameters['token'];
    final invitationEmail = Get.parameters['email'];
    if (invitationToken != null && invitationToken.isNotEmpty) {
      _checkInvitationToken(invitationToken, invitationEmail);
    }
  }

  // Vérifier le token d'invitation et pré-remplir l'email
  Future<void> _checkInvitationToken(String token, String? email) async {
    try {
      // Rechercher l'attribution en attente avec ce token
      final pendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('pending_points_attributions')
          .where('invitation_token', isEqualTo: token)
          .where('claimed', isEqualTo: false)
          .limit(1)
          .get();

      if (pendingSnap.docs.isNotEmpty) {
        final data = pendingSnap.docs.first.data();
        final points = data['points'] ?? 0;
        final pendingEmail = data['email'] ?? '';

        // Pré-remplir l'email et le rendre non modifiable
        if (email != null && email.isNotEmpty) {
          emailController.text = Uri.decodeComponent(email);
        } else if (pendingEmail.isNotEmpty) {
          emailController.text = pendingEmail;
        }

        hasPendingPoints.value = true;
        pendingPointsAmount.value = points;
      }
    } catch (e) {
      print('Erreur vérification token invitation: $e');
    }
  }

  bool checkPasswordConfirmation() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  // Valider le code de parrainage
  Future<void> validateReferralCode(String code) async {
    if (code.trim().isEmpty) {
      hasValidReferralCode.value = false;
      sponsorInfo.value = null;
      return;
    }

    try {
      // Rechercher l'utilisateur avec ce code
      final userQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('referral_code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        hasValidReferralCode.value = true;
        sponsorInfo.value = userQuery.docs.first.data();
        sponsorInfo.value!['id'] = userQuery.docs.first.id;
      } else {
        hasValidReferralCode.value = false;
        sponsorInfo.value = null;
        UniquesControllers().data.snackbar(
              'Code invalide',
              'Ce code de parrainage n\'existe pas',
              true,
            );
      }
    } catch (e) {
      hasValidReferralCode.value = false;
      sponsorInfo.value = null;
    }
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

      // Vérifier si l'email est dans une liste de parrainage
      final emailToCheck = emailController.text.trim().toLowerCase();
      Map<String, dynamic>? actualSponsorInfo;

      final sponsorshipQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .where('sponsored_emails', arrayContains: emailToCheck)
          .limit(1)
          .get();

      if (sponsorshipQuery.docs.isNotEmpty) {
        // L'email est parrainé
        final sponsorId = sponsorshipQuery.docs.first.data()['user_id'];
        final sponsorDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('users')
            .doc(sponsorId)
            .get();

        if (sponsorDoc.exists) {
          actualSponsorInfo = sponsorDoc.data();
          actualSponsorInfo!['id'] = sponsorDoc.id;
        }
      } else if (hasValidReferralCode.value && sponsorInfo.value != null) {
        // Utiliser le code de parrainage saisi
        actualSponsorInfo = sponsorInfo.value;
      }

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

      // Générer un code de parrainage pour le nouvel utilisateur
      final newReferralCode = _generateReferralCode();

      final userData = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'user_type_id': currentUserType.value?.id,
        'image_url': imageUrl,
        'isVisible': true,
        'isEnable': true,
        'referral_code': newReferralCode,
        'created_at': FieldValue.serverTimestamp(),
      };

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set(userData);

      // Calculer les points de bienvenue
      int welcomePoints = 0;
      if (actualSponsorInfo != null) {
        welcomePoints = 100; // Bonus de parrainage
      }

      // NOUVEAU : Vérifier et réclamer les points en attente
      final pendingPoints =
          await _checkAndClaimPendingPoints(emailToCheck, user.uid);
      welcomePoints += pendingPoints;

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': user.uid,
        'points': welcomePoints,
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
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc()
          .set({
        'user_id': user.uid,
        'sponsored_emails': [],
      });

      // Si parrainé, mettre à jour le parrain
      if (actualSponsorInfo != null) {
        // Retirer l'email de la liste sponsored_emails du parrain
        if (sponsorshipQuery.docs.isNotEmpty) {
          await sponsorshipQuery.docs.first.reference.update({
            'sponsored_emails': FieldValue.arrayRemove([emailToCheck])
          });
        }

        // Ajouter des points au parrain
        await _addReferralPointsToSponsor(actualSponsorInfo['id'], 50);

        // Envoyer un email de notification au parrain
        await sendSponsorshipNotificationEmail(
          sponsorEmail: actualSponsorInfo['email'],
          sponsorName: actualSponsorInfo['name'],
          newUserEmail: emailController.text.trim(),
          pointsEarned: 50,
        );
      }

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

      UniquesControllers().getStorage.write('email', emailController.text);
      UniquesControllers()
          .getStorage
          .write('password', passwordController.text);

      UniquesControllers().data.isInAsyncCall.value = false;

      await sendModernWelcomeEmail(
          user.email ?? '', nameController.text.trim());

      Get.toNamed(Routes.login);

      // Message personnalisé en fonction des points reçus
      String successMessage = 'Inscription réussie !';
      if (pendingPoints > 0 && actualSponsorInfo != null) {
        successMessage =
            'Bienvenue ! Vous avez reçu ${welcomePoints} points (${pendingPoints} points en attente + 100 points de parrainage).';
      } else if (pendingPoints > 0) {
        successMessage =
            'Bienvenue ! Vous avez reçu ${pendingPoints} points qui vous attendaient.';
      } else if (actualSponsorInfo != null) {
        successMessage =
            'Bienvenue ! Vous avez reçu 100 points de bienvenue grâce au parrainage.';
      } else {
        successMessage = 'Vous pouvez maintenant vous connecter !';
      }

      UniquesControllers().data.snackbar(
            'Inscription réussie',
            successMessage,
            false,
          );
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers()
          .data
          .snackbar('Erreur lors de l\'inscription', e.toString(), true);
    }
  }

  // NOUVEAU : Méthode pour vérifier et réclamer les points en attente
  Future<int> _checkAndClaimPendingPoints(String email, String userId) async {
    try {
      final pendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('pending_points_attributions')
          .where('email', isEqualTo: email.toLowerCase())
          .where('claimed', isEqualTo: false)
          .get();

      if (pendingSnap.docs.isEmpty) return 0;

      int totalPoints = 0;
      final batch = UniquesControllers().data.firebaseFirestore.batch();

      for (final doc in pendingSnap.docs) {
        final data = doc.data();
        final points = data['points'] ?? 0;
        totalPoints += points as int;

        // Marquer comme réclamé
        batch.update(doc.reference, {
          'claimed': true,
          'claimed_by_user_id': userId,
          'claimed_at': DateTime.now(),
        });

        // Créer une attribution validée
        final attributionRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('points_attributions')
            .doc();
        batch.set(attributionRef, {
          'giver_id': data['giver_id'],
          'target_id': userId,
          'target_email': email,
          'date': DateTime.now(),
          'cost': 0,
          'points': points,
          'commission_percent': 0,
          'commission_cost': 0,
          'validated': true,
          'from_pending': true,
        });
      }

      await batch.commit();
      return totalPoints;
    } catch (e) {
      print('Erreur lors de la réclamation des points en attente: $e');
      return 0;
    }
  }

  String _generateReferralCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _addReferralPointsToSponsor(String sponsorId, int points) async {
    try {
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: sponsorId)
          .limit(1)
          .get();

      if (walletQuery.docs.isNotEmpty) {
        await walletQuery.docs.first.reference.update({
          'points': FieldValue.increment(points),
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ajout des points de parrainage: $e');
    }
  }

  Future<void> sendSponsorshipNotificationEmail({
    required String sponsorEmail,
    required String sponsorName,
    required String newUserEmail,
    required int pointsEarned,
  }) async {
    final content = '''
      <h2>🎉 Félicitations $sponsorName !</h2>
      <p>
        Excellente nouvelle ! <strong>$newUserEmail</strong> vient de s'inscrire
        sur VenteMoi grâce à votre parrainage.
      </p>

      <div class="highlight-box">
        <h3>Votre récompense</h3>
        <div class="info-value" style="font-size: 32px; color: #ff7a00; margin: 10px 0;">
          +$pointsEarned points
        </div>
        <p style="margin: 10px 0; color: #666;">
          Ces points ont été ajoutés à votre compte
        </p>
      </div>

      <p>
        Continuez à parrainer vos proches et gagnez encore plus de récompenses !
        Chaque nouveau filleul actif vous rapporte des points bonus.
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://ventemoi.com/parrainage" class="button">
          Parrainer d'autres amis
        </a>
      </div>

      <div class="divider"></div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Rappel :</strong> Vous gagnez également 10% des achats
        réalisés par vos filleuls. Plus vous parrainez, plus vous gagnez !
      </p>
    ''';

    await sendMailSimple(
      toEmail: sponsorEmail,
      subject: '🎊 $newUserEmail s\'est inscrit grâce à vous !',
      htmlBody: buildModernMailHtml(content),
    );
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
