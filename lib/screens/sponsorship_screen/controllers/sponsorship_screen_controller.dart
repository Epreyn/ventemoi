import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/email_templates.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/sponsorship.dart';

class SponsorshipScreenController extends GetxController with ControllerMixin {
  // Titre
  String pageTitle = 'Parrainage'.toUpperCase();
  String customBottomAppBarTag = 'sponsorship-bottom-app-bar';

  // Observables
  Rx<Sponsorship?> currentSponsorship = Rx<Sponsorship?>(null);
  RxString referralCode = ''.obs;
  RxInt totalEarnings = 0.obs;
  RxInt activeReferrals = 0.obs;
  Rx<Map<String, dynamic>?> sponsorInfo = Rx<Map<String, dynamic>?>(null);
  RxMap<String, Map<String, dynamic>> referralDetails =
      <String, Map<String, dynamic>>{}.obs;

  // Subscriptions
  StreamSubscription<Sponsorship?>? _sponsorshipSub;
  StreamSubscription<QuerySnapshot>? _referralsSub;
  StreamSubscription<DocumentSnapshot>? _sponsorSub;

  // Controllers
  final TextEditingController emailCtrl = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // IDs
  String? sponsorshipDocId;

  @override
  void onInit() {
    super.onInit();
    _initializeSponsorship();
  }

  @override
  void onClose() {
    _sponsorshipSub?.cancel();
    _referralsSub?.cancel();
    _sponsorSub?.cancel();
    emailCtrl.dispose();
    super.onClose();
  }

  void _initializeSponsorship() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    // Générer ou récupérer le code de parrainage
    await _initializeReferralCode(uid);

    // Écouter les changements du document sponsorship
    _sponsorshipSub = _listenSponsorshipDoc(uid).listen((sponsorship) {
      currentSponsorship.value = sponsorship;
      _updateReferralDetails(sponsorship?.sponsoredEmails ?? []);
    });

    // Vérifier si l'utilisateur a un parrain
    await _checkForSponsor(uid);

