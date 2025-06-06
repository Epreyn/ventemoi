import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';

class ClientHistoryScreenController extends GetxController
    with ControllerMixin {
  String pageTitle = 'Historique Client'.toUpperCase();
  String customBottomAppBarTag = 'client-history-bottom-app-bar';

  // On suit le wallet pour l'affichage "Points"
  RxInt userPoints = 0.obs;
  // On suit la liste d'achats
  RxList<Purchase> purchases = <Purchase>[].obs;

  // Filtres et tri
  RxString selectedFilter = 'all'.obs;
  RxString sortBy = 'date'.obs;
  RxBool sortAscending = false.obs; // Par défaut, date décroissante

  StreamSubscription<int>? _walletSub;
  StreamSubscription<List<Purchase>>? _purchasesSub;

  @override
  void onInit() {
    super.onInit();
    // Souscrire au wallet
    _walletSub = getUserWalletStream().listen((pts) {
      userPoints.value = pts;
    });
    // Souscrire à la collection 'purchases' buyer_id == currentUser
    _purchasesSub = getUserPurchasesStream().listen((list) {
      purchases.value = list;
    });
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    _purchasesSub?.cancel();
    super.onClose();
  }

  // Récupère la liste d'achats (purchases)
  Stream<List<Purchase>> getUserPurchasesStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('purchases')
        .where('buyer_id', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Purchase.fromDocument(d)).toList());
  }

  // Récupère le wallet => points
  Stream<int> getUserWalletStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return 0;
      final data = snap.docs.first.data();
      return data['points'] ?? 0;
    });
  }

  // Getter pour la liste filtrée et triée
  List<Purchase> get filteredPurchases {
    // D'abord, on filtre
    List<Purchase> filtered = purchases.toList();

    switch (selectedFilter.value) {
      case 'pending':
        filtered = filtered.where((p) => !p.isReclaimed).toList();
        break;
      case 'claimed':
        filtered = filtered.where((p) => p.isReclaimed).toList();
        break;
      case 'donations':
        filtered = filtered.where((p) => p.couponsCount == 0).toList();
        break;
      case 'all':
      default:
        // Pas de filtre
        break;
    }

    // Ensuite, on trie
    switch (sortBy.value) {
      case 'date':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount':
        filtered.sort((a, b) => a.couponsCount.compareTo(b.couponsCount));
        break;
      case 'seller':
        // Pour trier par vendeur, on devrait idéalement avoir le nom en cache
        // Pour l'instant, on trie par sellerId
        filtered.sort((a, b) => a.sellerId.compareTo(b.sellerId));
        break;
      case 'status':
        // D'abord les en attente, puis les récupérés
        filtered.sort((a, b) =>
            a.isReclaimed == b.isReclaimed ? 0 : (a.isReclaimed ? 1 : -1));
        break;
    }

    // Appliquer l'ordre
    if (!sortAscending.value) {
      filtered = filtered.reversed.toList();
    }

    return filtered;
  }

  // Méthodes pour changer les filtres et le tri
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setSortBy(String sort, bool ascending) {
    sortBy.value = sort;
    sortAscending.value = ascending;
  }
}
