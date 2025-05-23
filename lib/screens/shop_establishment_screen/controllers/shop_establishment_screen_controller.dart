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

class ShopEstablishmentScreenController extends GetxController with ControllerMixin {
  // Onglet 0 => Boutiques, 1 => Associations
  RxInt selectedTabIndex = 0.obs;

  // Streams
  StreamSubscription<List<Establishment>>? _estabSub;
  StreamSubscription<int>? _buyerPointsSub;

  // TOUTES les establishments (boutiques + associations confondues)
  RxList<Establishment> allEstablishments = <Establishment>[].obs;
  // Après filtrage
  RxList<Establishment> displayedEstablishments = <Establishment>[].obs;

  RxMap<String, String> categoriesMap = <String, String>{}.obs;

  // Filtre multi-catégories
  RxString searchText = ''.obs;
  RxSet<String> selectedCatIds = <String>{}.obs;

  // Points user
  RxInt buyerPoints = 0.obs;

  // Sélection achat/don
  Rx<Establishment?> selectedEstab = Rx<Establishment?>(null);
  final TextEditingController donationCtrl = TextEditingController();
  RxInt couponsToBuy = 1.obs;

  final int maxCouponsAllowed = 4;
  final int pointPerCoupon = 50;

  String pageTitle = 'Boutique Établissements'.toUpperCase();
  String customBottomAppBarTag = 'shop-establishment-bottom-app-bar';

  // Pour stocker userId -> userTypeName (ex: "Association" ou "Boutique") afin d'éviter
  // de refaire 2 fetchs (users + user_types) lors du filtrage
  final Map<String, String> userTypeNameCache = {};

  @override
  void onInit() {
    super.onInit();

    // 1) Charger la liste d'établissements
    _estabSub = _getEstablishmentStream().listen((list) {
      allEstablishments.value = list;
      // Charger les catégories
      _loadCategories(list);
      // Filtrage
      filterEstablishments();
    });

    // 2) Points acheteur
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _buyerPointsSub = _getBuyerPointsStream(uid).listen((pts) {
        buyerPoints.value = pts;
      });
    }