    // Calculer les gains totaux
    _calculateTotalEarnings();
  }

  Future<void> _initializeReferralCode(String uid) async {
    try {
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['referral_code'] != null) {
          referralCode.value = data!['referral_code'];
        } else {
          // Générer un nouveau code
          final newCode = _generateReferralCode();
          await userDoc.reference.update({'referral_code': newCode});
          referralCode.value = newCode;
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du code de parrainage: $e');
    }
  }

  String _generateReferralCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _checkForSponsor(String uid) async {
    try {
      // Rechercher si cet utilisateur apparaît dans une liste sponsored_emails
      final sponsorshipQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .where('sponsored_emails',
              arrayContains:
                  UniquesControllers().data.firebaseAuth.currentUser?.email)
          .limit(1)
          .get();

      if (sponsorshipQuery.docs.isNotEmpty) {
        final sponsorId = sponsorshipQuery.docs.first.data()['user_id'];

        // Écouter les infos du parrain
        _sponsorSub = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('users')
            .doc(sponsorId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            sponsorInfo.value = snapshot.data();
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du parrain: $e');
    }
  }

  void _updateReferralDetails(List<String> emails) async {
    for (String email in emails) {
      try {
        // Récupérer les infos de l'utilisateur parrainé
        final userQuery = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          final userId = userQuery.docs.first.id;

          // Vérifier si l'utilisateur est actif
          final isActive = userData['isEnable'] ?? false;

          // Récupérer les gains générés par ce filleul
          final earnings = await _calculateEarningsFromReferral(userId);

          referralDetails[email] = {
            'isActive': isActive,
            'earnings': earnings,
            'joinDate': _formatDate(userData['created_at']),
            'name': userData['name'] ?? '',
          };

          if (isActive) {
            activeReferrals.value++;
          }
        } else {
          // Utilisateur pas encore inscrit
          referralDetails[email] = {
            'isActive': false,
            'earnings': 0,
            'joinDate': '',
            'name': '',
          };
        }
      } catch (e) {
        print(
            'Erreur lors de la mise à jour des détails du filleul $email: $e');
      }
    }
  }

  Future<int> _calculateEarningsFromReferral(String referralId) async {
    // Logique pour calculer les gains générés par un filleul
    // Par exemple: 10% des achats du filleul, bonus d'inscription, etc.
    try {
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: referralId)
          .limit(1)
          .get();

      if (walletQuery.docs.isNotEmpty) {
        final walletData = walletQuery.docs.first.data();
        // Exemple: 5€ de bonus par filleul actif + 10% de ses achats
        final totalSpent = (walletData['total_spent'] ?? 0) as num;
        return 5 + (totalSpent * 0.1).round();
      }
    } catch (e) {
      print('Erreur lors du calcul des gains: $e');
    }
    return 0;
  }

  void _calculateTotalEarnings() {
    int total = 0;
    referralDetails.forEach((email, details) {
      total += (details['earnings'] as int?) ?? 0;
    });
    totalEarnings.value = total;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Stream<Sponsorship?> _listenSponsorshipDoc(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      sponsorshipDocId = doc.id;
      return Sponsorship.fromDocument(doc);
    });
  }

  void copyReferralCode() {
    Clipboard.setData(ClipboardData(text: referralCode.value));
    UniquesControllers().data.snackbar(
          'Copié !',
          'Code de parrainage copié dans le presse-papier',
          false,
        );
  }

  void shareReferralCode() {
    // Au lieu de partager, on ouvre le bottom sheet pour envoyer un email
    openCreateUserBottomSheet();
  }

  Future<void> removeReferral(String email) async {
    if (sponsorshipDocId == null) return;

    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc(sponsorshipDocId!)
          .update({
        'sponsored_emails': FieldValue.arrayRemove([email]),
      });

      referralDetails.remove(email);
      _calculateTotalEarnings();

      UniquesControllers().data.snackbar(
            'Succès',
            'Filleul retiré de votre liste',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de retirer ce filleul',
            true,
          );
    }
  }

  Future<void> onAddSponsorship() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    Get.back();

    final emailToSponsor = emailCtrl.text.trim().toLowerCase();
    if (emailToSponsor.isEmpty) return;

    final sponsorUid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (sponsorUid == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      // Vérifier si cet email est déjà parrainé
      final oldList = currentSponsorship.value?.sponsoredEmails ?? [];
      if (oldList.contains(emailToSponsor)) {
        UniquesControllers().data.snackbar(
              'Attention',
              'Cet email est déjà dans votre liste de filleuls.',
              true,
            );
        return;
      }

      // Vérifier si l'utilisateur existe déjà
      final userSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: emailToSponsor)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        // L'utilisateur existe déjà
        UniquesControllers().data.snackbar(
              'Information',
              'Cet utilisateur possède déjà un compte.',
              true,
            );
        return;
      }

      // Ajouter l'email à la liste des parrainés (sans créer de compte)
      await _addSponsoredEmailToList(emailToSponsor);

      // Envoyer l'email d'invitation
      await sendReferralInvitationEmail(
        toEmail: emailToSponsor,
        sponsorName:
            UniquesControllers().data.firebaseAuth.currentUser?.displayName ??
                UniquesControllers().data.firebaseAuth.currentUser?.email ??
                'Un ami',
        referralCode: referralCode.value,
      );

      UniquesControllers().data.snackbar(
            'Invitation envoyée ! 🎉',
            'Un email d\'invitation a été envoyé à $emailToSponsor',
            false,
          );
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Envoyer l'email d'invitation de parrainage
  Future<void> sendReferralInvitationEmail({
    required String toEmail,
    required String sponsorName,
    required String referralCode,
  }) async {
    final content = '''
      <h2>🎉 $sponsorName vous invite sur VenteMoi !</h2>

      <p>
        Vous avez été invité(e) à rejoindre VenteMoi, la plateforme qui révolutionne
        les achats locaux et solidaires !
      </p>

      <div class="highlight-box">
        <h3>Votre code de parrainage exclusif</h3>
        <div class="code-box">$referralCode</div>
        <p style="margin: 15px 0 5px 0; color: #666;">
          Ce code vous donne droit à <strong>100 points offerts</strong> à l'inscription !
        </p>
      </div>

      <p>
        <strong>Pourquoi rejoindre VenteMoi ?</strong>
      </p>
      <ul style="line-height: 1.8;">
        <li>💰 <strong>100 points de bienvenue</strong> grâce au parrainage</li>
        <li>🛍️ Des réductions exclusives chez nos commerçants partenaires</li>
        <li>❤️ La possibilité de soutenir des associations locales</li>
        <li>🎁 Des bons d'achat à utiliser dans vos boutiques préférées</li>
      </ul>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://ventemoi.com/register?code=$referralCode" class="button">
          Je m'inscris maintenant
        </a>
      </div>

      <div class="divider"></div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Comment utiliser votre code ?</strong><br>
        Lors de votre inscription, entrez simplement le code <strong>$referralCode</strong>
        dans le champ prévu à cet effet pour recevoir vos points bonus.
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🎁 $sponsorName vous offre 100 points sur VenteMoi !',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Supprimer la fonction createUserWithoutSwitchingSession car on ne crée plus de compte

  Future<void> _addSponsoredEmailToList(String email) async {
    if (sponsorshipDocId == null) {
      // Créer un nouveau document sponsorship
      final newRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc();
      sponsorshipDocId = newRef.id;

      final sponsorUid =
          UniquesControllers().data.firebaseAuth.currentUser?.uid;

      await newRef.set({
        'user_id': sponsorUid,
        'sponsored_emails': [email],
      });
    } else {
      // Mettre à jour le document existant
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc(sponsorshipDocId!)
          .update({
        'sponsored_emails': FieldValue.arrayUnion([email]),
      });
    }
  }

  @override
  void variablesToResetToBottomSheet() {
    emailCtrl.clear();
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            Text(
              'Invitez vos proches à rejoindre VenteMoi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomTextFormField(
              tag: UniqueKey().toString(),
              controller: emailCtrl,
              labelText: 'Email du filleul',
              iconData: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Veuillez entrer un email';
                }
                final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!pattern.hasMatch(val.trim())) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gagnez 50 points par filleul + 10% de ses achats',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    await onAddSponsorship();
  }

  void openCreateUserBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Parrainer un proche',
      actionName: 'Envoyer l\'invitation',
      actionIcon: Icons.send_rounded,
    );
  }
}
