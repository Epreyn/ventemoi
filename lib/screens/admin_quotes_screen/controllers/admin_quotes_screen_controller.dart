import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/models/establishement.dart';

class AdminQuotesScreenController extends GetxController with ControllerMixin {
  // Configuration de base
  String pageTitle = 'DEVIS';
  String customBottomAppBarTag = 'admin-quotes-bottom-app-bar';

  // Liste des devis
  RxList<QuoteRequest> allQuotes = <QuoteRequest>[].obs;

  // Filtres et recherche
  RxString searchText = ''.obs;
  RxString filterStatus = 'all'.obs; // all, pending, assigned, completed, cancelled
  RxString filterType = 'all'.obs; // all, renovation, construction, etc.

  // Tri
  RxInt sortColumnIndex = 3.obs; // 0=Client, 1=Type, 2=Montant, 3=Date, 4=Statut
  RxBool sortAscending = false.obs; // Plus récent d'abord par défaut

  // Cache pour les noms
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> enterpriseNameCache = <String, String>{}.obs;

  // Stream subscription
  StreamSubscription<QuerySnapshot>? _quotesSubscription;

  // Statistiques
  Map<String, dynamic> get quoteStats {
    final total = allQuotes.length;
    final pending = allQuotes.where((q) => q.status == 'pending').length;
    final assigned = allQuotes.where((q) => q.status == 'assigned').length;
    final completed = allQuotes.where((q) => q.status == 'completed').length;
    final cancelled = allQuotes.where((q) => q.status == 'cancelled').length;
    final totalAmount = allQuotes.fold<double>(
      0.0,
      (sum, q) => sum + (double.tryParse(q.estimatedBudget ?? '0') ?? 0)
    );

    return {
      'total': total,
      'pending': pending,
      'assigned': assigned,
      'completed': completed,
      'cancelled': cancelled,
      'totalAmount': totalAmount,
    };
  }

  // Liste filtrée et triée
  List<QuoteRequest> get filteredQuotes {
    var filtered = allQuotes.toList();

    // 1. Appliquer le filtre de recherche
    if (searchText.value.isNotEmpty) {
      final search = searchText.value.toLowerCase();
      filtered = filtered.where((quote) {
        // Recherche dans le nom du client
        final clientName = userNameCache[quote.userId]?.toLowerCase() ?? '';
        if (clientName.contains(search)) return true;

        // Recherche dans le type de projet
        final projectType = quote.projectType.toLowerCase();
        if (projectType.contains(search)) return true;

        // Recherche dans la description
        final description = quote.projectDescription.toLowerCase();
        if (description.contains(search)) return true;

        // Recherche dans le montant
        final amount = quote.estimatedBudget ?? '';
        if (amount.toLowerCase().contains(search)) return true;

        return false;
      }).toList();
    }

    // 2. Appliquer le filtre de statut
    if (filterStatus.value != 'all') {
      filtered = filtered.where((q) => q.status == filterStatus.value).toList();
    }

    // 3. Appliquer le filtre de type
    if (filterType.value != 'all') {
      filtered = filtered.where((q) =>
        q.projectType.toLowerCase() == filterType.value.toLowerCase()
      ).toList();
    }

    // 4. Appliquer le tri
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortColumnIndex.value) {
        case 0: // Client
          comparison = (userNameCache[a.userId] ?? '').compareTo(
            userNameCache[b.userId] ?? ''
          );
          break;
        case 1: // Type
          comparison = a.projectType.compareTo(b.projectType);
          break;
        case 2: // Montant
          final aAmount = double.tryParse(a.estimatedBudget ?? '0') ?? 0;
          final bAmount = double.tryParse(b.estimatedBudget ?? '0') ?? 0;
          comparison = aAmount.compareTo(bAmount);
          break;
        case 3: // Date
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 4: // Statut
          comparison = a.status.compareTo(b.status);
          break;
      }

      return sortAscending.value ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeDataStream();
    _setupReactiveUpdates();
  }

  @override
  void onClose() {
    _quotesSubscription?.cancel();
    super.onClose();
  }

  void _initializeDataStream() {
    _quotesSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('quote_requests')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      final quotes = snapshot.docs
          .map((doc) => QuoteRequest.fromFirestore(doc))
          .toList();

      allQuotes.value = quotes;

      // Précharger les noms des clients
      _preloadUserNames();
    }, onError: (error) {
    });
  }

  void _setupReactiveUpdates() {
    // Rafraîchir quand le cache change
    ever(userNameCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        allQuotes.refresh();
      });
    });
  }

  void _preloadUserNames() {
    final uniqueUserIds = <String>{};

    for (final quote in allQuotes) {
      if (!userNameCache.containsKey(quote.userId)) {
        uniqueUserIds.add(quote.userId);
      }
      if (quote.assignedTo != null && !enterpriseNameCache.containsKey(quote.assignedTo!)) {
        uniqueUserIds.add(quote.assignedTo!);
      }
    }

    // Charger les noms en batch (limité)
    int count = 0;
    for (final userId in uniqueUserIds) {
      if (count >= 10) break;
      getUserName(userId);
      count++;
    }
  }

  String getUserName(String userId) {
    if (userId.isEmpty) return 'Inconnu';

    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }

    // Placeholder pendant le chargement
    userNameCache[userId] = '...';

    // Charger depuis Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snap) {
      String name = 'Inconnu';
      if (snap.exists) {
        final data = snap.data()!;
        name = data['name'] ?? data['userName'] ?? data['email'] ?? 'Anonyme';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNameCache[userId] = name;
      });
    });

    return '...';
  }

  String getEnterpriseName(String enterpriseId) {
    if (enterpriseId.isEmpty) return 'Non assigné';

    if (enterpriseNameCache.containsKey(enterpriseId)) {
      return enterpriseNameCache[enterpriseId]!;
    }

    // Placeholder pendant le chargement
    enterpriseNameCache[enterpriseId] = '...';

    // Charger depuis Firestore
    FirebaseFirestore.instance
        .collection('establishments')
        .doc(enterpriseId)
        .get()
        .then((snap) {
      String name = 'Inconnu';
      if (snap.exists) {
        final data = snap.data()!;
        name = data['name'] ?? 'Entreprise inconnue';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        enterpriseNameCache[enterpriseId] = name;
      });
    });

    return '...';
  }

  // Actions sur les devis
  Future<void> updateQuoteStatus(String quoteId, String newStatus) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({'status': newStatus});

      UniquesControllers().data.snackbar(
        'Succès',
        'Statut du devis mis à jour',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de mettre à jour le statut',
        true,
      );
    }
  }

  Future<void> assignQuoteToEnterprise(String quoteId, String enterpriseId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'assigned_to': enterpriseId,
        'status': 'assigned',
        'assigned_at': FieldValue.serverTimestamp(),
      });

      UniquesControllers().data.snackbar(
        'Succès',
        'Devis assigné à l\'entreprise',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'assigner le devis',
        true,
      );
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .delete();

      UniquesControllers().data.snackbar(
        'Succès',
        'Devis supprimé',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de supprimer le devis',
        true,
      );
    }
  }

  // Méthodes de recherche et filtrage
  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void onStatusFilterChanged(String status) {
    filterStatus.value = status;
  }

  void onTypeFilterChanged(String type) {
    filterType.value = type;
  }

  void onSortData(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assigné';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}