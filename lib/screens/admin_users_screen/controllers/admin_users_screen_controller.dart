import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/email_templates.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

// Vos imports habituels
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user.dart' as u;
import '../../../core/models/user_type.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class AdminUsersScreenController extends GetxController with ControllerMixin {
  // ID du doc "Administrateur" dans user_types => pour filtrer
  static const String adminTypeDocId = '3YxzCA7BewiMswi8FDSt';

  String pageTitle = 'Utilisateurs (Admin)'.toUpperCase();
  String customBottomAppBarTag = 'admin-users-bottom-app-bar';

  RxList<u.User> allUsers = <u.User>[].obs;

  /// Texte de recherche
  RxString searchText = ''.obs;

  /// Indices pour le tri DataTable
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  /// Subscription Firestore
  StreamSubscription<List<u.User>>? _usersSub;

  // ------------------------------------------------
  // Champs de Form (Invitation)
  // ------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Contrôleur pour l'email de l'utilisateur à inviter
  final emailCtrl = TextEditingController();

  // ------------------------------------------------
  // Lifecycle
  // ------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // On écoute la collection 'users'
    _usersSub = getAllUsersStream().listen((list) {
      allUsers.value = list;
      _sortUsers();
    });

    // Filtre
    ever(searchText, (_) => _sortUsers());
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    emailCtrl.dispose();
    super.onClose();
  }

  // ------------------------------------------------
  // Stream "users"
  // ------------------------------------------------
  Stream<List<u.User>> getAllUsersStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => u.User.fromDocument(d)).toList());
  }

  // ------------------------------------------------
  // Rechercher
  // ------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value.trim().toLowerCase();
  }

  // ------------------------------------------------
  // Filtrage
  // ------------------------------------------------
  List<u.User> get filteredUsers {
    // Exclure admin
    final nonAdmins =
        allUsers.where((u) => u.userTypeID != adminTypeDocId).toList();
    // Filtre text
    final st = searchText.value;
    if (st.isEmpty) {
      return nonAdmins;
    } else {
      return nonAdmins.where((u) {
        final lName = u.name.toLowerCase();
        final lMail = u.email.toLowerCase();
        return lName.contains(st) || lMail.contains(st);
      }).toList();
    }
  }

  // ------------------------------------------------
  // Tri
  // ------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortUsers();
  }

  void _sortUsers() {
    final sorted = allUsers.toList();
    sorted.sort((a, b) => _compareUsers(a, b));
    allUsers.value = sortAscending.value ? sorted : sorted.reversed.toList();
  }

  int _compareUsers(u.User a, u.User b) {
    switch (sortColumnIndex.value) {
      case 0:
        return a.name.compareTo(b.name);
      case 1:
        return a.email.compareTo(b.email);
      case 2:
        return a.userTypeID.compareTo(b.userTypeID);
      default:
        return 0;
    }
  }

  // ------------------------------------------------
  // Switch isEnabled / isVisible
  // ------------------------------------------------
  Future<void> onSwitchEnabled(u.User user, bool newValue) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.id)
          .update({'isEnable': newValue});

      // Envoi d'un email de notification si le compte est désactivé
      if (!newValue) {
        await sendAccountStatusEmail(
          toEmail: user.email,
          userName: user.name.isEmpty ? 'Utilisateur' : user.name,
          isEnabled: false,
        );
      }
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    }
  }

  Future<void> onSwitchVisible(u.User user, bool newValue) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.id)
          .update({'isVisible': newValue});
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    }
  }

  // ------------------------------------------------
  // Invitation d'un utilisateur via BottomSheet
  // ------------------------------------------------
  void openCreateUserBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Inviter un utilisateur',
      actionName: 'Envoyer l\'invitation',
      actionIcon: Icons.send,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    formKey.currentState?.reset();
    emailCtrl.clear();
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            // Info message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Un email d\'invitation sera envoyé à l\'utilisateur pour créer son compte.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const CustomSpace(heightMultiplier: 3),

            // Email
            CustomCardAnimation(
              index: 0,
              child: CustomTextFormField(
                tag: 'admin-user-invite-email',
                controller: emailCtrl,
                labelText: 'Email de l\'utilisateur',
                keyboardType: TextInputType.emailAddress,
                errorText: 'Email invalide',
                validatorPattern: r'^.+@[a-zA-Z]+\.[a-zA-Z]+$',
                iconData: Icons.email_outlined,
              ),
            ),

            const CustomSpace(heightMultiplier: 2),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    Get.back();

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      final email = emailCtrl.text.trim().toLowerCase();

      // Vérifier si l'utilisateur existe déjà
      final existingUsers = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw 'Un utilisateur avec cet email existe déjà';
      }

      // Générer un token unique pour l'invitation
      final invitationToken = DateTime.now().millisecondsSinceEpoch.toString() +
          UniqueKey().toString().replaceAll(RegExp(r'[^\w]'), '');

      // Enregistrer l'invitation dans une collection
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_invitations')
          .add({
        'email': email,
        'invited_by':
            UniquesControllers().data.firebaseAuth.currentUser?.email ??
                'admin',
        'invited_by_id':
            UniquesControllers().data.firebaseAuth.currentUser?.uid ?? '',
        'invited_at': DateTime.now(),
        'status': 'pending',
        'token': invitationToken,
        'expires_at':
            DateTime.now().add(Duration(days: 7)), // Expiration dans 7 jours
      });

      // Envoyer l'email d'invitation
      await sendInvitationEmail(
        toEmail: email,
        invitedBy: UniquesControllers().data.firebaseAuth.currentUser?.email ??
            'un administrateur',
        invitationToken: invitationToken,
      );

      UniquesControllers()
          .data
          .snackbar('Succès', 'Invitation envoyée à $email', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ------------------------------------------------
  // Fonction pour envoyer l'email d'invitation avec le système existant
  // ------------------------------------------------
  Future<void> sendInvitationEmail({
    required String toEmail,
    required String invitedBy,
    required String invitationToken,
  }) async {
    final invitationLink =
        'https://ventemoi.com/invitation?token=$invitationToken&email=$toEmail';

    final content = '''
      <h2>Vous êtes invité(e) à rejoindre Vente Moi ! 🎉</h2>
      <p>
        <strong>$invitedBy</strong> vous invite à rejoindre la plateforme Vente Moi,
        où vous pourrez profiter de nombreux avantages et participer à une économie solidaire.
      </p>

      <div class="highlight-box">
        <h3>📧 Votre invitation</h3>
        <p style="margin: 15px 0;">
          Cette invitation a été créée spécialement pour vous.<br>
          Elle est valable pendant <strong>7 jours</strong>.
        </p>
      </div>

      <p>
        <strong>Comment rejoindre Vente Moi ?</strong><br>
        C'est très simple ! Cliquez sur le bouton ci-dessous pour créer votre compte :
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="$invitationLink" class="button">Créer mon compte</a>
      </div>

      <div class="divider"></div>

      <h3 style="color: #333; font-size: 18px; margin-bottom: 15px;">✨ Pourquoi rejoindre Vente Moi ?</h3>
      <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 15px 0;">
        <p style="margin: 10px 0;">
          <strong>🎁 Des bons d'achat</strong> - Profitez de réductions chez nos partenaires<br>
          <strong>💰 Des points bonus</strong> - Gagnez des points à utiliser dans notre boutique<br>
          <strong>❤️ Une communauté solidaire</strong> - Soutenez des associations locales<br>
          <strong>🌟 Des offres exclusives</strong> - Accédez à des promotions réservées aux membres
        </p>
      </div>

      <p style="font-size: 14px; color: #888; margin-top: 30px;">
        💡 <strong>Note :</strong> Si vous n'avez pas demandé cette invitation, vous pouvez ignorer cet email.
        Le lien expirera automatiquement dans 7 jours.
      </p>

      <p style="font-size: 14px; color: #888;">
        Vous ne pouvez pas cliquer sur le bouton ? Copiez et collez ce lien dans votre navigateur :<br>
        <a href="$invitationLink" style="color: #ff7a00; word-break: break-all;">$invitationLink</a>
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🎉 $invitedBy vous invite sur Vente Moi',
      htmlBody: this.buildModernMailHtml(content),
    );
  }

  // ------------------------------------------------
  // Email de notification de changement de statut de compte
  // ------------------------------------------------
  Future<void> sendAccountStatusEmail({
    required String toEmail,
    required String userName,
    required bool isEnabled,
  }) async {
    final subject = isEnabled
        ? '✅ Votre compte Vente Moi a été réactivé'
        : '⚠️ Votre compte Vente Moi a été temporairement désactivé';

    final content = isEnabled
        ? '''
        <h2>Bonne nouvelle $userName !</h2>
        <p>
          Votre compte Vente Moi vient d'être <strong>réactivé</strong>.
          Vous pouvez à nouveau vous connecter et profiter de tous nos services.
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://ventemoi.com/login" class="button">Se connecter</a>
        </div>

        <p>
          Si vous avez des questions, n'hésitez pas à contacter notre support.
        </p>
      '''
        : '''
        <h2>Information importante concernant votre compte</h2>
        <p>
          Bonjour $userName,<br><br>
          Votre compte Vente Moi a été <strong>temporairement désactivé</strong> par un administrateur.
        </p>

        <div class="highlight-box" style="background: #fff3cd; border-color: #ffc107;">
          <h3 style="color: #856404;">⚠️ Compte désactivé</h3>
          <p style="color: #856404;">
            Vous ne pouvez plus vous connecter à votre compte pour le moment.
            Cette mesure est temporaire.
          </p>
        </div>

        <p>
          <strong>Que faire ?</strong><br>
          Si vous pensez qu'il s'agit d'une erreur ou si vous souhaitez plus d'informations,
          veuillez contacter notre équipe support :
        </p>

        <p style="text-align: center; margin: 20px 0;">
          📧 <a href="mailto:support@ventemoi.com" style="color: #ff7a00;">support@ventemoi.com</a>
        </p>

        <p style="font-size: 14px; color: #888;">
          Nous nous excusons pour la gêne occasionnée et ferons notre possible pour
          résoudre cette situation rapidement.
        </p>
      ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: subject,
      htmlBody: this.buildModernMailHtml(content),
    );
  }

  // ------------------------------------------------
  // Email de rappel pour les invitations
  // ------------------------------------------------
  Future<void> sendInvitationReminderEmail({
    required String toEmail,
    required String invitedBy,
    required String invitationToken,
    required int daysRemaining,
  }) async {
    final invitationLink =
        'https://ventemoi.com/invitation?token=$invitationToken&email=$toEmail';

    final content = '''
      <h2>⏰ Rappel : Votre invitation Vente Moi expire bientôt !</h2>
      <p>
        Il y a quelques jours, <strong>$invitedBy</strong> vous a invité à rejoindre Vente Moi.
        Cette invitation expire dans <strong>$daysRemaining jour${daysRemaining > 1 ? 's' : ''}</strong>.
      </p>

      <div class="highlight-box" style="background: #fff3cd; border-color: #ffc107;">
        <h3 style="color: #856404;">⏳ Plus que $daysRemaining jour${daysRemaining > 1 ? 's' : ''} !</h3>
        <p style="color: #856404;">
          N'attendez plus pour créer votre compte et profiter de tous les avantages.
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="$invitationLink" class="button">Créer mon compte maintenant</a>
      </div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Rappel des avantages :</strong> Points bonus à l'inscription,
        bons d'achat chez nos partenaires, soutien aux associations locales, et bien plus !
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject:
          '⏰ Plus que $daysRemaining jour${daysRemaining > 1 ? 's' : ''} pour accepter votre invitation Vente Moi',
      htmlBody: this.buildModernMailHtml(content),
    );
  }

  // ------------------------------------------------
  // Fonction pour vérifier et envoyer des rappels d'invitation
  // ------------------------------------------------
  Future<void> checkAndSendInvitationReminders() async {
    try {
      final now = DateTime.now();

      // Récupérer toutes les invitations en attente
      final invitations = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_invitations')
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in invitations.docs) {
        final data = doc.data();
        final expiresAt = (data['expires_at'] as dynamic).toDate();
        final invitedAt = (data['invited_at'] as dynamic).toDate();
        final daysRemaining = expiresAt.difference(now).inDays;

        // Envoyer un rappel si l'invitation expire dans 2 jours et qu'elle a été créée il y a au moins 3 jours
        if (daysRemaining == 2 && now.difference(invitedAt).inDays >= 3) {
          final hasReminder = data['reminder_sent'] ?? false;

          if (!hasReminder) {
            await sendInvitationReminderEmail(
              toEmail: data['email'],
              invitedBy: data['invited_by'],
              invitationToken: data['token'],
              daysRemaining: daysRemaining,
            );

            // Marquer le rappel comme envoyé
            await doc.reference.update({'reminder_sent': true});
          }
        }

        // Marquer comme expiré si nécessaire
        if (daysRemaining < 0) {
          await doc.reference.update({'status': 'expired'});
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des invitations: $e');
    }
  }
}
