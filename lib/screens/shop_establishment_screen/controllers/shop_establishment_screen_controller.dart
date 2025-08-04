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
  /// 0 => Partenaires (Entreprises), 1 => Commerces (Boutiques), 2 => Associations, 3 => Sponsors
  RxInt selectedTabIndex = 0.obs;

  // Streams
  StreamSubscription<List<Establishment>>? _estabSub;
  StreamSubscription<int>? _buyerPointsSub;

  // TOUTES les establishments
  RxList<Establishment> allEstablishments = <Establishment>[].obs;
  // Après filtrage
  RxList<Establishment> displayedEstablishments = <Establishment>[].obs;

  // Catégories pour Commerces/Associations
  RxMap<String, String> categoriesMap = <String, String>{}.obs;
  // Catégories d'entreprises
  RxMap<String, String> enterpriseCategoriesMap = <String, String>{}.obs;

  // Filtre multi-catégories (pour commerces/assos)
  RxString searchText = ''.obs;
  RxSet<String> selectedCatIds = <String>{}.obs;

  // Filtre pour partenaires (entreprises)
  RxString enterpriseSearchText = ''.obs;
  RxSet<String> selectedEnterpriseCatIds = <String>{}.obs;

  RxString sponsorSearchText = ''.obs;
  RxSet<String> selectedSponsorCatIds = <String>{}.obs;

  // Pour la bottom sheet (filtres temporaires)
  RxSet<String> localSelectedSponsorCatIds = <String>{}.obs;

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

    // watchers pour commerces/assos
    ever(searchText, (_) => filterEstablishments());
    ever(selectedCatIds, (_) => filterEstablishments());

    // watchers pour partenaires (entreprises)
    ever(enterpriseSearchText, (_) => filterEstablishments());
    ever(selectedEnterpriseCatIds, (_) => filterEstablishments());

    // watchers pour sponsors
    ever(sponsorSearchText, (_) => filterEstablishments());
    ever(selectedSponsorCatIds, (_) => filterEstablishments());
  }

  @override
  void onClose() {
    _estabSub?.cancel();
    _buyerPointsSub?.cancel();
    donationCtrl.dispose();
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

        // NOUVEAU : Filtrer directement les établissements qui n'ont pas accepté le contrat
        // Sauf pour les associations qui ont leur propre logique de visibilité
        if (!est.hasAcceptedContract && !est.isAssociation) {
          continue;
        }

        // Pour les associations, vérifier la visibilité (15 affiliés ou override)
        if (est.isAssociation) {
          final isVisibleAssociation =
              est.affiliatesCount >= 15 || est.isVisibleOverride;
          if (!isVisibleAssociation) {
            continue;
          }
        }

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
  // Charger catégories : commerces/associations
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

    // Déterminer quel texte de recherche utiliser selon l'onglet
    String lowerSearch = '';
    switch (tab) {
      case 0: // Partenaires (Entreprises)
        lowerSearch = enterpriseSearchText.value.trim().toLowerCase();
        break;
      case 1: // Commerces (Boutiques)
      case 2: // Associations
        lowerSearch = searchText.value.trim().toLowerCase();
        break;
      case 3: // Sponsors
        lowerSearch = sponsorSearchText.value.trim().toLowerCase();
        break;
    }

    final raw = allEstablishments;
    final result = <Establishment>[];

    // Récupérer l'ID de l'utilisateur connecté
    final currentUserId =
        UniquesControllers().data.firebaseAuth.currentUser?.uid;

    for (final e in raw) {
      // Exclure l'établissement de l'utilisateur connecté
      // SAUF pour les entreprises (tab 0)
      if (e.userId == currentUserId && tab != 0) {
        continue;
      }

      // Récupérer typeName
      final tName = userTypeNameCache[e.userId] ?? 'INVISIBLE';
      final isEnt = (tName == 'Entreprise');
      final isBoutique = (tName == 'Boutique');
      final isAsso = (tName == 'Association');
      final isSponsor = (tName == 'Sponsor');

      // Filtrer par tab (nouvel ordre)
      if (tab == 0 && !isEnt) continue; // Partenaires (Entreprises)
      if (tab == 1 && !isBoutique) continue; // Commerces (Boutiques)
      if (tab == 2 && !isAsso) continue; // Associations
      if (tab == 3 && !isSponsor) continue; // Sponsors

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
      switch (tab) {
        case 0: // Partenaires (Entreprises) - utilisent enterprise_categories
          if (selectedEnterpriseCatIds.isNotEmpty) {
            final eCats = e.enterpriseCategoryIds ?? [];
            final hasIntersection = eCats.any(
              (cid) => selectedEnterpriseCatIds.contains(cid),
            );
            if (!hasIntersection) continue;
          }
          break;
        case 1: // Commerces (Boutiques)
        case 2: // Associations
          if (selectedCatIds.isNotEmpty) {
            if (!selectedCatIds.contains(e.categoryId)) {
              continue;
            }
          }
          break;
        case 3: // Sponsors
          if (selectedSponsorCatIds.isNotEmpty) {
            if (!selectedSponsorCatIds.contains(e.categoryId)) {
              continue;
            }
          }
          break;
      }

      result.add(e);
    }

    displayedEstablishments.value = result;
  }

  // ----------------------------------------------------------------
  // Setters de search
  // ----------------------------------------------------------------
  void setSearchText(String val) {
    final tab = selectedTabIndex.value;
    switch (tab) {
      case 0: // Partenaires (Entreprises)
        enterpriseSearchText.value = val;
        break;
      case 1: // Commerces (Boutiques)
      case 2: // Associations
        searchText.value = val;
        break;
      case 3: // Sponsors
        sponsorSearchText.value = val;
        break;
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

    if (tName == 'Boutique') {
      // Pour les commerces (boutiques)
      openBottomSheet(
        'Acheter des bons',
        subtitle: 'Commerces',
        hasAction: true,
        actionName: 'Confirmer l\'achat',
        actionIcon: Icons.shopping_cart,
      );
    } else if (tName == 'Association') {
      // Pour les associations
      openBottomSheet(
        'Faire un don',
        subtitle: 'Associations',
        hasAction: true,
        actionName: 'Confirmer le don',
        actionIcon: Icons.favorite,
      );
    }
  }

  // Variables locales pour les filtres temporaires
  RxSet<String> localSelectedCatIds = <String>{}.obs;
  RxSet<String> localSelectedEnterpriseCatIds = <String>{}.obs;

  @override
  void variablesToResetToBottomSheet() {
    final tab = selectedTabIndex.value;
    switch (tab) {
      case 0: // Partenaires (Entreprises)
        localSelectedEnterpriseCatIds.value =
            Set.from(selectedEnterpriseCatIds);
        break;
      case 1: // Commerces (Boutiques)
      case 2: // Associations
        localSelectedCatIds.value = Set.from(selectedCatIds);
        break;
      case 3: // Sponsors
        localSelectedSponsorCatIds.value = Set.from(selectedSponsorCatIds);
        break;
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      // Statistiques des catégories
      Obx(() {
        final tab = selectedTabIndex.value;

        // Déterminer quelles catégories afficher
        Map<String, String> categories;
        RxSet<String> selectedIds;

        switch (tab) {
          case 0: // Partenaires (Entreprises)
            categories = enterpriseCategoriesMap;
            selectedIds = localSelectedEnterpriseCatIds;
            break;
          case 1: // Commerces (Boutiques)
          case 2: // Associations
            categories = categoriesMap;
            selectedIds = localSelectedCatIds;
            break;
          case 3: // Sponsors
            categories = categoriesMap;
            selectedIds = localSelectedSponsorCatIds;
            break;
          default:
            categories = {};
            selectedIds = RxSet<String>();
        }
        // Suite du code...
        return Container();
      }),
    ];
  }

  // Le reste des méthodes restent inchangées...

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
      throw 'Vous n\'avez pas assez de points.';
    }
    await docRef.update({
      'points': oldPoints - amount,
    });
  }

  String _generate6DigitPassword() {
    final rand = Random();
    final sb = StringBuffer();
    for (int i = 0; i < 6; i++) {
      sb.write(rand.nextInt(10)); // 0..9
    }
    return sb.toString();
  }
}
