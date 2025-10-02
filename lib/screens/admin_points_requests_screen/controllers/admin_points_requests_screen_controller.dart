import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/points_request.dart';

class AdminPointsRequestsScreenController extends GetxController
    with ControllerMixin {
  String pageTitle = 'Gestion des Bons Cadeaux'.toUpperCase();
  String customBottomAppBarTag = 'admin-points-requests-bottom-app-bar';

  // Collection de bons renouvelés vendus (au lieu de requests)
  final RxList<Map<String, dynamic>> renewedVouchersSold = <Map<String, dynamic>>[].obs;

  // Pour compatibilité temporaire avec le code existant
  final RxList<PointsRequest> requests = <PointsRequest>[].obs;

  // Filtered requests
  List<PointsRequest>? get filteredRequests {
    var filtered = requests.toList();

    // Filtre par recherche
    if (searchText.value.isNotEmpty) {
      final search = searchText.value.toLowerCase();
      filtered = filtered.where((request) {
        final userName = getUserName(request.userId).toLowerCase();
        final userEmail = getUserEmail(request.userId).toLowerCase();
        final estabName = getEstabName(request.establishmentId).toLowerCase();
        final couponsStr = request.couponsCount.toString();

        return userName.contains(search) ||
            userEmail.contains(search) ||
            estabName.contains(search) ||
            couponsStr.contains(search);
      }).toList();
    }

    // Filtre par statut de validation
    if (filterValidated.value == 'validated') {
      filtered = filtered.where((r) => r.isValidated).toList();
    } else if (filterValidated.value == 'pending') {
      filtered = filtered.where((r) => !r.isValidated).toList();
    }

    // Tri
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortColumnIndex.value) {
        case 0: // Date
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 1: // Nom
          comparison = getUserName(a.userId).compareTo(getUserName(b.userId));
          break;
        case 2: // Email
          comparison = getUserEmail(a.userId).compareTo(getUserEmail(b.userId));
          break;
        case 3: // Bons
          comparison = a.couponsCount.compareTo(b.couponsCount);
          break;
      }

      return sortAscending.value ? comparison : -comparison;
    });

    return filtered;
  }

  // Stats calculées
  Map<String, int> get requestStats {
    final total = requests.length;
    final validated = requests.where((r) => r.isValidated).length;
    final pending = requests.where((r) => !r.isValidated).length;
    final totalCoupons =
        requests.fold<int>(0, (sum, r) => sum + r.couponsCount);

    return {
      'total': total,
      'validated': validated,
      'pending': pending,
      'totalCoupons': totalCoupons,
    };
  }

  // Sorting
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = false.obs; // Plus récent d'abord par défaut

  // Filtering
  final RxString searchText = ''.obs;
  final RxString filterValidated = 'all'.obs; // all, validated, pending

  // We store user names/emails and establishment names in these caches
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> userEmailCache = <String, String>{}.obs;
  final RxMap<String, String> estabNameCache = <String, String>{}.obs;

  // Firestore subscription
  StreamSubscription<QuerySnapshot>? _sub;

  // For the AlertDialog
  PointsRequest? tempPointsRequest;

  // For the bottom sheet => creation of new request
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController searchEmailCtrl = TextEditingController();
  final TextEditingController couponsCountCtrl = TextEditingController();

  // For dynamic searching => we only want userType == "Boutique"
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxString selectedUserId = ''.obs;
  final RxString selectedUserEmail = ''.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // MODIFIÉ: Écouter TOUS les bons (normaux + renouvelés)
    _sub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('vouchers')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((querySnap) {
      final allVouchers = <Map<String, dynamic>>[];

      for (var doc in querySnap.docs) {
        final data = doc.data();
        // Déterminer si c'est un bon renouvelé
        final isRenewed = data['is_renewed'] == true;

        allVouchers.add({
          'id': doc.id,
          'establishment_id': data['establishment_id'] ?? '',
          'establishment_name': data['establishment_name'] ?? 'Boutique inconnue',
          'buyer_id': data['buyer_id'] ?? '', // Acheteur ou boutique qui renouvelle
          'final_buyer_id': data['final_buyer_id'] ?? '', // Client final si bon renouvelé vendu
          'code': data['voucher_code'] ?? data['code'] ?? '',
          'value': data['value'] ?? data['points_value'] ?? 50,
          'is_renewed': isRenewed,
          'renewal_cost': isRenewed ? (data['renewal_cost'] ?? 15) : 0,
          'ventemoi_owes': isRenewed ? (data['ventemoi_owes'] ?? 35) : 0,
          'renewal_date': data['renewal_date'],
          'created_at': data['created_at'],
          'status': data['status'] ?? 'active',
          'used_at': data['used_at'],
          'payment_status': isRenewed ? (data['payment_status'] ?? 'pending') : 'not_applicable',
          'payment_date': data['payment_date'],
        });
      }

      renewedVouchersSold.value = allVouchers;
    });

    // 2) Watch for changes to userNameCache, userEmailCache, or estabNameCache
    //    so we can trigger a refresh => the "..." placeholders are replaced.
    ever(userNameCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requests.refresh();
      });
    });
    ever(userEmailCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requests.refresh();
      });
    });
    ever(estabNameCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requests.refresh();
      });
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    searchEmailCtrl.dispose();
    couponsCountCtrl.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // NOUVEAU: Marquer un bon renouvelé comme payé
  // ---------------------------------------------------------------------------
  Future<void> markAsPaid(String voucherId) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('vouchers')
          .doc(voucherId)
          .update({
        'payment_status': 'paid',
        'payment_date': DateTime.now().toIso8601String(),
      });

      UniquesControllers().data.snackbar(
        'Succès',
        'Paiement marqué comme effectué',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de marquer le paiement: $e',
        true,
      );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Filtrer pour afficher uniquement les bons renouvelés qui ont été vendus
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredVouchers {
    // Filtrer uniquement les bons renouvelés qui ont été vendus
    // is_renewed = true ET (status = 'used' OU final_buyer_id non vide)
    var filtered = renewedVouchersSold.where((v) {
      final isRenewed = v['is_renewed'] == true;
      final status = v['status'] ?? '';
      final hasFinalBuyer = v['final_buyer_id'] != null && v['final_buyer_id'].toString().isNotEmpty;

      // Seulement les bons renouvelés qui ont été vendus
      return isRenewed && (status == 'used' || hasFinalBuyer);
    }).toList();

    // Appliquer le filtre de recherche
    if (searchText.value.isNotEmpty) {
      final search = searchText.value.toLowerCase();
      filtered = filtered.where((v) {
        final establishmentName = (v['establishment_name'] ?? '').toString().toLowerCase();
        final code = (v['code'] ?? '').toString().toLowerCase();
        final value = v['value'].toString();

        return establishmentName.contains(search) ||
               code.contains(search) ||
               value.contains(search);
      }).toList();
    }

    return filtered;
  }

  // ---------------------------------------------------------------------------
  // Calculer le total dû par VenteMoi
  // ---------------------------------------------------------------------------
  double get totalOwed {
    return filteredVouchers
        .where((v) => v['payment_status'] != 'paid')
        .fold(0.0, (sum, v) {
          // Tous sont des bons renouvelés vendus : VenteMoi doit 35€
          return sum + (v['ventemoi_owes'] ?? 35);
        });
  }

  double get totalPaid {
    return filteredVouchers
        .where((v) => v['payment_status'] == 'paid')
        .fold(0.0, (sum, v) {
          // Tous sont des bons renouvelés vendus : VenteMoi a payé 35€
          return sum + (v['ventemoi_owes'] ?? 35);
        });
  }

  // ---------------------------------------------------------------------------
  // Search and filtering
  // ---------------------------------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value;
  }

  // ---------------------------------------------------------------------------
  // Fetching user info => name + email
  // ---------------------------------------------------------------------------
  String getUserName(String userId) {
    if (userId.isEmpty) return 'Utilisateur inconnu';

    // If we already have it cached, return it
    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }

    // Otherwise, put a placeholder and fetch async
    userNameCache[userId] = '...';
    userEmailCache[userId] = '...';

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snap) {
      String resolvedName = 'Inconnu';
      String resolvedEmail = 'Inconnu';
      if (snap.exists) {
        final data = snap.data();
        resolvedName = data?['name'] ?? 'Anonyme';
        resolvedEmail = data?['email'] ?? 'Anonyme';
      }
      // Update after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNameCache[userId] = resolvedName;
        userEmailCache[userId] = resolvedEmail;
      });
    }).catchError((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNameCache[userId] = 'Inconnu';
        userEmailCache[userId] = 'Inconnu';
      });
    });

    return userNameCache[userId]!; // might be '...' or 'Inconnu'
  }

  String getUserEmail(String userId) {
    if (userId.isEmpty) return '...';
    // Could still be '...' or 'Inconnu'
    return userEmailCache[userId] ?? '...';
  }

  // ---------------------------------------------------------------------------
  // Fetching establishment name
  // ---------------------------------------------------------------------------
  String getEstabName(String estabId) {
    if (estabId.isEmpty) return 'Établissement inconnu';
    if (estabNameCache.containsKey(estabId)) {
      return estabNameCache[estabId]!;
    }
    estabNameCache[estabId] = '...';

    FirebaseFirestore.instance
        .collection('establishments')
        .doc(estabId)
        .get()
        .then((snap) {
      String resolvedName = 'Inconnu';
      if (snap.exists) {
        final data = snap.data();
        resolvedName = data?['name'] ?? 'Sans nom';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        estabNameCache[estabId] = resolvedName;
      });
    }).catchError((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        estabNameCache[estabId] = 'Inconnu';
      });
    });

    return estabNameCache[estabId]!; // might be '...' or 'Inconnu'
  }

  // ---------------------------------------------------------------------------
  // Sorting
  // ---------------------------------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    requests.refresh(); // Trigger UI update
  }

  // ---------------------------------------------------------------------------
  // DataTable columns (legacy - kept for compatibility)
  // ---------------------------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Date'),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        const DataColumn(label: Text('Nom')),
        const DataColumn(label: Text('Email')),
        const DataColumn(label: Text('Établissement')),
        const DataColumn(label: Text('Bons demandés')),
        const DataColumn(label: Text('Validé ?')),
      ];

  // ---------------------------------------------------------------------------
  // Build rows (legacy - kept for compatibility)
  // ---------------------------------------------------------------------------
  List<DataRow> get dataRows {
    return List.generate(requests.length, (i) {
      final pr = requests[i];
      final dateFr = _formatDate(pr.createdAt);

      final userName = getUserName(pr.userId);
      final userEmail = getUserEmail(pr.userId);
      final estabName = getEstabName(pr.establishmentId);

      return DataRow(
        cells: [
          DataCell(CustomCardAnimation(index: i, child: Text(dateFr))),
          DataCell(CustomCardAnimation(index: i + 1, child: Text(userName))),
          DataCell(CustomCardAnimation(index: i + 2, child: Text(userEmail))),
          DataCell(CustomCardAnimation(index: i + 3, child: Text(estabName))),
          DataCell(CustomCardAnimation(
              index: i + 4, child: Text('${pr.couponsCount}'))),
          DataCell(
            CustomCardAnimation(
              index: i + 5,
              child: Switch(
                thumbColor: WidgetStateProperty.all(Colors.black),
                value: pr.isValidated,
                onChanged: pr.isValidated
                    ? null
                    : (val) async {
                        tempPointsRequest = pr;
                        openAlertDialog(
                          '${pr.couponsCount} bons pour $userName',
                          confirmText: 'Valider',
                        );
                      },
              ),
            ),
          ),
        ],
      );
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // AlertDialog => validation
  // ---------------------------------------------------------------------------

  @override
  Future<void> actionAlertDialog() async {
    final pr = tempPointsRequest;
    if (pr == null) return;

    try {
      // Mark isValidated = true
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_requests')
          .doc(pr.id)
          .update({'isValidated': true});

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc(pr.walletId)
          .update({
        'coupons': FieldValue.increment(pr.couponsCount),
      });

      UniquesControllers().data.snackbar(
            'Succès',
            'Demande validée et ${pr.couponsCount} bons crédités.',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      tempPointsRequest = null;
    }
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET => Attribuer des bons
  // ---------------------------------------------------------------------------
  late Widget addCouponsFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.adminIconList.length,
    child: FloatingActionButton.extended(
      heroTag: UniqueKey().toString(),
      icon: const Icon(Icons.add),
      label: const Text('Attribuer des bons'),
      onPressed: () {
        openBottomSheet(
          'Attribuer des Bons à une Boutique',
          actionName: 'Créer',
          actionIcon: Icons.check,
        );
      },
    ),
  );

  @override
  void variablesToResetToBottomSheet() {
    formKey.currentState?.reset();
    searchEmailCtrl.clear();
    couponsCountCtrl.clear();
    searchResults.clear();
    selectedUserId.value = '';
    selectedUserEmail.value = '';
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            CustomTextFormField(
              tag: 'email-boutique',
              controller: searchEmailCtrl,
              labelText: 'Email Boutique',
              onChanged: (val) async {
                await _searchBoutiqueByEmail(val.trim().toLowerCase());
              },
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Entrez un email';
                }
                final pattern = RegExp(r'^.+@[a-zA-Z]+\.[a-zA-Z]+$');
                if (!pattern.hasMatch(val.trim())) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const CustomSpace(heightMultiplier: 1),
            Obx(() {
              if (searchResults.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: searchResults.map((doc) {
                  final email = doc['email'] as String;
                  final uid = doc['uid'] as String;
                  return SizedBox(
                    width: UniquesControllers().data.baseMaxWidth,
                    child: Card(
                      child: ListTile(
                        title: Text(email),
                        onTap: () {
                          selectedUserEmail.value = email;
                          selectedUserId.value = uid;
                          searchResults.clear();
                          searchEmailCtrl.text = email;
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const CustomSpace(heightMultiplier: 1),
            CustomTextFormField(
              tag: 'coupons-count',
              controller: couponsCountCtrl,
              labelText: 'Nombre de bons',
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Entrez un nombre';
                }
                final nb = int.tryParse(val.trim()) ?? 0;
                if (nb <= 0) {
                  return 'Valeur invalide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  alertDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Êtes-vous sûr de vouloir valider cette demande ?',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cette action est irréversible. Les bons seront crédités sur le wallet de la boutique.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    if (selectedUserId.value.isEmpty) {
      UniquesControllers()
          .data
          .snackbar('Erreur', 'Veuillez sélectionner une boutique', true);
      return;
    }

    Get.back(); // close bottomSheet

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      final uid = selectedUserId.value;

      // 1) find the wallet doc
      final walletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();
      if (walletSnap.docs.isEmpty) {
        throw 'Le user n\'a pas de wallet.';
      }
      final walletId = walletSnap.docs.first.id;

      // 2) find the establishment doc
      final estSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();
      if (estSnap.docs.isEmpty) {
        throw 'L\'utilisateur n\'a pas d\'établissement.';
      }
      final estabId = estSnap.docs.first.id;

      final nb = int.parse(couponsCountCtrl.text.trim());
      final docRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_requests')
          .doc();
      await docRef.set({
        'user_id': uid,
        'wallet_id': walletId,
        'establishment_id': estabId,
        'coupons_count': nb,
        'isValidated': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc(walletId)
          .update({
        'coupons': FieldValue.increment(nb),
      });

      UniquesControllers().data.snackbar('Succès',
          'Attribution de $nb bons pour ${selectedUserEmail.value}', false);
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Searching for "Boutique" user by partial email
  // ---------------------------------------------------------------------------
  Future<void> _searchBoutiqueByEmail(String input) async {
    searchResults.clear();
    if (input.isEmpty) {
      return;
    }

    // 1) find userTypeDocId for "Boutique"
    final boutiqueSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .where('name', isEqualTo: 'Boutique')
        .limit(1)
        .get();
    if (boutiqueSnap.docs.isEmpty) {
      return;
    }
    final boutiqueTypeId = boutiqueSnap.docs.first.id;

    // 2) load up to 10 "Boutique" users
    final usersSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('user_type_id', isEqualTo: boutiqueTypeId)
        .limit(10)
        .get();

    // 3) filter them by partial email
    final docs = usersSnap.docs;
    final filtered = <Map<String, dynamic>>[];
    for (final d in docs) {
      final data = d.data();
      final email = (data['email'] ?? '').toString().toLowerCase();
      if (email.contains(input)) {
        filtered.add({
          'uid': d.id,
          'email': email,
        });
      }
    }
    searchResults.value = filtered;
  }
}
