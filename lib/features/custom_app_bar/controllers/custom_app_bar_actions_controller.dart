import 'dart:async';

import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomAppBarActionsController extends GetxController {
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
    if (uid == null) return;

    _determineUserType(uid);

    // Souscrire aux streams
    _walletSub = _walletStream(uid).listen((pts) {
      realPoints.value = pts;
    });
    _pendingSub = _pendingPointsStream(uid).listen((sum) {
      pendingPoints.value = sum;
    });
    _couponsSub = _couponsStream(uid).listen((val) {
      couponsRestants.value = val;
    });
    _couponsPendingSub = _couponsPendingStream(uid).listen((val) {
      couponsPending.value = val;
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
      if (snap.docs.isEmpty) return 0;
      return snap.docs.first.data()['points'] ?? 0;
    });
  }

  Stream<int> _pendingPointsStream(String uid) {
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
      if (snap.docs.isEmpty) return 0;
      return snap.docs.first.data()['coupons'] ?? 0;
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
      print('Erreur lors du rafraîchissement des données wallet: $e');
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
