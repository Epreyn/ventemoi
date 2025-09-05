import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class AdminEstablishmentsScreenController extends GetxController
    with ControllerMixin {
  // Titre / BottomBar
  String pageTitle = 'Admin - Établissements'.toUpperCase();
  String customBottomAppBarTag = 'admin-establishments-bottom-app-bar';

  // Liste brute des établissements
  RxList<Establishment> allEstablishments = <Establishment>[].obs;

  // Texte de recherche
  RxString searchText = ''.obs;

  // Tri
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  // Statistiques par type
  final RxMap<String, int> statsByType = <String, int>{}.obs;

  // Subscription Firestore
  StreamSubscription<List<Establishment>>? _estabSub;
  StreamSubscription<QuerySnapshot>? _usersSub;

  // Cache pour les noms et types
  final Map<String, String> _ownerNamesCache = {};
  final Map<String, String> _ownerTypesCache = {};
  final Map<String, String> _categoryNamesCache = {};

  @override
  void onInit() {
    super.onInit();

    // Écouter les établissements
    _estabSub = _getAllEstablishmentsStream().listen((list) {
      allEstablishments.value = list;
      _sortEstablishments();
      _updateStatistics(list);
    });

    // Écouter les utilisateurs pour le cache et les stats
    _usersSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .snapshots()
        .listen((snap) {
      _updateUserCache(snap.docs);
    });

    ever(searchText, (_) => _sortEstablishments());
  }

  @override
  void onClose() {
    _estabSub?.cancel();
    _usersSub?.cancel();
    super.onClose();
  }

  // --------------------------------------------------------------------------------
  // Stream de tous les Establishment
  // --------------------------------------------------------------------------------
  Stream<List<Establishment>> _getAllEstablishmentsStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Establishment.fromDocument(doc)).toList());
  }

  // --------------------------------------------------------------------------------
  // Mise à jour du cache utilisateurs
  // --------------------------------------------------------------------------------
  void _updateUserCache(List<QueryDocumentSnapshot> userDocs) async {
    for (final doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = doc.id;
      final userName = data['name'] ?? 'Sans nom';
      final userTypeId = data['user_type_id'] ?? '';

      _ownerNamesCache[userId] = userName;

      if (userTypeId.isNotEmpty) {
        final typeDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('user_types')
            .doc(userTypeId)
            .get();

        if (typeDoc.exists) {
          final typeName = typeDoc.data()?['name'] ?? '';
          _ownerTypesCache[userId] = typeName;
        }
      }
    }

    // Mettre à jour les stats après mise à jour du cache
    _updateStatistics(allEstablishments);
  }

  // --------------------------------------------------------------------------------
  // Mise à jour des statistiques
  // --------------------------------------------------------------------------------
  void _updateStatistics(List<Establishment> establishments) async {
    final Map<String, int> stats = {
      'particulier': 0,
      'partenaire': 0,
      'entreprise': 0,
      'boutique': 0,
      'association': 0,
      'professionnel': 0,
      'inconnu': 0,
    };

    for (final est in establishments) {
      final ownerType = _ownerTypesCache[est.userId]?.toLowerCase() ?? '';

      if (ownerType.isEmpty) {
        // Si pas dans le cache, essayer de récupérer
        final type = await getOwnerType(est.userId);
        if (type.isNotEmpty) {
          _ownerTypesCache[est.userId] = type;
          stats[type.toLowerCase()] = (stats[type.toLowerCase()] ?? 0) + 1;
        } else {
          stats['inconnu'] = (stats['inconnu'] ?? 0) + 1;
        }
      } else {
        stats[ownerType] = (stats[ownerType] ?? 0) + 1;
      }
    }

    statsByType.value = stats;
    
    // Calculer les statistiques spécifiques aux associations
    _updateAssociationStats(establishments);
  }
  
  // Nouvelle méthode pour calculer les stats des associations
  void _updateAssociationStats(List<Establishment> establishments) async {
    int associationsVisibles = 0;
    int associationsEnAttente = 0;
    int associationsSansAffilies = 0;
    
    for (final est in establishments) {
      final ownerType = _ownerTypesCache[est.userId]?.toLowerCase() ?? '';
      
      if (ownerType == 'association') {
        if (est.isVisible) {
          associationsVisibles++;
        } else if (est.affiliatesCount >= 15) {
          associationsEnAttente++;
        } else {
          associationsSansAffilies++;
        }
      }
    }
    
    // Stocker ces stats pour les afficher si besoin
    // (vous pouvez créer des observables supplémentaires si nécessaire)
  }

  // --------------------------------------------------------------------------------
  // Getter filteredEstablishments (applique la recherche)
  // --------------------------------------------------------------------------------
  List<Establishment> get filteredEstablishments {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) {
      return allEstablishments;
    }
    return allEstablishments.where((est) {
      final name = est.name.toLowerCase();
      final desc = est.description.toLowerCase();
      final address = est.address.toLowerCase();
      final email = est.email.toLowerCase();
      final phone = est.telephone.toLowerCase();
      final ownerName = (_ownerNamesCache[est.userId] ?? '').toLowerCase();

      return name.contains(query) ||
          desc.contains(query) ||
          address.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          ownerName.contains(query);
    }).toList();
  }

  // --------------------------------------------------------------------------------
  // Méthodes de tri
  // --------------------------------------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortEstablishments();
  }

  void _sortEstablishments() {
    final sorted = allEstablishments.toList();
    sorted.sort(_compareEst);
    allEstablishments.value =
        sortAscending.value ? sorted : sorted.reversed.toList();
  }

  int _compareEst(Establishment a, Establishment b) {
    switch (sortColumnIndex.value) {
      case 0: // Tri par nom d'établissement
        return a.name.compareTo(b.name);
      case 1: // Tri par nom propriétaire
        final ownerA = _ownerNamesCache[a.userId] ?? '';
        final ownerB = _ownerNamesCache[b.userId] ?? '';
        return ownerA.compareTo(ownerB);
      case 2: // Tri par email
        return a.email.compareTo(b.email);
      default:
        return 0;
    }
  }

  // --------------------------------------------------------------------------------
  // Récupérer le nom du propriétaire (avec cache)
  // --------------------------------------------------------------------------------
  Future<String> getOwnerName(String userId) async {
    if (userId.isEmpty) return 'Inconnu';

    // Vérifier le cache d'abord
    if (_ownerNamesCache.containsKey(userId)) {
      return _ownerNamesCache[userId]!;
    }

    // Si pas dans le cache, récupérer de Firestore
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();

    if (!snap.exists) {
      _ownerNamesCache[userId] = 'Inconnu';
      return 'Inconnu';
    }

    final data = snap.data()!;
    final ownerName = data['name'] ?? 'Sans nom';
    _ownerNamesCache[userId] = ownerName;
    return ownerName;
  }

  // --------------------------------------------------------------------------------
  // Récupérer le type du propriétaire (avec cache)
  // --------------------------------------------------------------------------------
  Future<String> getOwnerType(String userId) async {
    if (userId.isEmpty) return '';

    // Vérifier le cache d'abord
    if (_ownerTypesCache.containsKey(userId)) {
      return _ownerTypesCache[userId]!;
    }

    // Si pas dans le cache, récupérer de Firestore
    final userSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();

    if (!userSnap.exists) return '';

    final userData = userSnap.data();
    final userTypeId = userData?['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';

    final typeSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();

    if (!typeSnap.exists) return '';

    final typeName = typeSnap.data()?['name'] ?? '';
    _ownerTypesCache[userId] = typeName;
    return typeName;
  }

  // --------------------------------------------------------------------------------
  // Récupérer le nom de la catégorie (avec cache)
  // --------------------------------------------------------------------------------
  Future<String> getCategoryName(
      String catId, List<String>? enterpriseCatsIds) async {
    // Pour les catégories entreprise (plusieurs)
    if (enterpriseCatsIds != null && enterpriseCatsIds.isNotEmpty) {
      final catNames = <String>[];
      for (final cId in enterpriseCatsIds) {
        final cacheKey = 'enterprise_$cId';

        if (_categoryNamesCache.containsKey(cacheKey)) {
          catNames.add(_categoryNamesCache[cacheKey]!);
        } else {
          final catSnap = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('enterprise_categories')
              .doc(cId)
              .get();

          if (catSnap.exists) {
            final catData = catSnap.data();
            final catName = catData?['name'] ?? 'N/A';
            _categoryNamesCache[cacheKey] = catName;
            catNames.add(catName);
          }
        }
      }
      return catNames.join(', ');
    }

    // Pour les catégories normales
    if (catId.isEmpty) return 'N/A';

    final cacheKey = 'normal_$catId';
    if (_categoryNamesCache.containsKey(cacheKey)) {
      return _categoryNamesCache[cacheKey]!;
    }

    final catSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .doc(catId)
        .get();

    if (!catSnap.exists) {
      _categoryNamesCache[cacheKey] = 'N/A';
      return 'N/A';
    }

    final catData = catSnap.data();
    final catName = catData?['name'] ?? 'N/A';
    _categoryNamesCache[cacheKey] = catName;
    return catName;
  }

  // --------------------------------------------------------------------------------
  // Méthode pour la barre de recherche
  // --------------------------------------------------------------------------------
  void onSearchChanged(String val) {
    searchText.value = val;
  }

  // --------------------------------------------------------------------------------
  // DataTable => Columns (non utilisé dans la nouvelle version mais gardé pour compatibilité)
  // --------------------------------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Établissement',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Propriétaire',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Type Proprio',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: const Text('Email',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Catégorie',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];

  // --------------------------------------------------------------------------------
  // DataTable => Rows (non utilisé dans la nouvelle version mais gardé pour compatibilité)
  // --------------------------------------------------------------------------------
  List<DataRow> get dataRows {
    final list = filteredEstablishments;
    return List.generate(list.length, (i) {
      final est = list[i];
      return DataRow(
        cells: [
          // Nom établissement
          DataCell(CustomCardAnimation(index: i, child: Text(est.name))),
          // Propriétaire (résolu en FutureBuilder => ownerName)
          DataCell(
            CustomCardAnimation(
              index: i + 1,
              child: FutureBuilder<String>(
                future: getOwnerName(est.userId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  return Text(snap.data ?? 'Inconnu');
                },
              ),
            ),
          ),
          // Type proprio
          DataCell(
            CustomCardAnimation(
              index: i + 2,
              child: FutureBuilder<String>(
                future: getOwnerType(est.userId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  return Text(snap.data ?? '');
                },
              ),
            ),
          ),
          // Email de l'établissement
          DataCell(CustomCardAnimation(
              index: i + 3, child: Text(est.email.isEmpty ? '-' : est.email))),
          // Catégorie (résolu en FutureBuilder => catName)
          DataCell(
            CustomCardAnimation(
              index: i + 4,
              child: FutureBuilder<String>(
                future:
                    getCategoryName(est.categoryId, est.enterpriseCategoryIds),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  return Text(snap.data ?? 'N/A');
                },
              ),
            ),
          ),
        ],
      );
    });
  }
  
  // Mettre à jour le pourcentage de cashback
  Future<void> updateCashbackPercentage(String establishmentId, double percentage) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentId)
          .update({
        'cashback_percentage': percentage,
      });
      
      // Rafraîchir la liste localement
      final index = allEstablishments.indexWhere((e) => e.id == establishmentId);
      if (index != -1) {
        // Forcer un rafraîchissement en récupérant le document mis à jour
        final updatedDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentId)
            .get();
        
        if (updatedDoc.exists) {
          allEstablishments[index] = Establishment.fromDocument(updatedDoc);
          allEstablishments.refresh();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le cashback: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
}
