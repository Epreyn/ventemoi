import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Imports internes
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/models/establishment_category.dart';
import '../../../core/theme/custom_theme.dart';
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

    // Récupérer l'ID de l'utilisateur connecté
    final currentUserId =
        UniquesControllers().data.firebaseAuth.currentUser?.uid;

    for (final e in raw) {
      // Exclure l'établissement de l'utilisateur connecté
      if (e.userId == currentUserId && tab != 2) {
        continue; // Ne pas afficher sa propre boutique/association
      }

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

    openAlertDialog(
      isAssoc ? 'Faire un don' : 'Acheter des bons',
      confirmText: isAssoc ? 'Donner' : 'Acheter',
      confirmColor: isAssoc ? Colors.green : CustomTheme.lightScheme().primary,
      icon: isAssoc ? Icons.volunteer_activism : Icons.shopping_cart,
    );
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

    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image de l'établissement
          if (e.logoUrl.isNotEmpty || e.bannerUrl.isNotEmpty)
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(
                      e.logoUrl.isNotEmpty ? e.logoUrl : e.bannerUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Text(
                  e.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Solde actuel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: CustomTheme.lightScheme().primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Solde actuel : ',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${buyerPoints.value} points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (isAssoc) ...[
            // Interface pour les dons
            Column(
              children: [
                Text(
                  'Montant du don',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Champ de saisie moderne
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: donationCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            suffixText: 'points',
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Suggestions de montants
                Wrap(
                  spacing: 8,
                  children: [10, 25, 50, 100].map((amount) {
                    return ActionChip(
                      label: Text('$amount pts'),
                      onPressed: () => donationCtrl.text = amount.toString(),
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ] else ...[
            // Interface pour l'achat de bons
            Column(
              children: [
                Text(
                  'Nombre de bons',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),

                // Sélecteur de quantité moderne
                Obx(() => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Bouton moins
                              Container(
                                decoration: BoxDecoration(
                                  color: canDecrement
                                      ? CustomTheme.lightScheme().primary
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: canDecrement
                                      ? () => couponsToBuy.value--
                                      : null,
                                  icon: const Icon(Icons.remove,
                                      color: Colors.white),
                                  iconSize: 20,
                                ),
                              ),

                              // Quantité
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    Text(
                                      '${couponsToBuy.value}',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      couponsToBuy.value > 1 ? 'bons' : 'bon',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bouton plus
                              Container(
                                decoration: BoxDecoration(
                                  color: canIncrement
                                      ? CustomTheme.lightScheme().primary
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: canIncrement
                                      ? () => couponsToBuy.value++
                                      : null,
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Prix total
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: 20,
                                  color: CustomTheme.lightScheme().primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total : ',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '$costInPoints points',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CustomTheme.lightScheme().primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Message d'erreur si pas assez de points
                          if (costInPoints > buyerPoints.value) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 20,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Points insuffisants',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),

                const SizedBox(height: 12),

                // Information sur la limite
                Text(
                  'Maximum $maxCouponsAllowed bons par achat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
  // Ajouter ces méthodes dans ShopEstablishmentScreenController

  // Variables locales pour les filtres temporaires
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
      // Statistiques des catégories
      Obx(() {
        final tab = selectedTabIndex.value;
        final categories = tab == 2 ? enterpriseCategoriesMap : categoriesMap;
        final totalEstablishments = displayedEstablishments.length;

        if (categories.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.05),
                  Colors.blue.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Statistiques',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalEstablishments établissement${totalEstablishments > 1 ? 's' : ''} trouvé${totalEstablishments > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${categories.length} catégorie${categories.length > 1 ? 's' : ''} disponible${categories.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }),

      const SizedBox(height: 20),

      // Section des catégories
      Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de section
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Catégories disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Chips de catégories avec design amélioré
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _buildImprovedCategoryChips(),
                    ),
                  ),
                ),
              ),
            ],
          )),

      const SizedBox(height: 20),

      // Actions rapides
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: CustomTheme.lightScheme().primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Sélectionner toutes les catégories
                      final tab = selectedTabIndex.value;
                      if (tab == 2) {
                        localSelectedEnterpriseCatIds.value =
                            Set.from(enterpriseCategoriesMap.keys);
                      } else {
                        localSelectedCatIds.value =
                            Set.from(categoriesMap.keys);
                      }
                    },
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Tout sélectionner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomTheme.lightScheme().primary,
                      side: BorderSide(
                        color: CustomTheme.lightScheme().primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Inverser la sélection
                      final tab = selectedTabIndex.value;
                      if (tab == 2) {
                        final allKeys = enterpriseCategoriesMap.keys.toSet();
                        final currentSelection =
                            localSelectedEnterpriseCatIds.toSet();
                        localSelectedEnterpriseCatIds.value =
                            allKeys.difference(currentSelection);
                      } else {
                        final allKeys = categoriesMap.keys.toSet();
                        final currentSelection = localSelectedCatIds.toSet();
                        localSelectedCatIds.value =
                            allKeys.difference(currentSelection);
                      }
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Inverser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildImprovedCategoryChips() {
    final tab = selectedTabIndex.value;
    final categories = tab == 2 ? enterpriseCategoriesMap : categoriesMap;
    final selectedIds =
        tab == 2 ? localSelectedEnterpriseCatIds : localSelectedCatIds;

    if (categories.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune catégorie disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return categories.entries.map((entry) {
      final isSelected = selectedIds.contains(entry.key);

      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(
          begin: isSelected ? 0.95 : 1.0,
          end: 1.0,
        ),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isSelected) {
                    selectedIds.remove(entry.key);
                  } else {
                    selectedIds.add(entry.key);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.2),
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? CustomTheme.lightScheme().primary
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected
                            ? CustomTheme.lightScheme().primary
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? CustomTheme.lightScheme().primary
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();

    // Appliquer les filtres temporaires aux filtres réels
    final tab = selectedTabIndex.value;
    if (tab == 2) {
      selectedEnterpriseCatIds.value = Set.from(localSelectedEnterpriseCatIds);
    } else {
      selectedCatIds.value = Set.from(localSelectedCatIds);
    }

    // Refiltrer les établissements
    filterEstablishments();

    // Feedback visuel
    HapticFeedback.mediumImpact();

    // Message de confirmation
    final filterCount =
        tab == 2 ? selectedEnterpriseCatIds.length : selectedCatIds.length;

    if (filterCount > 0) {
      UniquesControllers().data.snackbar(
            'Filtres appliqués',
            '$filterCount catégorie${filterCount > 1 ? 's' : ''} sélectionnée${filterCount > 1 ? 's' : ''}',
            false,
          );
    }
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
