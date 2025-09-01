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
  RxInt donationAmount = 0.obs;

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
      // MODIFICATION: On n'exclut plus jamais l'établissement de l'utilisateur connecté
      // L'utilisateur peut voir son propre établissement mais ne pourra pas acheter

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

  // Méthode pour vérifier si c'est son propre établissement
  bool isOwnEstablishment(String establishmentUserId) {
    final currentUserId =
        UniquesControllers().data.firebaseAuth.currentUser?.uid;
    return establishmentUserId == currentUserId;
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
  void actionBottomSheet() {
    // Appeler la méthode appropriée selon le contexte
    if (selectedEstab.value != null) {
      final tName = userTypeNameCache[selectedEstab.value!.userId] ?? 'INVISIBLE';
      
      if (tName == 'Boutique') {
        // Achat de bons pour les commerces
        _performPurchase();
      } else if (tName == 'Association') {
        // Don pour les associations
        _performDonation();
      }
    }
  }
  
  void _performPurchase() async {
    if (selectedEstab.value == null) return;
    
    final totalCost = couponsToBuy.value * pointPerCoupon;
    
    if (buyerPoints.value < totalCost) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Vous n\'avez pas assez de points. Il vous faut $totalCost points.',
        true,
      );
      return;
    }
    
    isBuying.value = true;
    
    try {
      final batch = UniquesControllers().data.firebaseFirestore.batch();
      final buyerId = UniquesControllers().data.firebaseAuth.currentUser!.uid;
      
      // Créer les bons d'achat
      for (int i = 0; i < couponsToBuy.value; i++) {
        final couponRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('vouchers')
            .doc();
        
        batch.set(couponRef, {
          'buyer_id': buyerId,
          'establishment_id': selectedEstab.value!.id,
          'establishment_name': selectedEstab.value!.name,
          'points_value': pointPerCoupon,
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }
      
      // Déduire les points de l'acheteur
      final buyerRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(buyerId);
      
      batch.update(buyerRef, {
        'points': FieldValue.increment(-totalCost),
      });
      
      // Ajouter les points au commerce
      final estabRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(selectedEstab.value!.id);
      
      batch.update(estabRef, {
        'points_received': FieldValue.increment(totalCost),
      });
      
      // Créer une transaction
      final transactionRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('transactions')
          .doc();
      
      batch.set(transactionRef, {
        'from_user_id': buyerId,
        'to_establishment_id': selectedEstab.value!.id,
        'points': totalCost,
        'type': 'purchase',
        'voucher_count': couponsToBuy.value,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      // Attribuer les points de parrainage (50 points au parrain)
      await _attributeSponsorshipPoints(buyerId, 50);
      
      Get.back(); // Fermer la bottom sheet
      
      UniquesControllers().data.snackbar(
        'Succès',
        '${couponsToBuy.value} bon(s) acheté(s) pour $totalCost points',
        false,
      );
      
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de finaliser l\'achat: $e',
        true,
      );
    } finally {
      isBuying.value = false;
    }
  }
  
  void _performDonation() async {
    if (selectedEstab.value == null) return;
    
    final amount = int.tryParse(donationCtrl.text) ?? 0;
    
    if (amount <= 0) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Veuillez entrer un montant valide',
        true,
      );
      return;
    }
    
    if (buyerPoints.value < amount) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Vous n\'avez pas assez de points',
        true,
      );
      return;
    }
    
    isBuying.value = true;
    
    try {
      final batch = UniquesControllers().data.firebaseFirestore.batch();
      final buyerId = UniquesControllers().data.firebaseAuth.currentUser!.uid;
      
      // Déduire les points du donateur
      final buyerRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(buyerId);
      
      batch.update(buyerRef, {
        'points': FieldValue.increment(-amount),
      });
      
      // Ajouter les points à l'association
      final estabRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(selectedEstab.value!.id);
      
      batch.update(estabRef, {
        'points_received': FieldValue.increment(amount),
      });
      
      // Créer une transaction
      final transactionRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('transactions')
          .doc();
      
      batch.set(transactionRef, {
        'from_user_id': buyerId,
        'to_establishment_id': selectedEstab.value!.id,
        'points': amount,
        'type': 'donation',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      Get.back(); // Fermer la bottom sheet
      
      UniquesControllers().data.snackbar(
        'Succès',
        'Don de $amount points effectué',
        false,
      );
      
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de finaliser le don: $e',
        true,
      );
    } finally {
      isBuying.value = false;
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    if (selectedEstab.value == null) return [];
    
    final tName = userTypeNameCache[selectedEstab.value!.userId] ?? '';
    
    if (tName == 'Boutique') {
      // Interface pour acheter des bons
      return [
        // Informations sur le commerce
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedEstab.value!.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prix par bon: $pointPerCoupon points',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Slider pour sélectionner le nombre de bons
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nombre de bons',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${couponsToBuy.value}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomTheme.lightScheme().primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Le slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: CustomTheme.lightScheme().primary,
                inactiveTrackColor: CustomTheme.lightScheme().primary.withOpacity(0.2),
                thumbColor: CustomTheme.lightScheme().primary,
                overlayColor: CustomTheme.lightScheme().primary.withOpacity(0.2),
                valueIndicatorColor: CustomTheme.lightScheme().primary,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: couponsToBuy.value.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '${couponsToBuy.value} bon${couponsToBuy.value > 1 ? 's' : ''}',
                onChanged: (value) {
                  couponsToBuy.value = value.round();
                },
              ),
            ),
            
            // Indicateurs des valeurs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('2', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('3', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('4', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        )),
        
        const SizedBox(height: 20),
        
        // Total à payer
        Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CustomTheme.lightScheme().primary.withOpacity(0.05),
                CustomTheme.lightScheme().primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CustomTheme.lightScheme().primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total à payer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${couponsToBuy.value * pointPerCoupon} points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CustomTheme.lightScheme().primary,
                ),
              ),
            ],
          ),
        )),
        
        // Solde actuel
        Obx(() => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Votre solde: ${buyerPoints.value} points',
            style: TextStyle(
              fontSize: 14,
              color: (buyerPoints.value >= couponsToBuy.value * pointPerCoupon)
                  ? Colors.green[700]
                  : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        )),
      ];
      
    } else if (tName == 'Association') {
      // Interface pour faire un don
      return [
        // Informations sur l'association
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedEstab.value!.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Association',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Champ pour le montant du don
        TextField(
          controller: donationCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Montant du don (points)',
            prefixIcon: const Icon(Icons.volunteer_activism),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            donationAmount.value = int.tryParse(value) ?? 0;
          },
        ),
        
        // Solde actuel
        Obx(() => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Votre solde: ${buyerPoints.value} points',
            style: TextStyle(
              fontSize: 14,
              color: (buyerPoints.value >= donationAmount.value && donationAmount.value > 0)
                  ? Colors.green[700]
                  : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        )),
      ];
    }
    
    return [];
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
  
  Future<void> _attributeSponsorshipPoints(String userId, int points) async {
    try {
      // Rechercher si cet utilisateur a un parrain
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userEmail = userDoc.data()?['email']?.toLowerCase();
      if (userEmail == null) return;
      
      // Rechercher le document sponsorship où cet email apparaît
      final sponsorshipQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .get();
      
      for (var doc in sponsorshipQuery.docs) {
        final sponsorshipData = doc.data();
        final details = sponsorshipData['sponsorship_details'] as Map<String, dynamic>?;
        
        if (details != null && details.containsKey(userEmail)) {
          // Cet utilisateur a un parrain
          final sponsorId = sponsorshipData['user_id'];
          
          // Ajouter les points au wallet du parrain
          final walletQuery = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('wallets')
              .where('user_id', isEqualTo: sponsorId)
              .limit(1)
              .get();
          
          if (walletQuery.docs.isNotEmpty) {
            await walletQuery.docs.first.reference.update({
              'points': FieldValue.increment(points),
            });
          }
          
          // Mettre à jour les détails du parrainage
          final userDetail = details[userEmail] as Map<String, dynamic>;
          userDetail['total_earnings'] = (userDetail['total_earnings'] ?? 0) + points;
          
          // Ajouter à l'historique des gains
          List<dynamic> history = userDetail['earnings_history'] ?? [];
          history.add({
            'date': FieldValue.serverTimestamp(),
            'points': points,
            'reason': 'purchase',
          });
          userDetail['earnings_history'] = history;
          
          details[userEmail] = userDetail;
          
          // Mettre à jour le document sponsorship
          await doc.reference.update({
            'sponsorship_details': details,
            'total_earnings': FieldValue.increment(points),
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          break; // Un utilisateur ne peut avoir qu'un seul parrain
        }
      }
    } catch (e) {
      print('Erreur lors de l\'attribution des points de parrainage: $e');
    }
  }
}
