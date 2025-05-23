import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class AdminEstablishmentsScreenController extends GetxController with ControllerMixin {
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

  // Subscription Firestore
  StreamSubscription<List<Establishment>>? _estabSub;

  @override
  void onInit() {
    super.onInit();
    _estabSub = _getAllEstablishmentsStream().listen((list) {
      allEstablishments.value = list;
      _sortEstablishments();
    });
    ever(searchText, (_) => _sortEstablishments());
  }

  @override
  void onClose() {
    _estabSub?.cancel();
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
        .map((snap) => snap.docs.map((doc) => Establishment.fromDocument(doc)).toList());
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
      return name.contains(query) ||
          desc.contains(query) ||
          address.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
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
    allEstablishments.value = sortAscending.value ? sorted : sorted.reversed.toList();
  }

  int _compareEst(Establishment a, Establishment b) {
    switch (sortColumnIndex.value) {
      case 0: // Tri par nom d'établissement
        return a.name.compareTo(b.name);
      case 1: // Tri par nom propriétaire => On ne l'a pas local, on fera un tri par userId ?
        return a.userId.compareTo(b.userId);
      case 2: // Tri par email (par ex)
        return a.email.compareTo(b.email);
      default:
        return 0;
    }
  }

  // --------------------------------------------------------------------------------
  // Récupérer le nom du propriétaire (userId -> users doc -> name)
  // --------------------------------------------------------------------------------
  Future<String> getOwnerName(String userId) async {
    if (userId.isEmpty) return 'Inconnu';
    final snap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!snap.exists) return 'Inconnu';
    final data = snap.data()!;
    final ownerName = data['name'] ?? 'Inconnu';
    return ownerName;
  }

  // --------------------------------------------------------------------------------
  // Récupérer le type du propriétaire
  // --------------------------------------------------------------------------------
  Future<String> getOwnerType(String userId) async {
    if (userId.isEmpty) return '';
    final userSnap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!userSnap.exists) return '';
    final userData = userSnap.data();
    final userTypeId = userData?['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';
    final typeSnap = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(userTypeId).get();
    if (!typeSnap.exists) return '';
    return typeSnap.data()?['name'] ?? '';
  }

  // --------------------------------------------------------------------------------
  // Récupérer le nom de la catégorie (categoryId -> categories doc -> name)
  // --------------------------------------------------------------------------------
  Future<String> getCategoryName(String catId, List<String>? enterpriseCatsIds) async {
    if (enterpriseCatsIds != null && enterpriseCatsIds.isNotEmpty) {
      final cats = enterpriseCatsIds;
      final catNames = <String>[];
      for (final cId in cats) {
        final catSnap =
            await UniquesControllers().data.firebaseFirestore.collection('enterprise_categories').doc(cId).get();
        if (catSnap.exists) {
          final catData = catSnap.data();
          final catName = catData?['name'] ?? 'N/A';
          catNames.add(catName);
        }
      }
      return catNames.join(', ');
    }

    if (catId.isEmpty) return 'N/A';
    final catSnap = await UniquesControllers().data.firebaseFirestore.collection('categories').doc(catId).get();
    if (!catSnap.exists) return 'N/A';
    final catData = catSnap.data();
    return catData?['name'] ?? 'N/A';
  }

  // --------------------------------------------------------------------------------
  // Méthode pour la barre de recherche
  // --------------------------------------------------------------------------------
  void onSearchChanged(String val) {
    searchText.value = val;
  }

  // --------------------------------------------------------------------------------
  // DataTable => Columns
  // --------------------------------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Établissement', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Propriétaire', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Type Proprio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];

  // --------------------------------------------------------------------------------
  // DataTable => Rows
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
          DataCell(CustomCardAnimation(index: i + 3, child: Text(est.email.isEmpty ? '-' : est.email))),
          // Catégorie (résolu en FutureBuilder => catName)
          DataCell(
            CustomCardAnimation(
              index: i + 4,
              child: FutureBuilder<String>(
                future: getCategoryName(est.categoryId, est.enterpriseCategoryIds),
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
}
