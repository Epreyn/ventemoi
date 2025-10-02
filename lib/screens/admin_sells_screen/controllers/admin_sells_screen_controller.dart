import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';

class AdminSellsScreenController extends GetxController with ControllerMixin {
  // ---------------------------------------------------------------------------
  // Configuration de base
  // ---------------------------------------------------------------------------
  String pageTitle = 'VENTES';
  String customBottomAppBarTag = 'admin-sells-bottom-app-bar';

  // ---------------------------------------------------------------------------
  // Données principales
  // ---------------------------------------------------------------------------
  // Liste complète des achats
  final RxList<Purchase> purchases = <Purchase>[].obs;

  // ---------------------------------------------------------------------------
  // Recherche et filtrage
  // ---------------------------------------------------------------------------
  final RxString searchText = ''.obs;
  final RxString filterReclaimed =
      'all'.obs; // all, reclaimed, pending, donations

  // ---------------------------------------------------------------------------
  // Tri
  // ---------------------------------------------------------------------------
  final RxInt sortColumnIndex =
      3.obs; // 0=Acheteur, 1=Vendeur, 2=Montant, 3=Date
  final RxBool sortAscending = false.obs; // Plus récent d'abord par défaut

  // ---------------------------------------------------------------------------
  // Cache pour optimisation
  // ---------------------------------------------------------------------------
  // Cache des noms d'utilisateurs pour éviter les requêtes répétées
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> userEmailCache = <String, String>{}.obs;

  // Cache combiné pour les participants (buyerId_sellerId -> {buyer, seller})
  final RxMap<String, Map<String, String>> participantCache =
      <String, Map<String, String>>{}.obs;

  // ---------------------------------------------------------------------------
  // Gestion des streams
  // ---------------------------------------------------------------------------
  StreamSubscription<QuerySnapshot>? _purchasesSubscription;
  StreamSubscription<QuerySnapshot>? _vouchersSubscription;

  // ---------------------------------------------------------------------------
  // Statistiques calculées
  // ---------------------------------------------------------------------------
  Map<String, int> get purchaseStats {
    final total = purchases.length;
    final donations = purchases.where((p) => p.isDonation).length;
    final sales = purchases.where((p) => !p.isDonation).length;
    final reclaimed =
        purchases.where((p) => !p.isDonation && p.isReclaimed).length;
    final pending =
        purchases.where((p) => !p.isDonation && !p.isReclaimed).length;
    final totalCoupons = purchases
        .where((p) => !p.isDonation)
        .fold<int>(0, (sum, p) => sum + p.couponsCount);
    final totalDonationPoints = purchases
        .where((p) => p.isDonation)
        .fold<int>(0, (sum, p) => sum + p.couponsCount);

    return {
      'total': total,
      'donations': donations,
      'sales': sales,
      'reclaimed': reclaimed,
      'pending': pending,
      'totalCoupons': totalCoupons,
      'totalDonationPoints': totalDonationPoints,
    };
  }

  // ---------------------------------------------------------------------------
  // Liste filtrée et triée
  // ---------------------------------------------------------------------------
  List<Purchase> get filteredPurchases {
    var filtered = purchases.toList();

    // 1. Appliquer le filtre de recherche
    if (searchText.value.isNotEmpty) {
      final search = searchText.value.toLowerCase();
      filtered = filtered.where((purchase) {
        // Recherche dans le code (seulement pour les achats)
        if (!purchase.isDonation) {
          final code = purchase.reclamationPassword.toLowerCase();
          if (code.contains(search)) return true;
        }

        // Recherche dans le montant
        final amountStr = purchase.couponsCount.toString();
        if (amountStr.contains(search)) return true;

        // Recherche dans la date
        final dateStr = _formatDate(purchase.date).toLowerCase();
        if (dateStr.contains(search)) return true;

        // Recherche dans les noms (si en cache)
        final cacheKey = '${purchase.buyerId}_${purchase.sellerId}';
        if (participantCache.containsKey(cacheKey)) {
          final names = participantCache[cacheKey]!;
          final buyerName = (names['buyer'] ?? '').toLowerCase();
          final sellerName = (names['seller'] ?? '').toLowerCase();
          if (buyerName.contains(search) || sellerName.contains(search)) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    // 2. Appliquer le filtre de statut
    switch (filterReclaimed.value) {
      case 'reclaimed':
        filtered =
            filtered.where((p) => !p.isDonation && p.isReclaimed).toList();
        break;
      case 'pending':
        filtered =
            filtered.where((p) => !p.isDonation && !p.isReclaimed).toList();
        break;
      case 'donations':
        filtered = filtered.where((p) => p.isDonation).toList();
        break;
      case 'all':
      default:
        // Pas de filtre
        break;
    }

    // 3. Appliquer le tri
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortColumnIndex.value) {
        case 0: // Acheteur/Donateur
          final aNames = participantCache['${a.buyerId}_${a.sellerId}'];
          final bNames = participantCache['${b.buyerId}_${b.sellerId}'];
          comparison =
              (aNames?['buyer'] ?? '').compareTo(bNames?['buyer'] ?? '');
          break;
        case 1: // Vendeur/Bénéficiaire
          final aNames = participantCache['${a.buyerId}_${a.sellerId}'];
          final bNames = participantCache['${b.buyerId}_${b.sellerId}'];
          comparison =
              (aNames?['seller'] ?? '').compareTo(bNames?['seller'] ?? '');
          break;
        case 2: // Montant
          comparison = a.couponsCount.compareTo(b.couponsCount);
          break;
        case 3: // Date
          comparison = a.date.compareTo(b.date);
          break;
      }

      return sortAscending.value ? comparison : -comparison;
    });

    return filtered;
  }

  // ---------------------------------------------------------------------------
  // Cycle de vie
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    _initializeDataStream();
    _setupReactiveUpdates();
  }

