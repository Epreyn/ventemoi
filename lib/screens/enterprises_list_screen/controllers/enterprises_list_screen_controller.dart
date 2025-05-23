import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';

class EnterprisesListScreenController extends GetxController with ControllerMixin {
  // Titre ou bottom bar
  String pageTitle = 'Entreprises'.toUpperCase();
  String customBottomAppBarTag = 'enterprises-list-bottom-bar';

  // Stream subscription
  StreamSubscription<List<Establishment>>? _sub;

  // Données brutes + filtrées
  RxList<Establishment> allEnterprises = <Establishment>[].obs;
  RxList<Establishment> displayedEnterprises = <Establishment>[].obs;

  // Barre de recherche
  RxString searchText = ''.obs;

  // Sélection multi-cat (IDs)
  RxSet<String> selectedCategoryIds = <String>{}.obs;

  // Map ID->name pour categories
  RxMap<String, String> enterpriseCategoriesMap = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Souscrire
    _sub = _getEnterprisesStream().listen((list) {
      // Màj la liste brute
      allEnterprises.value = list;
      // Charger la map ID->nom pour les cat
      _loadEnterpriseCategories(list);
      // Filtrer
      filterEnterprises();
    });

    // watchers
    ever(searchText, (_) => filterEnterprises());
    ever(selectedCategoryIds, (_) => filterEnterprises());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ----------------------------------------------------------------
  // Stream => tous les etablissements type Entreprise
  // ----------------------------------------------------------------
  Stream<List<Establishment>> _getEnterprisesStream() {
    return UniquesControllers().data.firebaseFirestore.collection('establishments').snapshots().asyncMap((snap) async {
      final docs = snap.docs.map((d) => Establishment.fromDocument(d)).toList();

      final filtered = <Establishment>[];
      for (final est in docs) {
        // check user isVisible + userType=Entreprise
        final userSnap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(est.userId).get();
        if (!userSnap.exists) continue;
        final userData = userSnap.data()!;
        final isVisible = userData['isVisible'] ?? false;
        if (!isVisible) continue;

        final typeId = userData['user_type_id'] ?? '';
        if (typeId.isEmpty) continue;
        final typeDoc = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(typeId).get();
        if (!typeDoc.exists) continue;
        final typeName = typeDoc.data()!['name'] ?? '';
        if (typeName == 'Entreprise') {
          filtered.add(est);
        }
      }

      // Tri par nom
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    });
  }

  // ----------------------------------------------------------------
  // Charger la map ID->name (enterprise_categories)
  // ----------------------------------------------------------------
  Future<void> _loadEnterpriseCategories(List<Establishment> list) async {
    // On veut accumuler tous les IDs
    final allCatIds = <String>{};
    for (final e in list) {
      // e.enterpriseCategoryIds peut être null => on fait ?? []
      final cats = e.enterpriseCategoryIds ?? [];
      allCatIds.addAll(cats);
    }
    if (allCatIds.isEmpty) {
      enterpriseCategoriesMap.clear();
      return;
    }

    // Requête
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .where(FieldPath.documentId, whereIn: allCatIds.toList())
        .get();

    final map = <String, String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final name = data['name'] ?? '???';
      map[d.id] = name;
    }
    enterpriseCategoriesMap.value = map;
  }

  // ----------------------------------------------------------------
  // Filtrage local => search + intersection sur enterpriseCategoryIds
  // ----------------------------------------------------------------
  void filterEnterprises() {
    final raw = allEnterprises;
    final lowerSearch = searchText.value.trim().toLowerCase();
    final catIds = selectedCategoryIds;

    final filtered = <Establishment>[];
    for (final e in raw) {
      // 1) Search => name ou description
      final n = e.name.toLowerCase();
      final d = e.description.toLowerCase();
      if (lowerSearch.isNotEmpty) {
        if (!n.contains(lowerSearch) && !d.contains(lowerSearch)) {
          continue;
        }
      }

      // 2) Filtre cat => intersection enterpriseCategoryIds
      if (catIds.isNotEmpty) {
        final eCatIds = e.enterpriseCategoryIds ?? [];
        final hasIntersection = eCatIds.any((cid) => catIds.contains(cid));
        if (!hasIntersection) {
          continue;
        }
      }

      filtered.add(e);
    }

    displayedEnterprises.value = filtered;
  }

  // ----------------------------------------------------------------
  // Setter => search
  // ----------------------------------------------------------------
  void onSearchChanged(String val) {
    searchText.value = val;
  }

  // ----------------------------------------------------------------
  // BottomSheet => multi-cat
  // ----------------------------------------------------------------
  RxSet<String> tempSelectedCats = <String>{}.obs;

  @override
  void variablesToResetToBottomSheet() {
    tempSelectedCats.value = Set.from(selectedCategoryIds);
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      const Text('Catégories d\'entreprise'),
      Obx(() {
        if (enterpriseCategoriesMap.isEmpty) {
          return const Text('Aucune catégorie d\'entreprise');
        }
        final setSel = tempSelectedCats;
        final items = enterpriseCategoriesMap.entries.toList();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            final catId = e.key;
            final catName = e.value;
            final selected = setSel.contains(catId);
            return FilterChip(
              label: Text(catName),
              selected: selected,
              onSelected: (val) {
                if (val) {
                  setSel.add(catId);
                } else {
                  setSel.remove(catId);
                }
              },
            );
          }).toList(),
        );
      }),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();
    // Applique
    selectedCategoryIds.value = Set.from(tempSelectedCats);
  }
}