    // 3) Watchers => refiltre
    ever(selectedTabIndex, (_) => filterEstablishments());
    ever(searchText, (_) => filterEstablishments());
    ever(selectedCatIds, (_) => filterEstablishments());
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
  /// On récupère TOUTES les establishments, et on charge userDoc + user_typeDoc
  /// pour stocker userId -> userTypeName dans userTypeNameCache.
  /// On ne *filtre pas encore* par Association/Boutique ici : on prend tout,
  /// et on fera la distinction plus tard dans `filterEstablishments()`.
  Stream<List<Establishment>> _getEstablishmentStream() async* {
    final snapStream = UniquesControllers().data.firebaseFirestore.collection('establishments').snapshots();

    await for (final snap in snapStream) {
      if (snap.docs.isEmpty) {
        yield <Establishment>[];
        continue;
      }

      final docs = snap.docs.map((d) => Establishment.fromDocument(d)).toList();
      final results = <Establishment>[];

      // On va fetch tous les userDocs correspondants *une fois* => userId -> userData
      // Au lieu de fetch doc par doc, on utilise un batch approach (whereIn),
      // si le nombre de userIds <= 10. Sinon on segmente.
      final userIds = docs.map((e) => e.userId).toSet().where((id) => id.isNotEmpty).toList();
      if (userIds.isEmpty) {
        yield <Establishment>[]; // personne
        continue;
      }

      // On scinde éventuellement en paquets de 10 (limite Firestore), omis ici pour la démo
      final usersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      // userId -> ( userData )
      final Map<String, Map<String, dynamic>> userMap = {};
      for (final d in usersSnap.docs) {
        userMap[d.id] = d.data();
      }

      // On extraie user_type_ids
      final typeIds = <String>{};
      for (final uData in userMap.values) {
        if ((uData['user_type_id'] ?? '').toString().isNotEmpty) {
          typeIds.add(uData['user_type_id']);
        }
      }

      // On fetch user_types => doc par doc ou un batch with whereIn
      final userTypesSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .where(FieldPath.documentId, whereIn: typeIds.toList())
          .get();

      // typeId -> name
      final Map<String, String> typeNameMap = {};
      for (final d in userTypesSnap.docs) {
        final nm = d.data()['name'] ?? '';
        typeNameMap[d.id] = nm;
      }

      // On remplit userTypeNameCache
      userTypeNameCache.clear();
      for (final entry in userMap.entries) {
        final uId = entry.key;
        final data = entry.value;
        final tId = data['user_type_id'] ?? '';
        final tName = typeNameMap[tId] ?? '';
        // isVisible => on check
        if (data['isVisible'] == true) {
          // on stocke
          userTypeNameCache[uId] = tName;
        } else {
          // user pas visible => on l'exclut d'office
          userTypeNameCache[uId] = 'INVISIBLE';
        }
      }

      // On repasse sur docs => on garde seulement si userId visible
      for (final est in docs) {
        final tName = userTypeNameCache[est.userId] ?? 'INVISIBLE';
        if (tName == 'INVISIBLE') {
          continue; // user non visible => skip
        }
        // On ajoute
        results.add(est);
      }

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
  // Charger la map des catégories => cId -> catName
  // ----------------------------------------------------------------
  Future<void> _loadCategories(List<Establishment> list) async {
    final cids = <String>{};
    for (final e in list) {
      if (e.categoryId.isNotEmpty) {
        cids.add(e.categoryId);
      }
    }
    if (cids.isEmpty) {
      categoriesMap.clear();
      return;
    }
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .where(FieldPath.documentId, whereIn: cids.toList())
        .get();

    final map = <String, String>{};
    for (final d in snap.docs) {
      final cat = EstablishmentCategory.fromDocument(d);
      map[cat.id] = cat.name;
    }
    categoriesMap.value = map;
  }

  // ----------------------------------------------------------------
  // Filtre final
  // ----------------------------------------------------------------
  void filterEstablishments() {
    final raw = allEstablishments;
    final tab = selectedTabIndex.value; // 0 => boutique, 1 => association
    final lowerSearch = searchText.value.trim().toLowerCase();
    final selCats = selectedCatIds;

    final res = <Establishment>[];

    for (final e in raw) {
      // Vérif type => userId -> userTypeName (via userTypeNameCache)
      final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
      if (tName == 'INVISIBLE') continue; // déjà skip

      final isAssoc = (tName == 'Association');
      final isBoutique = (tName == 'Boutique');

      // 1) tab
      if (tab == 0 && !isBoutique) continue;
      if (tab == 1 && !isAssoc) continue;

      // 2) search
      if (lowerSearch.isNotEmpty) {
        final n = e.name.toLowerCase();
        final d = e.description.toLowerCase();
        if (!n.contains(lowerSearch) && !d.contains(lowerSearch)) {
          continue;
        }
      }

      // 3) cat
      if (selCats.isNotEmpty && !selCats.contains(e.categoryId)) {
        continue;
      }

      res.add(e);
    }

    // Tri par nom
    res.sort((a, b) => a.name.compareTo(b.name));
    displayedEstablishments.value = res;
  }

  // setter search
  void setSearchText(String txt) => searchText.value = txt;

  // ----------------------------------------------------------------
  // Acheteur
  // ----------------------------------------------------------------
  RxBool isBuying = false.obs;

  void buyEstablishment(Establishment e) {
    selectedEstab.value = e;
    couponsToBuy.value = 1;
    donationCtrl.clear();

    // userId -> userTypeName
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
    if (e == null) {
      return const Text('Aucun établissement sélectionné');
    }
    // userId -> userTypeName
    final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
    final isAssoc = (tName == 'Association');

    if (isAssoc) {
      // Don
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Combien de points voulez-vous donner ?'),
          const CustomSpace(heightMultiplier: 1),
          TextField(
            controller: donationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    } else {
      // Boutique => coupons
      return Obx(() {
        return Column(
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
        );
      });
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
        final docRef = UniquesControllers().data.firebaseFirestore.collection('purchases').doc();

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

        final buyerEmail = UniquesControllers().data.firebaseAuth.currentUser?.email ?? '';
        final buyerName = '???'; // À récupérer depuis doc user ou firebaseAuth.currentUser
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
        final purchasesRef = UniquesControllers().data.firebaseFirestore.collection('purchases').doc();

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

        final buyerEmail = UniquesControllers().data.firebaseAuth.currentUser?.email ?? '';
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

  @override
  void variablesToResetToBottomSheet() {
    localSelectedCatIds.value = Set.from(selectedCatIds);
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      _buildCatFilterChips(),
    ];
  }

  Widget _buildCatFilterChips() {
    if (categoriesMap.isEmpty) {
      return const Text('Aucune catégorie disponible');
    }
    final setSel = localSelectedCatIds;
    final map = categoriesMap;

    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: map.entries.map((e) {
          final id = e.key;
          final name = e.value;
          final selected = setSel.contains(id);
          return FilterChip(
            label: Text(name),
            selected: selected,
            onSelected: (val) {
              if (val) {
                setSel.add(id);
              } else {
                setSel.remove(id);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();
    selectedCatIds.value = Set.from(localSelectedCatIds);
    filterEstablishments();
  }

  Future<String> _fetchUserEmail(String userId) async {
    final snap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!snap.exists) return '';
    final data = snap.data()!;
    return data['email'] ?? '';
  }
}
