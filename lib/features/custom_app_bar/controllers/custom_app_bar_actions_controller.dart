import 'dart:async';

import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomAppBarActionsController extends GetxController {
  static CustomAppBarActionsController get instance => Get.find();
  
  // Points
  RxInt realPoints = 0.obs; // points confirmés
  RxInt pendingPoints = 0.obs; // points en attente

  // Infos Boutique
  RxBool isBoutique = false.obs;
  RxInt couponsRestants = 0.obs;
  RxInt couponsPending = 0.obs; // bons en attente

  // Administrateur ?
  RxBool isAdmin = false.obs;

  StreamSubscription<int>? _walletSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _couponsSub;
  StreamSubscription<int>? _couponsPendingSub;

  @override
  void onInit() {
    super.onInit();

    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) {
      // CustomAppBarActionsController: uid is null
      return;
    }

    // CustomAppBarActionsController: Initializing with uid

    _determineUserType(uid);

    // Souscrire aux streams
    _walletSub = _walletStream(uid).listen((pts) {
      // Points updated: $pts
      realPoints.value = pts;
    });
    _pendingSub = _pendingPointsStream(uid).listen((sum) {
      // Pending points updated: $sum
      pendingPoints.value = sum;
    });
    _couponsSub = _couponsStream(uid).listen((val) {
      // Coupons updated: $val
      couponsRestants.value = val;
    });
    _couponsPendingSub = _couponsPendingStream(uid).listen((val) {
      // Pending coupons updated: $val
      couponsPending.value = val;
    });
    
    // Force un refresh immédiat au cas où les streams ne fonctionnent pas
    Future.delayed(const Duration(milliseconds: 500), () {
      refreshWallet();
    });
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    _pendingSub?.cancel();
    _couponsSub?.cancel();
    _couponsPendingSub?.cancel();
    super.onClose();
  }

  // Méthode pour forcer le rechargement
  Future<void> refreshWallet() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    // Force refresh wallet for user: $uid

    try {
      // Charger directement les points
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (walletQuery.docs.isNotEmpty) {
        final data = walletQuery.docs.first.data();
        final points = data['points'] ?? 0;
        final coupons = data['coupons'] ?? 0;
        // Direct wallet data
        realPoints.value = points;
        couponsRestants.value = coupons;
        // Updated: points and coupons
      } else {
        // No wallet found in direct query
      }
    } catch (e) {
      // Error refreshing wallet: $e
    }
  }

  Future<void> _determineUserType(String uid) async {
    final userDoc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final userTypeId = data['user_type_id'] ?? '';

    if (userTypeId.isEmpty) return;

    final typeDoc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();
    if (!typeDoc.exists) return;

    final tData = typeDoc.data()!;
    final name = (tData['name'] ?? '').toString().toLowerCase();

    if (name == 'boutique') {
      isBoutique.value = true;
    } else if (name == 'administrateur') {
      isAdmin.value = true;
    } else if (name == 'sponsor') {
      // Les sponsors sont un type d'utilisateur spécial
      // On s'assure qu'ils peuvent voir leurs points
    }
  }

  // --- Streams points
  Stream<int> _walletStream(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      // Wallet stream - docs found
      if (snap.docs.isEmpty) {
        // No wallet found for user
        return 0;
      }
      final data = snap.docs.first.data();
      // Wallet data retrieved
      final points = data['points'] ?? 0;
      // Points in wallet retrieved
      return points;
    });
  }

  Stream<int> _pendingPointsStream(String uid) {
    // Utiliser uniquement points_attributions pour les points en attente
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_attributions')
        .where('target_id', isEqualTo: uid)
        .where('validated', isEqualTo: false)
        .snapshots()
        .map((snap) {
      var sum = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawPoints = data['points'] ?? 0;
        sum += (rawPoints as num).toInt();
      }
      return sum;
    });
  }

  // --- Streams coupons
  Stream<int> _couponsStream(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      // Coupons stream - docs found
      if (snap.docs.isEmpty) {
        // No wallet found for coupons
        return 0;
      }
      final data = snap.docs.first.data();
      final coupons = data['coupons'] ?? 0;
      // Coupons in wallet retrieved
      return coupons;
    });
  }

  Stream<int> _couponsPendingStream(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_requests')
        .where('user_id', isEqualTo: uid)
        .where('isValidated', isEqualTo: false)
        .snapshots()
        .map((snap) {
      var total = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final nb = d['coupons_count'] ?? 0;
        total += (nb as num).toInt();
      }
      return total;
    });
  }

  // Méthode pour forcer le rafraîchissement des données
  Future<void> refreshWalletData() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Récupérer directement les données du wallet
      final walletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (walletSnap.docs.isNotEmpty) {
        final walletData = walletSnap.docs.first.data();
        realPoints.value = walletData['points'] ?? 0;
        couponsRestants.value = walletData['coupons'] ?? 0;
      }

      // Récupérer les points en attente
      final pendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_attributions')
          .where('target_id', isEqualTo: uid)
          .where('validated', isEqualTo: false)
          .get();

      var pendingSum = 0;
      for (final doc in pendingSnap.docs) {
        final rawPoints = doc.data()['points'] ?? 0;
        pendingSum += (rawPoints as num).toInt();
      }
      pendingPoints.value = pendingSum;

      // Récupérer les coupons en attente
      final couponsPendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_requests')
          .where('user_id', isEqualTo: uid)
          .where('isValidated', isEqualTo: false)
          .get();

      var couponsPendingTotal = 0;
      for (final doc in couponsPendingSnap.docs) {
        final nb = doc.data()['coupons_count'] ?? 0;
        couponsPendingTotal += (nb as num).toInt();
      }
      couponsPending.value = couponsPendingTotal;
    } catch (e) {
      // Erreur lors du rafraîchissement des données wallet
    }
  }

  // Méthode statique pour notifier tous les contrôleurs actifs
  static void notifyAllControllers() {
    if (Get.isRegistered<CustomAppBarActionsController>()) {
      final controller = Get.find<CustomAppBarActionsController>();
      controller.refreshWalletData();
    }
  }

  // Déconnexion
  void logout() {
    UniquesControllers().data.firebaseAuth.signOut();
    Get.offAllNamed('/login');
  }
}
