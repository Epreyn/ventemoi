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
import '../../../core/theme/custom_theme.dart';

class SponsorshipScreenController extends GetxController with ControllerMixin {
  // Titre
  String pageTitle = 'Parrainage'.toUpperCase();
  String customBottomAppBarTag = 'sponsorship-bottom-app-bar';

  // Observables
  Rx<Sponsorship?> currentSponsorship = Rx<Sponsorship?>(null);
  RxString referralCode = ''.obs;
  RxInt totalEarnings = 0.obs;
  RxInt activeReferrals = 0.obs;
  RxInt pendingReferrals = 0.obs;
  Rx<Map<String, dynamic>?> sponsorInfo = Rx<Map<String, dynamic>?>(null);
  RxMap<String, Map<String, dynamic>> referralDetails =
      <String, Map<String, dynamic>>{}.obs;

  // Type de parrainage sélectionné
  RxString selectedParrainageType = 'proche'.obs; // 'proche' ou 'entreprise'

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
      _updateReferralDetails(sponsorship);
    });

    // Vérifier si l'utilisateur a un parrain
    await _checkForSponsor(uid);
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

  void _updateReferralDetails(Sponsorship? sponsorship) async {
    if (sponsorship == null) {
      referralDetails.clear();
      activeReferrals.value = 0;
      pendingReferrals.value = 0;
      totalEarnings.value = 0;
      return;
    }

    referralDetails.clear();
    int active = 0;
    int pending = 0;

    // Utiliser les nouvelles données du modèle
    totalEarnings.value = sponsorship.totalEarnings;

    for (String email in sponsorship.sponsoredEmails) {
      try {
        final detail = sponsorship.sponsorshipDetails[email.toLowerCase()];

        if (detail != null) {
          // L'utilisateur existe dans les détails
          referralDetails[email] = {
            'isActive': detail.isActive,
            'earnings': detail.totalEarnings,
            'joinDate': detail.joinDate != null
                ? _formatDate(Timestamp.fromDate(detail.joinDate!))
                : '',
            'name': await _getUserNameByEmail(email),
            'userType': detail.userType,
            'hasPaid': detail.hasPaid,
            'hasAcceptedCGU': detail.hasAcceptedCGU,
            'userId': detail.userId,
          };

          if (detail.isActive) {
            active++;
          } else {
            pending++;
          }
        } else {
          // Utilisateur pas encore inscrit ou détails non disponibles
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
            final isActive = userData['isEnable'] ?? false;

            referralDetails[email] = {
              'isActive': isActive,
              'earnings': 0,
              'joinDate': _formatDate(userData['created_at']),
              'name': userData['name'] ?? '',
              'userType': await _getUserTypeNameById(userData['user_type_id']),
              'hasPaid': false,
              'hasAcceptedCGU': false,
              'userId': userId,
            };

            if (isActive) {
              active++;
            } else {
              pending++;
            }
          } else {
            // Utilisateur pas encore inscrit
            referralDetails[email] = {
              'isActive': false,
              'earnings': 0,
              'joinDate': '',
              'name': '',
              'userType': '',
              'hasPaid': false,
              'hasAcceptedCGU': false,
              'userId': '',
            };
            pending++;
          }
        }
      } catch (e) {
        print(
            'Erreur lors de la mise à jour des détails du filleul $email: $e');
      }
    }

    activeReferrals.value = active;
    pendingReferrals.value = pending;
  }

  Future<String> _getUserNameByEmail(String email) async {
    try {
      final userQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.data()['name'] ?? '';
      }
    } catch (e) {
      print('Erreur _getUserNameByEmail: $e');
    }
    return '';
  }

  Future<String> _getUserTypeNameById(String userTypeId) async {
    try {
      final typeDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .doc(userTypeId)
          .get();

      if (typeDoc.exists) {
        return typeDoc.data()?['name'] ?? '';
      }
    } catch (e) {
      print('Erreur _getUserTypeNameById: $e');
    }
    return '';
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

  void shareReferralLink() {
    final link =
        'https://app.ventemoi.fr/#/register?code=${referralCode.value}';
    Clipboard.setData(ClipboardData(text: link));
    UniquesControllers().data.snackbar(
          'Lien copié !',
          'Le lien de parrainage a été copié dans le presse-papier',
          false,
        );
  }

  void shareReferralCode() {
    // Au lieu de partager, on ouvre le bottom sheet pour envoyer un email
    showParrainageTypeDialog();
  }

  // Dialog pour choisir le type de parrainage
  void showParrainageTypeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir le type de parrainage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Option 1 : Parrainer un proche
              InkWell(
                onTap: () {
                  Get.back();
                  selectedParrainageType.value = 'proche';
                  openCreateUserBottomSheet();
                },
                child: Container(
                  padding: EdgeInsets.all(
                    UniquesControllers().data.baseSpace * 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parrainer un proche',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gagnez 50 points sur tous ses achats',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Option 2 : Parrainer une entreprise
              InkWell(
                onTap: () {
                  Get.back();
                  selectedParrainageType.value = 'entreprise';
                  openCreateUserBottomSheet();
                },
                child: Container(
                  padding: EdgeInsets.all(
                    UniquesControllers().data.baseSpace * 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parrainer une entreprise',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gagnez 100 points sur son adhésion',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> removeReferral(String email) async {
    if (sponsorshipDocId == null) return;

    try {
      // Récupérer le document actuel
      final docRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc(sponsorshipDocId!);

      final docSnap = await docRef.get();
      if (!docSnap.exists) return;

      final sponsorship = Sponsorship.fromDocument(docSnap);

      // Retirer l'email de la liste
      final updatedEmails = List<String>.from(sponsorship.sponsoredEmails);
      updatedEmails.remove(email);

      // Retirer les détails
      final updatedDetails =
          Map<String, SponsorshipDetail>.from(sponsorship.sponsorshipDetails);
      final removedDetail = updatedDetails.remove(email.toLowerCase());

      // Recalculer le total des gains
      int newTotalEarnings = 0;
      updatedDetails.forEach((_, detail) {
        newTotalEarnings += detail.totalEarnings;
      });

      // Mettre à jour le document
      await docRef.update({
        'sponsored_emails': updatedEmails,
        'sponsorship_details':
            updatedDetails.map((key, value) => MapEntry(key, value.toMap())),
        'total_earnings': newTotalEarnings,
        'updated_at': FieldValue.serverTimestamp(),
      });

      referralDetails.remove(email);

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

      if (userSnap.docs.isNotEmpty &&
          selectedParrainageType.value == 'proche') {
        // L'utilisateur existe déjà et on parraine un proche
        UniquesControllers().data.snackbar(
              'Information',
              'Cet utilisateur possède déjà un compte.',
              true,
            );
        return;
      }

      // Ajouter l'email à la liste des parrainés (sans créer de compte)
      await _addSponsoredEmailToList(emailToSponsor);

      // Envoyer l'email d'invitation approprié
      if (selectedParrainageType.value == 'entreprise') {
        await sendEnterpriseReferralInvitationEmail(
          toEmail: emailToSponsor,
          sponsorName:
              UniquesControllers().data.firebaseAuth.currentUser?.displayName ??
                  UniquesControllers().data.firebaseAuth.currentUser?.email ??
                  'Un partenaire',
          referralCode: referralCode.value,
        );
      } else {
        await sendReferralInvitationEmail(
          toEmail: emailToSponsor,
          sponsorName:
              UniquesControllers().data.firebaseAuth.currentUser?.displayName ??
                  UniquesControllers().data.firebaseAuth.currentUser?.email ??
                  'Un ami',
          referralCode: referralCode.value,
        );
      }

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

  // Envoyer l'email d'invitation de parrainage pour un proche
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
      </div>

      <p>
        <strong>Pourquoi rejoindre VenteMoi ?</strong>
      </p>
      <ul style="line-height: 1.8;">
        <li>🛍️ Des réductions exclusives chez nos commerçants partenaires</li>
        <li>❤️ La possibilité de soutenir des associations locales</li>
        <li>🎁 Des bons d'achat à utiliser dans vos boutiques préférées</li>
        <li>🤝 <strong>Devenez parrain à votre tour</strong> et gagnez des points !</li>
      </ul>

      <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h4 style="color: #1890ff; margin-top: 0;">💡 Comment fonctionne le parrainage ?</h4>
        <p style="margin: 10px 0;">En devenant membre, vous pourrez aussi parrainer vos proches et gagner :</p>
        <ul style="margin: 10px 0; padding-left: 20px;">
          <li><strong>50 points</strong> sur tous les achats de vos filleuls particuliers</li>
          <li><strong>100 points</strong> pour chaque entreprise/boutique parrainée qui s'inscrit</li>
        </ul>
        <p style="margin: 10px 0; font-style: italic;">
          Plus vous parrainez, plus vous gagnez de points à utiliser chez nos partenaires !
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/register?code=$referralCode" class="button">
          Je m'inscris maintenant
        </a>
      </div>

      <div class="divider"></div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Comment utiliser votre code ?</strong><br>
        Lors de votre inscription, le code <strong>$referralCode</strong> sera automatiquement appliqué
        si vous utilisez le lien ci-dessus, ou vous pouvez l'entrer manuellement.
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🎁 $sponsorName vous invite sur VenteMoi !',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Envoyer l'email d'invitation de parrainage pour une entreprise
  Future<void> sendEnterpriseReferralInvitationEmail({
    required String toEmail,
    required String sponsorName,
    required String referralCode,
  }) async {
    final content = '''
      <h2>🚀 Développez votre activité avec VenteMoi !</h2>

      <p>
        Bonjour,<br><br>
        <strong>$sponsorName</strong> vous recommande VenteMoi, la plateforme digitale
        qui booste votre visibilité et vos ventes localement.
      </p>

      <div class="highlight-box">
        <h3>Votre code partenaire exclusif</h3>
        <div class="code-box">$referralCode</div>
        <p style="margin-top: 10px; color: #666;">
          Utilisez ce code lors de votre inscription
        </p>
      </div>

      <p>
        <strong>Pourquoi rejoindre VenteMoi en tant que professionnel ?</strong>
      </p>
      <ul style="line-height: 1.8;">
        <li>📱 <strong>Une vitrine digitale complète</strong> avec vidéo de présentation</li>
        <li>🎯 <strong>Visibilité accrue</strong> auprès de clients locaux qualifiés</li>
        <li>💳 <strong>Système de bons d'achat</strong> qui fidélise vos clients</li>
        <li>📊 <strong>Statistiques détaillées</strong> sur vos performances</li>
        <li>🎁 <strong>16 bons cadeaux de 50€</strong> offerts pour démarrer</li>
        <li>🤝 <strong>Programme ambassadeur</strong> : 100€ pour chaque commerce parrainé</li>
      </ul>

      <div style="background: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h4 style="color: #0369a1; margin-top: 0;">💰 Offre de lancement exclusive</h4>
        <table style="width: 100%; margin: 10px 0;">
          <tr>
            <td style="padding: 8px 0;"><strong>1ère année :</strong></td>
            <td style="padding: 8px 0; text-align: right;">
              <span style="color: #0369a1; font-weight: bold;">870€ HT</span>
              <span style="font-size: 12px; color: #666;">(adhésion + vidéo + cotisation)</span>
            </td>
          </tr>
          <tr>
            <td style="padding: 8px 0;"><strong>Années suivantes :</strong></td>
            <td style="padding: 8px 0; text-align: right;">
              <span style="color: #0369a1; font-weight: bold;">540€ HT/an</span>
            </td>
          </tr>
        </table>
        <p style="margin: 10px 0 0 0; font-size: 14px; color: #0369a1;">
          ✅ Sans engagement après la première année
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/register?code=$referralCode" class="button">
          Découvrir VenteMoi Pro
        </a>
      </div>

      <div class="divider"></div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Des questions ?</strong><br>
        Notre équipe est à votre disposition au
        <a href="mailto:frederic.trabeco@gmail.com">frederic.trabeco@gmail.com</a>
        pour vous accompagner dans votre inscription.
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🚀 $sponsorName vous recommande VenteMoi Pro',
      htmlBody: buildModernMailHtml(content),
    );
  }

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
        'sponsorship_details': {},
        'total_earnings': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
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
        'updated_at': FieldValue.serverTimestamp(),
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
              selectedParrainageType.value == 'entreprise'
                  ? 'Invitez une entreprise à rejoindre VenteMoi'
                  : 'Invitez vos proches à rejoindre VenteMoi',
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
              labelText: selectedParrainageType.value == 'entreprise'
                  ? 'Email de l\'entreprise'
                  : 'Email du filleul',
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
                color: selectedParrainageType.value == 'entreprise'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedParrainageType.value == 'entreprise'
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: selectedParrainageType.value == 'entreprise'
                            ? Colors.green
                            : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Votre récompense',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selectedParrainageType.value == 'entreprise'
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedParrainageType.value == 'entreprise'
                        ? '• 100 points à l\'adhésion de l\'entreprise'
                        : '• 50 points sur tous les achats du filleul',
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedParrainageType.value == 'entreprise'
                          ? Colors.green[700]
                          : Colors.blue[700],
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
      selectedParrainageType.value == 'entreprise'
          ? 'Parrainer une entreprise'
          : 'Parrainer un proche',
      actionName: 'Envoyer l\'invitation',
      actionIcon: Icons.send_rounded,
    );
  }
}
