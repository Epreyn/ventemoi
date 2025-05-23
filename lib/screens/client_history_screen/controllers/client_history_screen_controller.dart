import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../widgets/client_history_seller_name.dart';

class ClientHistoryScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Historique Client'.toUpperCase();
  String customBottomAppBarTag = 'client-history-bottom-app-bar';

  // On suit le wallet pour l'affichage "Points"
  RxInt userPoints = 0.obs;
  // On suit la liste d'achats
  RxList<Purchase> purchases = <Purchase>[].obs;

  // Tri DataTable
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

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
      _sortPurchases();
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

  // Tri
  void onSortData(int colIndex, bool ascending) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = ascending;
    _sortPurchases();
  }

  void _sortPurchases() {
    final sorted = purchases.toList();
    switch (sortColumnIndex.value) {
      case 0: // Tri sur couponsCount
        sorted.sort((a, b) => a.couponsCount.compareTo(b.couponsCount));
        break;
      case 1: // Tri sur sellerId
        sorted.sort((a, b) => a.sellerId.compareTo(b.sellerId));
        break;
      case 2: // Tri sur date
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 3: // Tri sur reclamationPassword
        sorted.sort((a, b) => a.reclamationPassword.compareTo(b.reclamationPassword));
        break;
      case 4: // Tri sur isReclaimed
        // false avant true
        sorted.sort((a, b) => a.isReclaimed == b.isReclaimed ? 0 : (a.isReclaimed ? 1 : -1));
        break;
    }

    // Appliquer l'ordre asc/desc
    if (!sortAscending.value) {
      purchases.value = sorted.reversed.toList();
    } else {
      purchases.value = sorted;
    }
  }

  // Les colonnes
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Détails', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Établissement', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Code à fournir', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('État', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
      ];

  // Les rows
  List<DataRow> get dataRows {
    return List.generate(purchases.length, (i) {
      final pur = purchases[i];
      final dateFr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(pur.date);

      final isDonation = (pur.couponsCount == 0);
      final detailText = isDonation ? 'Don' : ' Bon d\'achat de ${pur.couponsCount * 50} €';

      return DataRow(
        cells: [
          DataCell(
            CustomCardAnimation(
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              index: i,
              child: Text(detailText),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              index: i + 1,
              // child: Container(),
              child: ClientHistorySellerNameCell(sellerId: pur.sellerId),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              index: i + 2,
              child: Text(dateFr),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              index: i + 3,
              child: Text(pur.reclamationPassword),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              index: i + 4,
              child: pur.isReclaimed
                  ? const Row(
                      children: [
                        Icon(Icons.check),
                        CustomSpace(widthMultiplier: 0.5),
                        Text('Récupéré'),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(Icons.history),
                        CustomSpace(widthMultiplier: 0.5),
                        Text('En attente'),
                      ],
                    ),
            ),
          ),
        ],
      );
    });
  }
}
