import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/point_attribution.dart';
import '../../../core/models/pending_points_attribution.dart';

class AdminPointsAttributionsScreenController extends GetxController
    with ControllerMixin {
  // Screen Info
  String pageTitle = 'Attributions de Points'.toUpperCase();
  String customBottomAppBarTag = 'admin-points-attributions-bottom-app-bar';

  // Tri et filtrage
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = false.obs;
  final RxString searchText = ''.obs;
  final RxString filterValidated = 'all'.obs;

  // Listes
  final RxList<PointAttribution> allAttributions = <PointAttribution>[].obs;
  final RxList<PendingPointsAttribution> pendingAttributions =
      <PendingPointsAttribution>[].obs;

  // Cache pour les noms/emails des utilisateurs
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> userEmailCache = <String, String>{}.obs;

  // Subscriptions
  StreamSubscription<List<PointAttribution>>? _attributionsSub;
  StreamSubscription<List<PendingPointsAttribution>>? _pendingSub;

  // Formulaire d'attribution
  final GlobalKey<FormState> attributionFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  final RxList<Map<String, dynamic>> emailSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxString selectedUserId = ''.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Écouter les attributions
    _attributionsSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_attributions')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PointAttribution.fromDocument(doc)).toList())
        .listen((list) {
      allAttributions.value = list;
    });

    // Écouter les attributions en attente
    _pendingSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('pending_points_attributions')
        .where('claimed', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PendingPointsAttribution.fromDocument(doc))
            .toList())
        .listen((list) {
      pendingAttributions.value = list;
    });

    // Observer les changements pour rafraîchir l'UI
    ever(userNameCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        allAttributions.refresh();
      });
    });
    ever(userEmailCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        allAttributions.refresh();
      });
    });
  }

  @override
  void onClose() {
    _attributionsSub?.cancel();
    _pendingSub?.cancel();
    emailController.dispose();
    pointsController.dispose();
    super.onClose();
  }

  // -----------------------------------------------------------------------------
  // Statistiques
  // -----------------------------------------------------------------------------
  Map<String, int> get attributionStats {
    final stats = <String, int>{
      'total': allAttributions.length,
      'totalPoints': 0,
      'validated': 0,
      'pending': 0,
    };

    for (final attribution in allAttributions) {
      stats['totalPoints'] = stats['totalPoints']! + attribution.points;
      if (attribution.validated) {
        stats['validated'] = stats['validated']! + 1;
      } else {
        stats['pending'] = stats['pending']! + 1;
      }
    }

    return stats;
  }

  // -----------------------------------------------------------------------------
  // Filtrage et tri
  // -----------------------------------------------------------------------------
  List<PointAttribution> get filteredAttributions {
    var filtered = allAttributions.toList();

    // Filtre par statut
    if (filterValidated.value == 'validated') {
      filtered = filtered.where((a) => a.validated).toList();
    } else if (filterValidated.value == 'pending') {
      filtered = filtered.where((a) => !a.validated).toList();
    }

    // Filtre par recherche
    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((a) {
        final dateStr = _formatDateForSearch(a.date).toLowerCase();
        final points = a.points.toString();
        final email = getUserEmail(a.targetId).toLowerCase();
        final name = getUserName(a.targetId).toLowerCase();
        final giverName = getUserName(a.giverId).toLowerCase();

        return dateStr.contains(query) ||
            points.contains(query) ||
            email.contains(query) ||
            name.contains(query) ||
            giverName.contains(query);
      }).toList();
    }

    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortColumnIndex.value) {
        case 0: // date
          comparison = a.date.compareTo(b.date);
          break;
        case 1: // points
          comparison = a.points.compareTo(b.points);
          break;
        case 2: // coût
          comparison = a.cost.compareTo(b.cost);
          break;
        case 3: // commission
          comparison = a.commissionPercent.compareTo(b.commissionPercent);
          break;
      }
      return sortAscending.value ? comparison : -comparison;
    });

    return filtered;
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void onSortData(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
  }

  // -----------------------------------------------------------------------------
  // Gestion des utilisateurs
  // -----------------------------------------------------------------------------
  String getUserName(String userId) {
    if (userId.isEmpty) return 'Inconnu';
    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }

    // Placeholder
    userNameCache[userId] = '...';
    userEmailCache[userId] = '...';

    // Charger depuis Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snap) {
      if (!snap.exists) {
        userNameCache[userId] = 'Inconnu';
        userEmailCache[userId] = 'Inconnu';
        return;
      }
      final data = snap.data() ?? {};
      final name = data['name'] ?? 'Sans nom';
      final email = data['email'] ?? 'Inconnu';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNameCache[userId] = name;
        userEmailCache[userId] = email;
      });
    }).catchError((_) {
      userNameCache[userId] = 'Inconnu';
      userEmailCache[userId] = 'Inconnu';
    });

    return userNameCache[userId] ?? '...';
  }

  String getUserEmail(String userId) {
    if (userId.isEmpty) return 'Inconnu';
    return userEmailCache[userId] ?? '...';
  }

  // -----------------------------------------------------------------------------
  // Validation d'attribution
  // -----------------------------------------------------------------------------
  void showValidationDialog(PointAttribution attribution) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            SizedBox(width: 12),
            Text('Valider l\'attribution'),
          ],
        ),
        content: Text(
          'Voulez-vous valider cette attribution de ${attribution.points} points ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              validateAttribution(attribution);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> validateAttribution(PointAttribution attribution) async {
    try {
      // 1) Marquer comme validée
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_attributions')
          .doc(attribution.id)
          .update({'validated': true});

      // 2) Incrémenter le wallet
      final targetWalletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: attribution.targetId)
          .limit(1)
          .get();

      if (targetWalletSnap.docs.isNotEmpty) {
        final walletId = targetWalletSnap.docs.first.id;
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc(walletId)
            .update({'points': FieldValue.increment(attribution.points)});
      }

      // 3) Gérer le parrainage (40% des points)
      await _handleSponsorshipReward(
        attribution.targetEmail.trim().toLowerCase(),
        attribution.points,
      );

      UniquesControllers()
          .data
          .snackbar('Succès', 'Attribution validée avec succès', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  Future<void> _handleSponsorshipReward(
    String targetEmail,
    int targetPoints,
  ) async {
    if (targetEmail.isEmpty || targetPoints <= 0) return;

    // Rechercher le parrain
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('sponsoredEmails', arrayContains: targetEmail)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final sponsorshipDoc = snap.docs.first;
    final sponsorData = sponsorshipDoc.data();
    final sponsorUid = sponsorData['user_id'] ?? '';
    if (sponsorUid.isEmpty) return;

    // Calculer la récompense (40% arrondi à l'inférieur)
    final reward = (targetPoints * 0.4).floor();
    if (reward <= 0) return;

    // Incrémenter le wallet du parrain
    final sponsorWalletSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: sponsorUid)
        .limit(1)
        .get();

    if (sponsorWalletSnap.docs.isEmpty) {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': sponsorUid,
        'points': reward,
        'coupons': 0,
      });
    } else {
      final sponsorWalletRef = sponsorWalletSnap.docs.first.reference;
      await sponsorWalletRef.update({
        'points': FieldValue.increment(reward),
      });
    }

    // Envoyer un mail au parrain
    final sponsorUserSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(sponsorUid)
        .get();

    if (sponsorUserSnap.exists) {
      final sponsorUserData = sponsorUserSnap.data()!;
      final sponsorEmail = (sponsorUserData['email'] ?? '').toString().trim();
      final sponsorName = (sponsorUserData['name'] ?? 'Sponsor').toString();

      if (sponsorEmail.isNotEmpty) {
        await sendSponsorshipMailForAttribution(
          sponsorName: sponsorName,
          sponsorEmail: sponsorEmail,
          filleulEmail: targetEmail,
          pointsWon: reward,
        );
      }
    }

    // Retirer l'email de la liste
    await sponsorshipDoc.reference.update({
      'sponsoredEmails': FieldValue.arrayRemove([targetEmail])
    });
  }

  // -----------------------------------------------------------------------------
  // Attribution de points (nouvelle logique avec invitation)
  // -----------------------------------------------------------------------------
  void resetAttributionForm() {
    attributionFormKey.currentState?.reset();
    emailController.clear();
    pointsController.clear();
    emailSearchResults.clear();
    selectedUserId.value = '';
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  String? validatePoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un nombre de points';
    }
    final points = int.tryParse(value.trim());
    if (points == null || points <= 0) {
      return 'Nombre de points invalide';
    }
    return null;
  }

  void onEmailChanged(String value) async {
    emailSearchResults.clear();
    if (value.length < 3) return;

    try {
      // Rechercher les utilisateurs existants
      final usersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .limit(10)
          .get();

      final results = <Map<String, dynamic>>[];
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final email = (data['email'] ?? '').toString().toLowerCase();
        if (email.contains(value.toLowerCase())) {
          results.add({
            'uid': doc.id,
            'email': email,
            'name': data['name'] ?? 'Sans nom',
          });
        }
      }
      emailSearchResults.value = results;
    } catch (e) {
      print('Erreur recherche email: $e');
    }
  }

  void selectUser(Map<String, dynamic> user) {
    selectedUserId.value = user['uid'] ?? '';
    emailController.text = user['email'] ?? '';
    emailSearchResults.clear();
  }

  Future<void> attributePoints() async {
    if (!attributionFormKey.currentState!.validate()) return;

    isProcessing.value = true;

    try {
      final email = emailController.text.trim().toLowerCase();
      final points = int.parse(pointsController.text.trim());
      final giverId = UniquesControllers().data.firebaseAuth.currentUser!.uid;

      // Vérifier si l'utilisateur existe déjà
      final existingUserSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserSnap.docs.isNotEmpty) {
        // L'utilisateur existe, créer une attribution directe
        final userId = existingUserSnap.docs.first.id;

        final docRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('points_attributions')
            .doc();

        await docRef.set({
          'giver_id': giverId,
          'target_id': userId,
          'target_email': email,
          'date': DateTime.now(),
          'cost': 0,
          'points': points,
          'commission_percent': 0,
          'commission_cost': 0,
          'validated': true,
        });

        // Incrémenter le wallet
        final walletSnap = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (walletSnap.docs.isEmpty) {
          await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('wallets')
              .doc()
              .set({
            'user_id': userId,
            'points': points,
            'coupons': 0,
          });
        } else {
          await walletSnap.docs.first.reference.update({
            'points': FieldValue.increment(points),
          });
        }

        UniquesControllers().data.snackbar(
              'Succès',
              'Points attribués à l\'utilisateur existant',
              false,
            );
      } else {
        // L'utilisateur n'existe pas, créer une attribution en attente
        final invitationToken = _generateInvitationToken();

        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('pending_points_attributions')
            .doc()
            .set({
          'email': email,
          'points': points,
          'giver_id': giverId,
          'created_at': DateTime.now(),
          'claimed': false,
          'invitation_token': invitationToken,
        });

        // Envoyer l'email d'invitation
        await _sendInvitationEmail(email, points, invitationToken);

        UniquesControllers().data.snackbar(
              'Succès',
              'Invitation envoyée avec $points points',
              false,
            );
      }

      Get.back();
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      isProcessing.value = false;
    }
  }

  String _generateInvitationToken() {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _sendInvitationEmail(
      String email, int points, String token) async {
    // Appeler votre méthode d'envoi d'email du mixin
    // Exemple:
    await sendPointsInvitationEmail(
      recipientEmail: email,
      points: points,
      invitationToken: token,
    );
  }

  // -----------------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------------
  String _formatDateForSearch(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // -----------------------------------------------------------------------------
  // Méthode pour vérifier les points en attente lors de la création de compte
  // À appeler dans le processus de création de compte
  // -----------------------------------------------------------------------------
  static Future<void> checkAndClaimPendingPoints(
      String email, String userId) async {
    try {
      final pendingSnap = await FirebaseFirestore.instance
          .collection('pending_points_attributions')
          .where('email', isEqualTo: email.toLowerCase())
          .where('claimed', isEqualTo: false)
          .get();

      if (pendingSnap.docs.isEmpty) return;

      int totalPoints = 0;
      final batch = FirebaseFirestore.instance.batch();

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
        final attributionRef =
            FirebaseFirestore.instance.collection('points_attributions').doc();
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

      // Créer ou mettre à jour le wallet
      final walletSnap = await FirebaseFirestore.instance
          .collection('wallets')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (walletSnap.docs.isEmpty) {
        final walletRef =
            FirebaseFirestore.instance.collection('wallets').doc();
        batch.set(walletRef, {
          'user_id': userId,
          'points': totalPoints,
          'coupons': 0,
        });
      } else {
        batch.update(walletSnap.docs.first.reference, {
          'points': FieldValue.increment(totalPoints),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la réclamation des points en attente: $e');
    }
  }
}
