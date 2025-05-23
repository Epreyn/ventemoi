import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../widgets/pro_sells_buyer_email_cell.dart';
import '../widgets/pro_sells_buyer_name_cell.dart';

class ProSellsScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Ventes'.toUpperCase();
  String customBottomAppBarTag = 'pro-sells-bottom-app-bar';

  RxList<Purchase> purchases = <Purchase>[].obs;

  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  StreamSubscription<List<Purchase>>? _purchasesSub;

  // Pour la validation (switch) => code
  Rx<Purchase?> editingPurchase = Rx<Purchase?>(null);
  final TextEditingController codeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _purchasesSub = getProPurchasesStream().listen((list) {
      purchases.value = list;
      _sortPurchases();
    });
  }

  @override
  void onClose() {
    _purchasesSub?.cancel();
    super.onClose();
  }

  // Récupération des purchases où seller_id == currentUser
  Stream<List<Purchase>> getProPurchasesStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    print('UID : ' + uid.toString());
    if (uid == null) return const Stream.empty();
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('purchases')
        .where('seller_id', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Purchase.fromDocument(d)).toList());
  }

  // Tri
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortPurchases();
  }

  void _sortPurchases() {
    final sorted = purchases.toList();
    switch (sortColumnIndex.value) {
      case 0: // Détails
        // ...ex: tri sur couponsCount
        sorted.sort((a, b) => a.couponsCount.compareTo(b.couponsCount));
        break;

      case 1: // Valeur => on suppose que vous avez un champ "purchaseValue"
        // => sorted.sort((a, b) => a.purchaseValue.compareTo(b.purchaseValue));
        break;

      case 2: // Acheteur => buyerId
        sorted.sort((a, b) => a.buyerId.compareTo(b.buyerId));
        break;

      case 3: // Date
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;

      case 4: // Email => pas de champ direct => skip
        break;

      case 5: // Statut => isReclaimed
        sorted.sort((a, b) =>
            a.isReclaimed.toString().compareTo(b.isReclaimed.toString()));
        break;

      default:
        break;
    }
    if (!sortAscending.value) {
      purchases.value = sorted.reversed.toList();
    } else {
      purchases.value = sorted;
    }
  }

  // Colonnes
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Détails',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Valeur',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Acheteur',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label:
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        const DataColumn(
          label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const DataColumn(
          label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];

  List<DataRow> get dataRows {
    return List.generate(purchases.length, (i) {
      final pur = purchases[i];
      final dateFr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(pur.date);

      // 1) Détails => couponsCount ou “Don”
      final bool isDonation = (pur.couponsCount == 0);
      final detailText = isDonation
          ? 'Don' // (si vous avez donation_amount, vous pourriez l'afficher)
          : '${pur.couponsCount} bons';

      // 2) Switch isReclaimed => si false => on peut l’activer => ouvre code
      // 3) Sur clic => on assigne editingPurchase=pur => openReclaimDialog()

      return DataRow(
        //color: i.isEven ? MaterialStateProperty.all() : null,
        cells: [
          // Détails
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text(detailText),
            ),
          ),
          // Valeur => purchaseValue
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text('${pur.couponsCount * 50} €'),
            ),
          ),
          // Acheteur => buyer name
          DataCell(
            CustomCardAnimation(
              index: i,
              child: ProSellsBuyerNameCell(buyerId: pur.buyerId),
            ),
          ),
          // Date
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text(dateFr),
            ),
          ),
          // Email
          DataCell(
            CustomCardAnimation(
              index: i,
              child: ProSellsBuyerEmailCell(buyerId: pur.buyerId),
            ),
          ),
          // Statut
          DataCell(
            pur.isReclaimed
                ? const Row(
                    children: [
                      Icon(Icons.check),
                      CustomSpace(widthMultiplier: 0.5),
                      Text('Récupéré'),
                    ],
                  )
                : CustomCardAnimation(
                    index: i,
                    child: Switch(
                      thumbColor: WidgetStateProperty.all(Colors.black),
                      value: pur.isReclaimed,
                      onChanged: pur.isReclaimed
                          ? null
                          : (val) {
                              if (val) {
                                editingPurchase.value = pur;
                                openReclaimDialog();
                              }
                            },
                    ),
                  ),
          ),
        ],
      );
    });
  }

  // On clique sur switch => openReclaimDialog() => saisie code
  void openReclaimDialog() {
    openAlertDialog('Valider la récupération ?');
  }

  // On veut un champ code => on l’ajoute dans alertDialogContent
  @override
  Widget alertDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Entrer le code de réclamation :'),
        const SizedBox(height: 12),
        TextField(
          controller: codeController,
          obscureText: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(90),
            ),
            labelText: 'Code',
          ),
        ),
      ],
    );
  }

  @override
  Future<void> actionAlertDialog() async {
    final pur = editingPurchase.value;
    if (pur == null) return;

    final inputCode = codeController.text.trim();
    codeController.clear();

    if (inputCode.isEmpty) {
      UniquesControllers().data.snackbar('Erreur', 'Code vide', true);
      return;
    }
    if (inputCode != pur.reclamationPassword) {
      UniquesControllers().data.snackbar('Erreur', 'Code invalide', true);
      return;
    }

    // code correct => isReclaimed = true
    try {
      UniquesControllers().data.isInAsyncCall.value = true;
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('purchases')
          .doc(pur.id)
          .update({
        'isReclaimed': true,
      });
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Succès', 'Produit récupéré', false);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
