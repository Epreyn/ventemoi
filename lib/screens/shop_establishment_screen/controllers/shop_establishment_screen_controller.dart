import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports internes
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/models/establishment_category.dart';
import '../../../features/custom_space/view/custom_space.dart';

class ShopEstablishmentScreenController extends GetxController
    with ControllerMixin {
  /// 0 => Boutiques, 1 => Associations, 2 => Entreprises
  RxInt selectedTabIndex = 0.obs;

  // Streams
  StreamSubscription<List<Establishment>>? _estabSub;
  StreamSubscription<int>? _buyerPointsSub;

  // TOUTES les establishments
  RxList<Establishment> allEstablishments = <Establishment>[].obs;
  // Après filtrage
  RxList<Establishment> displayedEstablishments = <Establishment>[].obs;

  // Catégories pour Boutiques/Associations
  RxMap<String, String> categoriesMap = <String, String>{}.obs;
  // Catégories d'entreprises
  RxMap<String, String> enterpriseCategoriesMap = <String, String>{}.obs;

  // Filtre multi-catégories (pour boutiques/assos)
  RxString searchText = ''.obs;
  RxSet<String> selectedCatIds = <String>{}.obs;

  // Filtre pour entreprises (si vous voulez un second set distinct)
  // Mais vous pouvez réutiliser les mêmes searchText + selectedCatIds
  // => ci-dessous un exemple
  RxString enterpriseSearchText = ''.obs;
  RxSet<String> selectedEnterpriseCatIds = <String>{}.obs;

  // Points user
  RxInt buyerPoints = 0.obs;

  // Sélection achat/don
  Rx<Establishment?> selectedEstab = Rx<Establishment?>(null);
  final TextEditingController donationCtrl = TextEditingController();
  RxInt couponsToBuy = 1.obs;

  final int maxCouponsAllowed = 4;
  final int pointPerCoupon = 50;

  String pageTitle = 'Établissements'.toUpperCase();
  String customBottomAppBarTag = 'shop-establishment-bottom-app-bar';

  /// userId -> userTypeName ( "Boutique" / "Association" / "Entreprise" / "INVISIBLE" )
  final Map<String, String> userTypeNameCache = {};

  @override
  void onInit() {
    super.onInit();

    // 1) Charger la liste d'établissements
    _estabSub = _getEstablishmentStream().listen((list) async {
      allEstablishments.value = list;

      // Charger les 2 types de catégories
      await _loadCategoriesForBoutiques(list);
      await _loadCategoriesForEnterprises(list);

      // Filtrer
      filterEstablishments();
    });

    // 2) Points acheteur
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _buyerPointsSub = _getBuyerPointsStream(uid).listen((pts) {
        buyerPoints.value = pts;
      });
    }

    // watchers => refiltre
    ever(selectedTabIndex, (_) => filterEstablishments());

    // watchers pour boutiques/assos
    ever(searchText, (_) => filterEstablishments());
    ever(selectedCatIds, (_) => filterEstablishments());

    // watchers pour entreprises
    ever(enterpriseSearchText, (_) => filterEstablishments());
    ever(selectedEnterpriseCatIds, (_) => filterEstablishments());
  }

  @override
  void onClose() {
    _estabSub?.cancel();
    _buyerPointsSub?.cancel();
    super.onClose();
  }

  // ----------------------------------------------------------------
  // Streams
  // ----------------------------------------------------------------

  Stream<List<Establishment>> _getEstablishmentStream() async* {
    final snapStream = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .snapshots();

    await for (final snap in snapStream) {
      if (snap.docs.isEmpty) {
        yield <Establishment>[];
        continue;
      }

      final docs = snap.docs.map((d) => Establishment.fromDocument(d)).toList();
      final results = <Establishment>[];

      // userDocs => savoir typeName + isVisible
      final userIds =
          docs.map((e) => e.userId).toSet().where((e) => e.isNotEmpty).toList();
      if (userIds.isEmpty) {
        yield <Establishment>[];
        continue;
      }

      final usersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      final Map<String, Map<String, dynamic>> userMap = {};
      for (final d in usersSnap.docs) {
        userMap[d.id] = d.data();
      }

      // extraire user_type
      final Set<String> typeIds = {};
      for (final u in userMap.values) {
        final tId = u['user_type_id'] ?? '';
        if (tId.isNotEmpty) typeIds.add(tId);
      }

      final userTypesSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .where(FieldPath.documentId, whereIn: typeIds.toList())
          .get();

      final Map<String, String> typeNameMap = {};
      for (final t in userTypesSnap.docs) {
        final tData = t.data();
        final nm = tData['name'] ?? '';
        typeNameMap[t.id] = nm;
      }

      // Remplir userTypeNameCache
      userTypeNameCache.clear();
      for (final entry in userMap.entries) {
        final uid = entry.key;
        final data = entry.value;
        final visible = data['isVisible'] == true;
        final tId = data['user_type_id'] ?? '';
        final tName = typeNameMap[tId] ?? '';

        if (!visible) {
          userTypeNameCache[uid] = 'INVISIBLE';
        } else {
          userTypeNameCache[uid] =
              tName; // "Boutique" / "Association" / "Entreprise"
        }
      }

      // filtrer
      for (final est in docs) {
        final tName = userTypeNameCache[est.userId] ?? 'INVISIBLE';
        if (tName == 'INVISIBLE') continue;
        results.add(est);
      }

      // tri
      results.sort((a, b) => a.name.compareTo(b.name));
      yield results;
    }
  }

  Stream<int> _getBuyerPointsStream(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return 0;
      return snap.docs.first.data()['points'] ?? 0;
    });
  }

  // ----------------------------------------------------------------
  // Charger catégories : boutiques/assos
  // ----------------------------------------------------------------
  Future<void> _loadCategoriesForBoutiques(List<Establishment> list) async {
    final catIds = <String>{};
    for (final est in list) {
      // On suppose : "categoryId" pour boutique/asso
      if (est.categoryId.isNotEmpty) {
        // Seules boutique/asso ont un categoryId
        catIds.add(est.categoryId);
      }
    }
    if (catIds.isEmpty) {
      categoriesMap.clear();
      return;
    }
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .where(FieldPath.documentId, whereIn: catIds.toList())
        .get();

    final map = <String, String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final nm = data['name'] ?? '';
      map[d.id] = nm;
    }
    categoriesMap.value = map;
  }

  // ----------------------------------------------------------------
  // Charger catégories : entreprises
  // ----------------------------------------------------------------
  Future<void> _loadCategoriesForEnterprises(List<Establishment> list) async {
    // On suppose : "enterpriseCategoryIds" pour entreprise
    final catIds = <String>{};
    for (final est in list) {
      if (est.enterpriseCategoryIds != null) {
        for (final c in est.enterpriseCategoryIds!) {
          catIds.add(c);
        }
      }
    }
    if (catIds.isEmpty) {
      enterpriseCategoriesMap.clear();
      return;
    }
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .where(FieldPath.documentId, whereIn: catIds.toList())
        .get();

    final map = <String, String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final nm = data['name'] ?? '';
      map[d.id] = nm;
    }
    enterpriseCategoriesMap.value = map;
  }

  // ----------------------------------------------------------------
  // Filtrage
  // ----------------------------------------------------------------
  void filterEstablishments() {
    final tab = selectedTabIndex.value;
    // On regarde si on est sur onglet 2 (Entreprises)
    final lowerSearch =
        (tab == 2 ? enterpriseSearchText.value : searchText.value)
            .trim()
            .toLowerCase();

    final raw = allEstablishments;
    final result = <Establishment>[];

    for (final e in raw) {
      // Récupérer typeName => "Boutique"/"Association"/"Entreprise"/"INVISIBLE"
      final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
      final isBoutique = (tName == 'Boutique');
      final isAsso = (tName == 'Association');
      final isEnt = (tName == 'Entreprise');

      // Filtrer par tab
      if (tab == 0 && !isBoutique) continue; // Boutiques seulement
      if (tab == 1 && !isAsso) continue; // Asso seulement
      if (tab == 2 && !isEnt) continue; // Entreprises seulement

      // Filtre par recherche
      if (lowerSearch.isNotEmpty) {
        final nameLower = e.name.toLowerCase();
        final descLower = e.description.toLowerCase();
        if (!nameLower.contains(lowerSearch) &&
            !descLower.contains(lowerSearch)) {
          continue;
        }
      }

      // Filtre par catégorie
      if (tab == 2) {
        // => entreprises => e.enterpriseCategoryIds
        if (selectedEnterpriseCatIds.isNotEmpty) {
          final eCats = e.enterpriseCategoryIds ?? [];
          final hasIntersection = eCats.any(
            (cid) => selectedEnterpriseCatIds.contains(cid),
          );
          if (!hasIntersection) continue;
        }
      } else {
        // => boutiques/assos => e.categoryId
        if (selectedCatIds.isNotEmpty) {
          if (!selectedCatIds.contains(e.categoryId)) {
            continue;
          }
        }
      }

      // On garde
      result.add(e);
    }

    displayedEstablishments.value = result;
  }

  // ----------------------------------------------------------------
  // Setters de search
  // ----------------------------------------------------------------
  void setSearchText(String val) {
    final tab = selectedTabIndex.value;
    if (tab == 2) {
      enterpriseSearchText.value = val;
    } else {
      searchText.value = val;
    }
  }

  // ----------------------------------------------------------------
  // Achat / Don identique
  // ----------------------------------------------------------------

  RxBool isBuying = false.obs;

  void buyEstablishment(Establishment e) {
    selectedEstab.value = e;
    couponsToBuy.value = 1;
    donationCtrl.clear();

    final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
    final isAssoc = (tName == 'Association');
    final title = isAssoc ? 'Donner à ${e.name}' : 'Acheter à ${e.name}';
    openAlertDialog(title, confirmText: 'Valider');
  }

  int get costInPoints => couponsToBuy.value * pointPerCoupon;
  bool get canDecrement => couponsToBuy.value > 1;
  bool get canIncrement => couponsToBuy.value < maxCouponsAllowed;

  @override
  void variablesToResetToAlertDialog() {}

  @override
  Widget alertDialogContent() {
    final e = selectedEstab.value;
    if (e == null) return const Text('Aucun établissement sélectionné');

    final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
    final isAssoc = (tName == 'Association');

    if (isAssoc) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Combien de points donner ?'),
          const CustomSpace(heightMultiplier: 1),
          TextField(
            controller: donationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Points',
            ),
          ),
        ],
      );
    } else {
      // Boutique => nb bons
      return Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: canDecrement ? () => couponsToBuy.value-- : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${couponsToBuy.value}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: canIncrement ? () => couponsToBuy.value++ : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const CustomSpace(heightMultiplier: 1),
              Text('Coût : $costInPoints point(s)'),
            ],
          ));
    }
  }

  @override
  Future<void> actionAlertDialog() async {
    final e = selectedEstab.value;
    if (e == null) return;

    // We assume you have something like:
    //    Map<String,String> userTypeNameCache => userId -> "Association"/"Boutique"
    // so we can differentiate
    final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
    final isAssoc = (tName == 'Association');
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      // Current buyer's points
      final currentPts = buyerPoints.value;

      if (isAssoc) {
        // DON
        final donation = int.tryParse(donationCtrl.text.trim()) ?? 0;
        if (donation <= 0 || donation > currentPts) {
          UniquesControllers().data.snackbar(
                'Erreur',
                'Montant invalide ou points insuffisants',
                true,
              );
          return;
        }

        // 1) Déduire les points du buyer
        await _decrementBuyerPoints(uid, donation);

        // 2) Créer doc "purchases" (ou "donations", selon vos noms)
        //    - isReclaimed = true
        //    - reclamationPassword = ''
        final docRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('purchases')
            .doc();

        await docRef.set({
          'buyer_id': uid,
          'seller_id': e.userId,
          'coupons_count': donation,
          'date': DateTime.now().toIso8601String(),
          'isReclaimed': true, // DON => rien à réclamer
          'reclamationPassword': '',
        });

        UniquesControllers().data.snackbar(
              'Succès',
              'Vous avez fait un don de $donation points à ${e.name}',
              false,
            );

        final buyerEmail =
            UniquesControllers().data.firebaseAuth.currentUser?.email ?? '';
        final buyerName =
            '???'; // À récupérer depuis doc user ou firebaseAuth.currentUser
        final sellerEmail = await _fetchUserEmail(e.userId);
        final sellerName = e.name; // ex. le champ "name" de l’établissement

        await sendPurchaseEmailToBuyer(
          buyerEmail: buyerEmail,
          buyerName: buyerName,
          sellerName: sellerName,
          isDonation: true,
          couponsCountOrPoints: donation,
          reclamationPassword: null, // no code
        );

        await sendPurchaseEmailToSeller(
          sellerEmail: sellerEmail,
          sellerName: sellerName,
          buyerName: buyerName,
          isDonation: true,
          couponsCountOrPoints: donation,
        );
      } else {
        // BOUTIQUE => Achat de coupons
        final nb = couponsToBuy.value;
        final cost = nb * pointPerCoupon;

        if (cost > currentPts) {
          UniquesControllers().data.snackbar(
                'Erreur',
                'Points insuffisants (vous avez $currentPts)',
                true,
              );
          return;
        }
        if (nb > maxCouponsAllowed) {
          UniquesControllers().data.snackbar(
                'Erreur',
                'Nombre de coupons max: $maxCouponsAllowed',
                true,
              );
          return;
        }

        // 1) Retirer les points du buyer
        await _decrementBuyerPoints(uid, cost);

        // 2) Vérifier que la boutique possède bien X coupons
        //    => "coupons" dans wallet du vendeur
        final sellerWalletSnap = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .where('user_id', isEqualTo: e.userId)
            .limit(1)
            .get();

        if (sellerWalletSnap.docs.isEmpty) {
          UniquesControllers().data.snackbar(
                'Erreur',
                'Cette boutique n’a pas de wallet',
                true,
              );
          return;
        }
        final sellerWalletRef = sellerWalletSnap.docs.first.reference;
        final sellerWalletData = sellerWalletSnap.docs.first.data();
        final sellerCoupons = sellerWalletData['coupons'] ?? 0;

        if (sellerCoupons < nb) {
          UniquesControllers().data.snackbar(
                'Erreur',
                'La boutique ne dispose que de $sellerCoupons bons',
                true,
              );
          return;
        }

        // 3) Décrémenter le stock "coupons" de la boutique
        await sellerWalletRef.update({
          'coupons': sellerCoupons - nb,
        });

        // 4) Générer code aléatoire 6 chiffres =>
        final code = _generate6DigitPassword();

        // 5) Créer doc "purchases"
        //    - isReclaimed = false (car c’est un bon cadeau non récupéré)
        //    - reclamationPassword = code
        final purchasesRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('purchases')
            .doc();

        await purchasesRef.set({
          'buyer_id': uid,
          'seller_id': e.userId,
          'coupons_count': nb,
          'date': DateTime.now().toIso8601String(),
          'isReclaimed': false,
          'reclamationPassword': code,
        });

        UniquesControllers().data.snackbar(
              'Succès',
              'Achat réussi : $nb bons pour ${e.name} (coût : $cost points)',
              false,
            );

        final buyerEmail =
            UniquesControllers().data.firebaseAuth.currentUser?.email ?? '';
        final buyerName = '???';
        final sellerEmail = await _fetchUserEmail(e.userId);
        final sellerName = e.name;

        await sendPurchaseEmailToBuyer(
          buyerEmail: buyerEmail,
          buyerName: buyerName,
          sellerName: sellerName,
          isDonation: false,
          couponsCountOrPoints: nb, // nb bons
          reclamationPassword: code, // le code généré
        );

        await sendPurchaseEmailToSeller(
          sellerEmail: sellerEmail,
          sellerName: sellerName,
          buyerName: buyerName,
          isDonation: false,
          couponsCountOrPoints: nb,
        );

        if (sellerCoupons - nb <= 3) {
          await sendLowCouponsEmailToSeller(
            sellerEmail: sellerEmail,
            sellerName: sellerName,
            couponsRemaining: sellerCoupons - nb,
          );
        }
      }
    } catch (err) {
      UniquesControllers().data.snackbar(
            'Erreur',
            err.toString(),
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  /// Décrémente le nombre de points du `uid` acheteur.
  Future<void> _decrementBuyerPoints(String uid, int amount) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw 'Impossible de trouver votre wallet.';
    }
    final docRef = snap.docs.first.reference;
    final oldPoints = snap.docs.first.data()['points'] ?? 0;
    if (oldPoints < amount) {
      throw 'Vous n’avez pas assez de points.';
    }
    await docRef.update({
      'points': oldPoints - amount,
    });
  }

  /// Génère un code random à 6 chiffres.
  /// Ex : "823144"
  String _generate6DigitPassword() {
    final rand = Random();
    final sb = StringBuffer();
    for (int i = 0; i < 6; i++) {
      sb.write(rand.nextInt(10)); // 0..9
    }
    return sb.toString();
  }

  // ----------------------------------------------------------------
  // BOTTOM SHEET : Filtres
  // ----------------------------------------------------------------
  RxSet<String> localSelectedCatIds = <String>{}.obs;
  RxSet<String> localSelectedEnterpriseCatIds = <String>{}.obs;

  @override
  void variablesToResetToBottomSheet() {
    final tab = selectedTabIndex.value;
    if (tab == 0 || tab == 1) {
      localSelectedCatIds.value = Set.from(selectedCatIds);
    } else {
      localSelectedEnterpriseCatIds.value = Set.from(selectedEnterpriseCatIds);
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Obx(() => _buildCatFilterChips()), // Important de mettre un Obx
    ];
  }

  Widget _buildCatFilterChips() {
    final tab = selectedTabIndex.value;

    if (tab == 2) {
      // ----- ONGLET ENTREPRISES -----
      if (enterpriseCategoriesMap.isEmpty) {
        return const Text('Aucune catégorie d’entreprise disponible');
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: enterpriseCategoriesMap.entries.map((e) {
          final catId = e.key;
          final catName = e.value;
          final isSelected = localSelectedEnterpriseCatIds.contains(catId);
          return FilterChip(
            label: Text(catName),
            selected: isSelected,
            onSelected: (bool val) {
              if (val) {
                localSelectedEnterpriseCatIds.add(catId);
              } else {
                localSelectedEnterpriseCatIds.remove(catId);
              }
            },
          );
        }).toList(),
      );
    } else {
      // ----- ONGLET BOUTIQUE/ASSO (0 ou 1) -----
      if (categoriesMap.isEmpty) {
        return const Text('Aucune catégorie disponible');
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categoriesMap.entries.map((e) {
          final catId = e.key;
          final catName = e.value;
          final isSelected = localSelectedCatIds.contains(catId);
          return FilterChip(
            label: Text(catName),
            selected: isSelected,
            onSelected: (bool val) {
              if (val) {
                localSelectedCatIds.add(catId);
              } else {
                localSelectedCatIds.remove(catId);
              }
            },
          );
        }).toList(),
      );
    }
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();

    final tab = selectedTabIndex.value;
    if (tab == 2) {
      // onglet entreprises => on applique localSelectedEnterpriseCatIds
      selectedEnterpriseCatIds.value = Set.from(localSelectedEnterpriseCatIds);
    } else {
      // onglet boutiques/assos => on applique localSelectedCatIds
      selectedCatIds.value = Set.from(localSelectedCatIds);
    }

    // Refiltrage
    filterEstablishments();
  }

  Future<String> _fetchUserEmail(String userId) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();
    if (!snap.exists) return '';
    final data = snap.data()!;
    return data['email'] ?? '';
  }
}
