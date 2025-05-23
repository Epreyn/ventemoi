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
  String pageTitle = 'Demandes de Bons'.toUpperCase();
  String customBottomAppBarTag = 'admin-points-requests-bottom-app-bar';

  // All points_requests docs
  final RxList<PointsRequest> requests = <PointsRequest>[].obs;

  // Sorting
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  // We store user names/emails and establishment names in these caches
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> userEmailCache = <String, String>{}.obs;
  final RxMap<String, String> estabNameCache = <String, String>{}.obs;

  // Firestore subscription
  StreamSubscription<List<PointsRequest>>? _sub;

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

    // 1) Listen to the 'points_requests' collection in Firestore
    _sub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_requests')
        .snapshots()
        .map((querySnap) {
      return querySnap.docs
          .map((doc) => PointsRequest.fromDocument(doc.id, doc.data()))
          .toList();
    }).listen((list) {
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      requests.value = list;
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
    super.onClose();
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

    final sorted = requests.toList();
    // For now, let's say colIndex=0 => date
    if (colIndex == 0) {
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!asc) sorted.reversed;
    }
    requests.value = sorted;
  }

  // ---------------------------------------------------------------------------
  // DataTable columns
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
  // Build rows
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
    return Text(
        'Êtes-vous sûr de vouloir valider cette demande ?\nCette action est irréversible.');
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
        throw 'Le user n’a pas de wallet.';
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
        throw 'L\'utilisateur n’a pas d’établissement.';
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
