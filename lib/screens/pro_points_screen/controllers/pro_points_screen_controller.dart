import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/commission.dart';
import '../../../core/models/point_attribution.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class ProPointsScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Points'.toUpperCase();
  String customBottomAppBarTag = 'pro-points-bottom-app-bar';

  // ---- LISTE DES POINTS ----
  RxList<PointAttribution> pointsList = <PointAttribution>[].obs;
  StreamSubscription<List<PointAttribution>>? _subscriptionPoints;

  // ---- LISTE DES COMMISSIONS ----
  RxList<Commission> ratioList = <Commission>[].obs;
  StreamSubscription<List<Commission>>? _subscriptionRatios;

  // Tri
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  // Le pourcentage points (manuel, 1.6% par ex.)
  final RxDouble manualPercentage = 1.6.obs;
  final RxInt potentialPoints = 0.obs;

  // BottomSheet
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController searchCtrl = TextEditingController();
  final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  final RxString selectedEmail = ''.obs;
  final TextEditingController montantCtrl = TextEditingController(text: '');

  @override
  void onInit() {
    super.onInit();

    // 1) Souscription flux "points_attributions"
    _subscriptionPoints = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_attributions')
        .where('giver_id', isEqualTo: UniquesControllers().data.firebaseAuth.currentUser?.uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PointAttribution.fromDocument(doc)).toList())
        .listen((list) {
      pointsList.value = list;
      _sortPoints();
    });

    // 2) Souscription flux "commissions" (ex- "ratios")
    _subscriptionRatios = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('commissions')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Commission.fromDocument(doc)).toList())
        .listen((list) {
      ratioList.value = list;
    });
  }

  @override
  void onClose() {
    _subscriptionPoints?.cancel();
    _subscriptionRatios?.cancel();
    super.onClose();
  }

  // --------------------------------------------------------
  // Tri
  // --------------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortPoints();
  }

  void _sortPoints() {
    final sorted = pointsList.toList();
    switch (sortColumnIndex.value) {
      case 0:
        sorted.sort((a, b) => a.targetEmail.compareTo(b.targetEmail));
        break;
      case 1:
        sorted.sort((a, b) => a.points.compareTo(b.points));
        break;
      case 2:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
    }
    pointsList.value = sortAscending.value ? sorted : sorted.reversed.toList();
  }

  // --------------------------------------------------------
  // Les colonnes du DataTable
  // --------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Points', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
          onSort: (col, asc) => onSortData(col, asc),
        ),
        DataColumn(
          label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (col, asc) => onSortData(col, asc),
        ),
        const DataColumn(
          label: Text('État', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];

  // --------------------------------------------------------
  // Les lignes du DataTable
  // --------------------------------------------------------
  List<DataRow> get dataRows {
    return List.generate(pointsList.length, (i) {
      final item = pointsList[i];
      final dateFr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(item.date);
      return DataRow(
        cells: [
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text(item.targetEmail),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text('${item.points}'),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text(dateFr),
            ),
          ),
          DataCell(
            CustomCardAnimation(
              index: i,
              child: item.validated
                  ? const Row(children: [
                      Icon(Icons.check),
                      CustomSpace(widthMultiplier: 0.5),
                      Text('Validé'),
                    ])
                  : const Row(children: [
                      Icon(Icons.history),
                      CustomSpace(widthMultiplier: 0.5),
                      Text('En attente'),
                    ]),
            ),
          ),
        ],
      );
    });
  }

  // --------------------------------------------------------
  // FAB => ouvre le bottomSheet
  // --------------------------------------------------------
  late Widget addPointsFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.dynamicIconList.length,
    child: FloatingActionButton.extended(
      heroTag: UniqueKey().toString(),
      onPressed: openAddPointsBottomSheet,
      icon: const Icon(Icons.add),
      label: const Text('Attribuer des Points'),
    ),
  );

  void openAddPointsBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Attribuer des Points',
      actionName: 'Attribuer',
      actionIcon: Icons.add,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    formKey.currentState?.reset();
    searchCtrl.clear();
    montantCtrl.clear();
    searchResults.clear();
    selectedEmail.value = '';
    potentialPoints.value = 0;
  }

  // --------------------------------------------------------
  // Au changement de Montant => on recalcule potentialPoints
  // --------------------------------------------------------
  Future<void> updatePotentialPoints(String val) async {
    final m = double.tryParse(val.trim()) ?? 0.0;
    if (m <= 0) {
      potentialPoints.value = 0;
      return;
    }
    // On ne change pas manualPercentage (1.6) dans cet exemple
    // On calcule juste potentialPoints
    potentialPoints.value = (m * (manualPercentage.value / 100.0)).floor();
  }

  // --------------------------------------------------------
  // Recherche d’un Particulier par email
  // --------------------------------------------------------
  Future<void> searchParticuliersByEmail(String input) async {
    final txt = input.trim().toLowerCase();
    if (txt.isEmpty) {
      searchResults.clear();
      return;
    }
    final userTypeIdParticulier = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .where('name', isEqualTo: 'Particulier')
        .limit(1)
        .get();
    if (userTypeIdParticulier.docs.isEmpty) {
      searchResults.clear();
      return;
    }
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('user_type_id', isEqualTo: userTypeIdParticulier.docs.first.id)
        .limit(10)
        .get();
    final allDocs = snap.docs.map((doc) {
      final d = doc.data();
      return {'uid': doc.id, 'email': (d['email'] ?? '').toString().toLowerCase()};
    }).toList();
    final filtered = allDocs.where((m) => (m['email'] as String).contains(txt)).toList();
    searchResults.value = filtered;
  }

  // --------------------------------------------------------
  // Création d’une attribution => applique la commission
  // --------------------------------------------------------
  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    Get.back();
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      final email = (selectedEmail.value.isNotEmpty ? selectedEmail.value : searchCtrl.text).trim().toLowerCase();
      final montant = double.tryParse(montantCtrl.text.trim()) ?? 0.0;
      if (email.isEmpty || montant <= 0) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar('Erreur', 'Email ou montant invalide', true);
        return;
      }
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      final proEmail = UniquesControllers().data.firebaseAuth.currentUser?.email?.toLowerCase() ?? '';
      if (uid == null) {
        UniquesControllers().data.isInAsyncCall.value = false;
        return;
      }

      // 1) Vérifier si l'utilisateur (Particulier) existe ou le créer
      final existingUser = await findUserByEmail(email);
      final String userId = existingUser == null ? await createUserWithoutSwitchingSession(email) : existingUser['uid'];

      // 2) Calcul des points => 1.6%
      final points = (montant * (manualPercentage.value / 100.0)).floor();
      if (points <= 0) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar('Erreur', 'Le montant est trop faible pour générer des points', true);
        return;
      }

      // 3) Trouver la commission appropriée
      final comm = _findCommissionForPro(montant, proEmail); // ex. Commission?
      double commissionPercent = 0.0;
      int commissionCost = 0;
      if (comm != null) {
        commissionPercent = comm.percentage;
        // calcul du coût de commission
        commissionCost = (montant * commissionPercent / 100.0).floor();
      }

      // 4) Écriture Firestore
      final docRef = UniquesControllers().data.firebaseFirestore.collection('points_attributions').doc();
      await docRef.set({
        'giver_id': uid,
        'target_id': userId,
        'target_email': email,
        'cost': montant,
        'points': points,
        'date': DateTime.now(),
        'validated': false,

        // Stockage de la commission
        'commission_percent': commissionPercent,
        'commission_cost': commissionCost,
      });

      UniquesControllers().data.snackbar(
            'Succès',
            'Montant $montant € => $points points attribués à $email',
            false,
          );

      await sendProAttributionMailToAdmins(
        proEmail: proEmail,
        montant: montant,
        points: points,
        commissionPercent: commissionPercent,
        commissionCost: commissionCost,
      );
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // --------------------------------------------------------
  // findCommissionForPro => cherche une commission s’appliquant
  // --------------------------------------------------------
  Commission? _findCommissionForPro(double amount, String proEmail) {
    // On parcourt la liste ratioList
    // On cherche un doc Commission qui match l’emailException (vide ou == proEmail)
    // + qui match le range minAmount <= amount < maxAmount (ou isInfinite).
    // On peut choisir le premier match ou le plus précis. Exemple simple :
    for (final c in ratioList) {
      // Filtrage par email
      if (c.emailException.isNotEmpty) {
        // si c.emailException != proEmail => skip
        if (c.emailException != proEmail) {
          continue;
        }
      }
      // Filtrage par montant
      if (amount >= c.minAmount) {
        if (c.isInfinite) {
          // c s’applique => on le retourne
          return c;
        } else {
          // on check maxAmount
          if (amount < c.maxAmount) {
            return c;
          }
        }
      }
    }
    // Si rien ne matche, renvoie null => Commission par défaut = 0
    return null;
  }

  // --------------------------------------------------------
  // findUser / createUser
  // --------------------------------------------------------
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return {'uid': doc.id, ...doc.data()};
  }

  Future<String> createUserWithoutSwitchingSession(String email) async {
    var tmpPass = UniqueKey().toString();
    final secondaryApp = await Firebase.initializeApp(name: 'SecondaryApp', options: Firebase.app().options);
    final secondAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
      final userCred = await secondAuth.createUserWithEmailAndPassword(email: email, password: tmpPass);
      final newUid = userCred.user?.uid;
      if (newUid == null) {
        throw Exception("Impossible de créer l'utilisateur secondaire");
      }
      await secondAuth.sendPasswordResetEmail(email: email);

      // On récupère l'id du userType "Particulier"
      final userTypeIdParticulier = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .where('name', isEqualTo: 'Particulier')
          .limit(1)
          .get();
      final partId = userTypeIdParticulier.docs.first.id;

      // On crée la doc user
      await UniquesControllers().data.firebaseFirestore.collection('users').doc(newUid).set({
        'name': '',
        'email': email,
        'user_type_id': partId,
        'image_url': '',
        'isEnable': true,
        'isVisible': true,
      });
      // On crée la doc wallet
      await UniquesControllers().data.firebaseFirestore.collection('wallets').doc().set({
        'user_id': newUid,
        'points': 0,
        'coupons': 0,
        'bank_details': null,
      });
      // On crée doc sponsorship (si besoin)
      await UniquesControllers().data.firebaseFirestore.collection('sponsorships').doc().set({
        'user_id': newUid,
        'sponsoredEmails': [],
      });

      final whoCreated = UniquesControllers().data.firebaseAuth.currentUser?.email ?? 'un administrateur';

      await sendWelcomeEmailForCreatedUser(
        toEmail: email,
        whoDidCreate: whoCreated,
      );

      return newUid;
    } finally {
      await secondAuth.signOut();
      await secondaryApp.delete();
    }
  }

  // --------------------------------------------------------
  // BOTTOMSHEET UI
  // --------------------------------------------------------
  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            const CustomSpace(heightMultiplier: 2),
            const Text(
              'Rechercher ou créer un Particulier',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const CustomSpace(heightMultiplier: 2),
            // => Champ recherche d’email
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFormField(
                  tag: 'search-email-particulier',
                  controller: searchCtrl,
                  labelText: 'Email du Particulier',
                  onChanged: (val) async {
                    selectedEmail.value = '';
                    await searchParticuliersByEmail(val);
                  },
                  validatorPattern: r'^.+@[a-zA-Z]+\.[a-zA-Z]+$',
                  errorText: 'Email invalide',
                ),
                Obx(() {
                  if (searchResults.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: searchResults.map((res) {
                      return SizedBox(
                        width: UniquesControllers().data.baseMaxWidth,
                        child: Card(
                          child: ListTile(
                            title: Text(res['email']),
                            onTap: () {
                              selectedEmail.value = res['email'];
                              searchCtrl.text = res['email'];
                              searchResults.clear();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
            const CustomSpace(heightMultiplier: 2),
            // => Champ montant
            CustomTextFormField(
              tag: 'montant-to-convert',
              controller: montantCtrl,
              keyboardType: TextInputType.number,
              labelText: 'Montant en €',
              validatorPattern: r'^[0-9]+(\.[0-9]+)?$',
              errorText: 'Entrez un nombre valide (ex: 10.5)',
              onChanged: (value) async {
                await updatePotentialPoints(value);
              },
            ),
            const CustomSpace(heightMultiplier: 4),

            // => Affichage du nb de points potentiel
            Obx(() {
              return Text(
                'Ce montant équivaut à ${potentialPoints.value} points',
                style: TextStyle(
                  fontSize: UniquesControllers().data.baseSpace * 2,
                ),
              );
            }),
            const CustomSpace(heightMultiplier: 2),
          ],
        ),
      ),
    ];
  }
}