  @override
  void onClose() {
    _purchasesSubscription?.cancel();
    _vouchersSubscription?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Initialisation des données
  // ---------------------------------------------------------------------------
  void _initializeDataStream() {
    // Variables pour stocker les dernières valeurs
    List<Purchase> latestPurchasesList = [];
    List<Purchase> latestVouchersList = [];

    // Stream pour les achats classiques (purchases)
    _purchasesSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('purchases')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      latestPurchasesList = snapshot.docs
          .map((doc) => Purchase.fromDocumentSnapshot(doc))
          .toList();

      // Combiner les deux listes
      _updateCombinedList(latestPurchasesList, latestVouchersList);
    }, onError: (error) {
    });

    // Stream pour les bons cadeaux (vouchers)
    _vouchersSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('vouchers')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      final newVouchersList = <Purchase>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          newVouchersList.add(Purchase.fromVoucherDocument(doc.id, data));
        } catch (e) {
        }
      }
      latestVouchersList = newVouchersList;

      // Combiner les deux listes
      _updateCombinedList(latestPurchasesList, latestVouchersList);
    }, onError: (error) {
    });
  }

  void _updateCombinedList(List<Purchase> purchasesList, List<Purchase> vouchersList) {
    // Combiner les deux listes
    final combined = [...purchasesList, ...vouchersList];

    // Trier par date décroissante
    combined.sort((a, b) => b.date.compareTo(a.date));

    // Mettre à jour l'observable
    purchases.value = combined;

    // Précharger les noms pour améliorer les performances
    _preloadParticipantNames();
  }

  // ---------------------------------------------------------------------------
  // Configuration des mises à jour réactives
  // ---------------------------------------------------------------------------
  void _setupReactiveUpdates() {
    // Rafraîchir l'interface quand le cache des participants change
    ever(participantCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        purchases.refresh();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Méthodes de recherche et filtrage
  // ---------------------------------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void onFilterChanged(String filter) {
    filterReclaimed.value = filter;
  }

  // ---------------------------------------------------------------------------
  // Méthodes de tri
  // ---------------------------------------------------------------------------
  void onSortData(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
  }

  // ---------------------------------------------------------------------------
  // Récupération des informations utilisateur
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> getParticipantNames(
      String buyerId, String sellerId) async {
    final cacheKey = '${buyerId}_${sellerId}';

    // Si déjà en cache, retourner directement
    if (participantCache.containsKey(cacheKey) &&
        participantCache[cacheKey]!['buyer'] != '...' &&
        participantCache[cacheKey]!['seller'] != '...') {
      return participantCache[cacheKey]!;
    }

    // Mettre des placeholders pendant le chargement
    participantCache[cacheKey] = {
      'buyer': '...',
      'seller': '...',
    };

    try {
      // Récupérer les informations des utilisateurs
      final results = await Future.wait([
        _getUserInfo(buyerId),
        _getSellerInfo(sellerId),
      ]);

      final names = {
        'buyer': results[0]['name'] ?? 'Inconnu',
        'seller': results[1]['name'] ?? 'Inconnu',
      };

      // Mettre à jour le cache après le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        participantCache[cacheKey] = names;
      });

      return names;
    } catch (e) {
      final errorNames = {
        'buyer': 'Erreur',
        'seller': 'Erreur',
      };

      WidgetsBinding.instance.addPostFrameCallback((_) {
        participantCache[cacheKey] = errorNames;
      });

      return errorNames;
    }
  }

  // ---------------------------------------------------------------------------
  // Récupération d'un utilisateur individuel
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> _getUserInfo(String userId) async {
    if (userId.isEmpty) {
      return {'name': 'Inconnu', 'email': 'inconnu@example.com'};
    }

    try {
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return {
          'name': 'Utilisateur supprimé',
          'email': 'supprime@example.com'
        };
      }

      final data = doc.data()!;
      return {
        'name': (data['name'] ??
                data['display_name'] ??
                data['company_name'] ??
                'Sans nom')
            .toString(),
        'email': (data['email'] ?? 'sans-email@example.com').toString(),
      };
    } catch (e) {
      return {'name': 'Erreur', 'email': 'erreur@example.com'};
    }
  }

  // ---------------------------------------------------------------------------
  // Récupération des informations du vendeur (établissement)
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> _getSellerInfo(String sellerId) async {
    if (sellerId.isEmpty) {
      return {'name': 'Inconnu', 'email': 'inconnu@example.com'};
    }

    try {
      // D'abord essayer de récupérer directement l'établissement par son ID
      final establishmentDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(sellerId)
          .get();

      if (establishmentDoc.exists) {
        final establishmentData = establishmentDoc.data()!;
        return {
          'name': (establishmentData['name'] ?? 'Établissement sans nom')
              .toString(),
          'email': (establishmentData['email'] ?? '').toString(),
        };
      }

      // Si ce n'est pas un ID d'établissement, chercher par user_id
      final establishmentQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (establishmentQuery.docs.isNotEmpty) {
        final establishmentData = establishmentQuery.docs.first.data();
        return {
          'name':
              (establishmentData['name'] ?? 'Établissement inconnu').toString(),
          'email': (establishmentData['email'] ?? '').toString(),
        };
      }

      // Si pas d'établissement, récupérer l'utilisateur
      return _getUserInfo(sellerId);
    } catch (e) {
      return {'name': 'Erreur', 'email': 'erreur@example.com'};
    }
  }

  // ---------------------------------------------------------------------------
  // Préchargement des noms pour optimisation
  // ---------------------------------------------------------------------------
  void _preloadParticipantNames() {
    // Collecter tous les IDs uniques
    final uniquePairs = <String>{};

    for (final purchase in purchases) {
      final cacheKey = '${purchase.buyerId}_${purchase.sellerId}';
      if (!participantCache.containsKey(cacheKey)) {
        uniquePairs.add(cacheKey);
      }
    }

    // Charger les noms en batch (limité pour éviter la surcharge)
    int count = 0;
    for (final pair in uniquePairs) {
      if (count >= 10) break; // Limiter à 10 chargements simultanés

      final ids = pair.split('_');
      if (ids.length == 2) {
        getParticipantNames(ids[0], ids[1]);
        count++;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Méthodes utilitaires
  // ---------------------------------------------------------------------------
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Actions sur les ventes
  // ---------------------------------------------------------------------------
  Future<void> markAsReclaimed(String purchaseId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('purchases')
          .doc(purchaseId)
          .update({'isReclaimed': true});

      UniquesControllers().data.snackbar(
            'Succès',
            'Vente marquée comme réclamée',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de mettre à jour la vente',
            true,
          );
    }
  }

  // ---------------------------------------------------------------------------
  // Export des données
  // ---------------------------------------------------------------------------
  String exportToCSV() {
    final buffer = StringBuffer();

    // En-têtes
    buffer.writeln(
        'Date,Type,Code/ID,Donateur/Acheteur,Bénéficiaire/Vendeur,Montant,Statut');

    // Données
    for (final purchase in filteredPurchases) {
      final cacheKey = '${purchase.buyerId}_${purchase.sellerId}';
      final names =
          participantCache[cacheKey] ?? {'buyer': 'N/A', 'seller': 'N/A'};

      final type = purchase.isDonation ? 'Don' : 'Achat';
      final codeOrId = purchase.isDonation
          ? purchase.id.substring(0, 8).toUpperCase()
          : purchase.reclamationPassword;
      final amount = purchase.isDonation
          ? '${purchase.couponsCount} points'
          : '${purchase.couponsCount} bons';
      final status = purchase.isDonation
          ? 'Effectué'
          : (purchase.isReclaimed ? 'Réclamée' : 'En attente');

      buffer.writeln('${_formatDateTime(purchase.date)},'
          '$type,'
          '$codeOrId,'
          '${names['buyer']},'
          '${names['seller']},'
          '$amount,'
          '$status');
    }

    return buffer.toString();
  }
}
