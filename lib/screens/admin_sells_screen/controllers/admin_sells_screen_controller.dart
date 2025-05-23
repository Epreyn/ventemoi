import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';

class AdminSellsScreenController extends GetxController with ControllerMixin {
  // Titre / bottom bar
  String pageTitle = 'Admin - Ventes'.toUpperCase();
  String customBottomAppBarTag = 'admin-sells-bottom-app-bar';

  // Liste complète
  RxList<Purchase> allPurchases = <Purchase>[].obs;

  // Barre de recherche
  RxString searchText = ''.obs;

  // Tri
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  StreamSubscription<List<Purchase>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _getAllPurchasesStream().listen((list) {
      allPurchases.value = list;
      _sortPurchases();
    });

    // On recalcule le filtrage/tri dès que le texte change
    ever(searchText, (_) => _sortPurchases());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // -----------------------------------------------------------------------------
  // Récupérer toutes les purchases
  // -----------------------------------------------------------------------------
  Stream<List<Purchase>> _getAllPurchasesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('purchases')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Purchase.fromDocument(doc)).toList());
  }

  // -----------------------------------------------------------------------------
  // Filtrage => search
  // -----------------------------------------------------------------------------
  List<Purchase> get filteredPurchases {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) {
      return allPurchases;
    }

    return allPurchases.where((p) {
      final code = p.reclamationPassword.toLowerCase();
      // On pourrait aussi stocker un "cache" du buyerName/sellerName,
      // mais ici on se limite à ce qu’on a localement :
      // => Rechercher dans: reclamationPassword, couponsCount (en string), ...
      final dateStr = p.date.toIso8601String().toLowerCase();
      final couponsStr = p.couponsCount.toString();
      return code.contains(query) || dateStr.contains(query) || couponsStr.contains(query);
    }).toList();
  }

  // -----------------------------------------------------------------------------
  // Tri
  // -----------------------------------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortPurchases();
  }

  void _sortPurchases() {
    final sorted = filteredPurchases.toList();
    sorted.sort(_comparePurchase);
    // final => on met dans allPurchases (ou on peut faire un setter filtré)
    // Mais si on veut vraiment la "liste finale" on peut faire un get dataRows
    // qui renvoie un tri.
    if (!sortAscending.value) {
      allPurchases.value = sorted.reversed.toList();
    } else {
      allPurchases.value = sorted;
    }
  }

  int _comparePurchase(Purchase a, Purchase b) {
    switch (sortColumnIndex.value) {
      case 0: // tri par Buyer => on n’a pas local => tri par buyerId
        return a.buyerId.compareTo(b.buyerId);
      case 1: // tri par Seller => ou sellerId
        return a.sellerId.compareTo(b.sellerId);
      case 2: // tri par couponsCount
        return a.couponsCount.compareTo(b.couponsCount);
      case 3: // tri par date
        return a.date.compareTo(b.date);
      default:
        return 0;
    }
  }

  // -----------------------------------------------------------------------------
  // Méthodes pour le DataTable
  // -----------------------------------------------------------------------------
  // Récupérer le nom d’un user => userId -> .name
  Future<String> getUserName(String userId) async {
    if (userId.isEmpty) return 'N/A';
    final snap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!snap.exists) return 'Inconnu';
    final data = snap.data()!;
    return data['name'] ?? 'Inconnu';
  }

  // -----------------------------------------------------------------------------
  // onSearchChanged
  // -----------------------------------------------------------------------------
  void onSearchChanged(String val) {
    searchText.value = val;
  }

  // -----------------------------------------------------------------------------
  // dataColumns => noms de colonnes
  // -----------------------------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Acheteur', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Vendeur', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Bons', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        const DataColumn(
          label: Text('Reclamé ?', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];

  // -----------------------------------------------------------------------------
  // dataRows => generation des DataRow
  // -----------------------------------------------------------------------------
  List<DataRow> get dataRows {
    final list = filteredPurchases;
    return List.generate(list.length, (index) {
      final p = list[index];
      return DataRow(
        cells: [
          // Buyer => FutureBuilder
          DataCell(
            CustomCardAnimation(
              index: index,
              child: FutureBuilder<String>(
                future: getUserName(p.buyerId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  return Text(snap.data ?? 'Inconnu');
                },
              ),
            ),
          ),
          // Seller => FutureBuilder
          DataCell(
            CustomCardAnimation(
              index: index + 1,
              child: FutureBuilder<String>(
                future: getUserName(p.sellerId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  return Text(snap.data ?? 'Inconnu');
                },
              ),
            ),
          ),
          // couponsCount
          DataCell(CustomCardAnimation(index: index + 2, child: Text('${p.couponsCount}'))),
          // date
          DataCell(CustomCardAnimation(
            index: index + 3,
            child: Text(
              '${p.date.day.toString().padLeft(2, '0')}/'
              '${p.date.month.toString().padLeft(2, '0')}/'
              '${p.date.year}',
            ),
          )),
          // isReclaimed
          DataCell(CustomCardAnimation(index: index + 4, child: Text(p.isReclaimed ? 'Oui' : 'Non'))),
          // reclamationPassword
        ],
      );
    });
  }
}
