import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/point_attribution.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class AdminPointsAttributionsScreenController extends GetxController
    with ControllerMixin {
  // Screen Info
  String pageTitle = 'Attributions de Points'.toUpperCase();
  String customBottomAppBarTag = 'admin-points-attributions-bottom-app-bar';

  // Sorting
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  // Main list of attributions (reactive)
  final RxList<PointAttribution> attributions = <PointAttribution>[].obs;

  // Cache for user names => KEY: userId, VALUE: userName
  // Also store user emails in a separate cache if you want to show them (optional).
  final RxMap<String, String> userNameCache = <String, String>{}.obs;
  final RxMap<String, String> userEmailCache = <String, String>{}.obs;

  // Subscription to the collection
  StreamSubscription<List<PointAttribution>>? _sub;

  // If we need to store an attribution for an AlertDialog
  PointAttribution? tempAttribution;

  // ----------------------------------------------------------
  // For the BottomSheet (to create a new attribution)
  // ----------------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController searchEmailCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController pointsCtrl = TextEditingController();

  // For dynamic searching => now for ANY user type
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxString selectedUserId = ''.obs;
  final RxString selectedUserEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // 1) Listen to the "points_attributions" collection
    _sub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_attributions')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PointAttribution.fromDocument(doc)).toList())
        .listen((list) {
      // Sort by date descending by default
      list.sort((a, b) => b.date.compareTo(a.date));
      attributions.value = list;
    });

    // 2) Watch for changes in userNameCache or userEmailCache => force a re-build
    ever(userNameCache, (_) {
      // Force a refresh of the table
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attributions.refresh();
      });
    });
    ever(userEmailCache, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attributions.refresh();
      });
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ----------------------------------------------------------
  // Get user name/email from Firestore
  // ----------------------------------------------------------
  String getUserName(String userId) {
    if (userId.isEmpty) return 'Inconnu';
    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }
    // placeholder
    userNameCache[userId] = '...';
    userEmailCache[userId] = '...';

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snap) {
      if (!snap.exists) {
        userNameCache[userId] = 'Inconnu';
        userEmailCache[userId] = 'Inconnu';
        return;
      }
      final data = snap.data() ?? {};
      final name = data['name'] ?? 'Sans nom';
      final email = data['email'] ?? '...';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNameCache[userId] = name;
        userEmailCache[userId] = email;
      });
    }).catchError((_) {
      userNameCache[userId] = 'Inconnu';
      userEmailCache[userId] = 'Inconnu';
    });

    return userNameCache[userId] ?? '...';
  }

  String getUserEmail(String userId) {
    if (userId.isEmpty) return '...';
    return userEmailCache[userId] ?? '...';
  }

  // ----------------------------------------------------------
  // Sorting
  // ----------------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;

    final sorted = attributions.toList();
    switch (colIndex) {
      case 0: // date
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 1: // giver name => nous n’avons qu’un ID -> skip ou géré autrement
        break;
      case 2: // target name => skip ou géré autrement
        break;
      case 3: // cost
        sorted.sort((a, b) => a.cost.compareTo(b.cost));
        break;
      case 4: // points
        sorted.sort((a, b) => a.points.compareTo(b.points));
        break;
      case 5: // commissionPercent
        sorted
            .sort((a, b) => a.commissionPercent.compareTo(b.commissionPercent));
        break;
      case 6: // commissionCost
        sorted.sort((a, b) => a.commissionCost.compareTo(b.commissionCost));
        break;
      // case 7 => validated => skip
    }
    if (!asc) {
      sorted.reversed;
    }
    attributions.value = sorted;
  }

  // ----------------------------------------------------------
  // DataTable columns
  // ----------------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label: const Text('Date'),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        const DataColumn(label: Text('Attribué par')),
        const DataColumn(label: Text('Cible')),
        const DataColumn(label: Text('Coût (€)')),
        const DataColumn(label: Text('Points')),
        // -- NOUVEAU : Commission %
        const DataColumn(label: Text('Comm. %')),
        // -- NOUVEAU : Commission €
        const DataColumn(label: Text('Comm. €')),
        const DataColumn(label: Text('Validé ?')),
      ];

  // ----------------------------------------------------------
  // DataTable rows
  // ----------------------------------------------------------
  List<DataRow> get dataRows {
    return List.generate(attributions.length, (i) {
      final att = attributions[i];
      final dateFr = _formatDate(att.date);
      final giverName = getUserName(att.giverId);
      final targetName = getUserName(att.targetId);
      final targetEmail = getUserEmail(att.targetId);

      return DataRow(
        cells: [
          // 1) Date
          DataCell(
            CustomCardAnimation(
              index: i,
              child: Text(dateFr),
            ),
          ),
          // 2) Attribué par
          DataCell(
            CustomCardAnimation(
              index: i + 1,
              child: Text(giverName),
            ),
          ),
          // 3) Cible
          DataCell(
            CustomCardAnimation(
              index: i + 2,
              child: Text('$targetName\n($targetEmail)'),
            ),
          ),
          // 4) Coût
          DataCell(
            CustomCardAnimation(
              index: i + 3,
              child: Text(att.cost.toStringAsFixed(2)),
            ),
          ),
          // 5) Points
          DataCell(
            CustomCardAnimation(
              index: i + 4,
              child: Text('${att.points}'),
            ),
          ),
          // 6) Commission %
          DataCell(
            CustomCardAnimation(
              index: i + 5,
              child: Text(
                '${att.commissionPercent.toStringAsFixed(2)} %',
              ),
            ),
          ),
          // 7) Commission €
          DataCell(
            CustomCardAnimation(
              index: i + 6,
              child: Text('${att.commissionCost}'),
            ),
          ),
          // 8) Validé ?
          DataCell(
            CustomCardAnimation(
              index: i + 7,
              child: Switch(
                thumbColor: WidgetStateProperty.all(Colors.black),
                value: att.validated,
                onChanged: att.validated
                    ? null
                    : (val) async {
                        tempAttribution = att;
                        openAlertDialog('Valider cette attribution ?',
                            confirmText: 'Valider');
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

  // ----------------------------------------------------------
  // AlertDialog => validation
  // ----------------------------------------------------------
  @override
  Future<void> actionAlertDialog() async {
    if (tempAttribution == null) return;

    try {
      // 1) On marque validated=true dans Firestore
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_attributions')
          .doc(tempAttribution!.id)
          .update({'validated': true});

      // 2) Incrémentation du wallet de la cible
      final targetWalletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: tempAttribution!.targetId)
          .limit(1)
          .get();

      if (targetWalletSnap.docs.isNotEmpty) {
        final wid = targetWalletSnap.docs.first.id;
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc(wid)
            .update({'points': FieldValue.increment(tempAttribution!.points)});
      }

      // 3) Logique de parrainage => 40% des points, arrondi à l'inférieur
      final emailCible = tempAttribution!.targetEmail.trim().toLowerCase();
      final pointsCible = tempAttribution!.points;
      await _handleSponsorshipReward(emailCible, pointsCible);

      UniquesControllers()
          .data
          .snackbar('Succès', 'Attribution validée.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      tempAttribution = null;
    }
  }

  /// Vérifie si [targetEmail] est présent dans sponsoredEmails d'un doc
  /// de la collection 'sponsorships'. Si oui, on attribue 40% arrondi
  /// à l'inférieur de [targetPoints] au parrain, et on envoie un mail.
  Future<void> _handleSponsorshipReward(
    String targetEmail,
    int targetPoints,
  ) async {
    if (targetEmail.isEmpty || targetPoints <= 0) {
      return;
    }

    // 1) On recherche un doc "sponsorship" qui contient targetEmail
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('sponsoredEmails', arrayContains: targetEmail)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return; // Aucun parrainage ne correspond
    }

    final sponsorshipDoc = snap.docs.first;
    final sponsorData = sponsorshipDoc.data();
    final sponsorUid = sponsorData['user_id'] ?? '';
    if (sponsorUid.isEmpty) {
      return;
    }

    // 2) Calcul 40% arrondi à l'inférieur
    final reward = (targetPoints * 0.4).floor();
    if (reward <= 0) {
      return;
    }

    // 3) Incrémentation du wallet du parrain
    final sponsorWalletSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: sponsorUid)
        .limit(1)
        .get();

    if (sponsorWalletSnap.docs.isEmpty) {
      // Création d'un nouveau wallet si besoin
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': sponsorUid,
        'points': reward,
        'coupons': 0,
      });
    } else {
      final sponsorWalletRef = sponsorWalletSnap.docs.first.reference;
      await sponsorWalletRef.update({
        'points': FieldValue.increment(reward),
      });
    }

    // 4) Envoi d'un mail au parrain => "Vous gagnez X points grâce à [targetEmail]"
    final sponsorUserSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(sponsorUid)
        .get();

    if (!sponsorUserSnap.exists) return;
    final sponsorUserData = sponsorUserSnap.data()!;
    final sponsorEmail = (sponsorUserData['email'] ?? '').toString().trim();
    final sponsorName = (sponsorUserData['name'] ?? 'Sponsor').toString();

    if (sponsorEmail.isNotEmpty) {
      // Envoi via un helper du mixin
      await sendSponsorshipMailForAttribution(
        sponsorName: sponsorName,
        sponsorEmail: sponsorEmail,
        filleulEmail: targetEmail,
        pointsWon: reward,
      );
    }

    // 5) On retire l'email pour ne pas réattribuer 40% la prochaine fois
    await sponsorshipDoc.reference.update({
      'sponsoredEmails': FieldValue.arrayRemove([targetEmail])
    });
  }

  // ----------------------------------------------------------
  // FAB + BottomSheet => attribute points to ANY user
  // ----------------------------------------------------------
  late Widget addPointsFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.adminIconList.length,
    child: FloatingActionButton.extended(
      heroTag: UniqueKey().toString(),
      icon: const Icon(Icons.add),
      label: const Text('Attribuer des Points'),
      onPressed: () {
        openBottomSheet(
          'Attribuer des Points',
          actionName: 'Valider',
          actionIcon: Icons.check,
        );
      },
    ),
  );

  // The form fields for the bottom sheet
  final GlobalKey<FormState> bottomSheetFormKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController pointsToGiveCtrl = TextEditingController();
  final RxList<Map<String, dynamic>> searchAnyUserResults =
      <Map<String, dynamic>>[].obs;
  final RxString chosenUserId = ''.obs;
  final RxString chosenUserEmail = ''.obs;

  @override
  void variablesToResetToBottomSheet() {
    bottomSheetFormKey.currentState?.reset();
    emailCtrl.clear();
    pointsToGiveCtrl.clear();
    searchAnyUserResults.clear();
    chosenUserId.value = '';
    chosenUserEmail.value = '';
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: bottomSheetFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Email => search
            CustomTextFormField(
              tag: 'any-email-search',
              controller: emailCtrl,
              labelText: 'Email utilisateur',
              onChanged: (val) async {
                await _searchAnyUserByEmail(val.trim().toLowerCase());
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
            Obx(() {
              if (searchAnyUserResults.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: searchAnyUserResults.map((userDoc) {
                  final uid = userDoc['uid'] ?? '';
                  final email = userDoc['email'] ?? '';
                  return SizedBox(
                    width: UniquesControllers().data.baseMaxWidth,
                    child: Card(
                      child: ListTile(
                        title: Text(email),
                        onTap: () {
                          chosenUserId.value = uid;
                          chosenUserEmail.value = email;
                          searchAnyUserResults.clear();
                          emailCtrl.text = email;
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const CustomSpace(heightMultiplier: 2),
            CustomTextFormField(
              tag: 'any-points-text-field',
              controller: pointsToGiveCtrl,
              labelText: 'Points à attribuer',
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Entrez un nombre de points';
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
  Future<void> actionBottomSheet() async {
    if (!bottomSheetFormKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    if (chosenUserId.value.isEmpty) {
      UniquesControllers()
          .data
          .snackbar('Erreur', 'Veuillez sélectionner un utilisateur', true);
      return;
    }

    Get.back(); // close bottomSheet

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      final targetUid = chosenUserId.value;
      final pointsInt = int.parse(pointsToGiveCtrl.text.trim());

      // Create a doc in `points_attributions`, validated = true immediately or false, up to you
      final docRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_attributions')
          .doc();
      await docRef.set({
        'giver_id': UniquesControllers().data.firebaseAuth.currentUser!.uid,
        'target_id': targetUid,
        'target_email': chosenUserEmail.value,
        'date': DateTime.now(),
        'cost': 0,
        'points': pointsInt,
        'validated': true, // or false if you want a second step
      });

      // Then increment user’s wallet points
      final walletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: targetUid)
          .limit(1)
          .get();

      if (walletSnap.docs.isEmpty) {
        // Possibly create a new wallet doc
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc()
            .set({
          'user_id': targetUid,
          'points': pointsInt,
          'coupons': 0,
        });
      } else {
        final walletDocId = walletSnap.docs.first.id;
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc(walletDocId)
            .update({'points': FieldValue.increment(pointsInt)});
      }

      UniquesControllers().data.snackbar(
          'Succès',
          'Attribution de $pointsInt points pour ${chosenUserEmail.value}',
          false);
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ----------------------------------------------------------
  // Searching any user by partial email (not restricting to "Boutique")
  // ----------------------------------------------------------
  Future<void> _searchAnyUserByEmail(String input) async {
    searchAnyUserResults.clear();
    if (input.isEmpty) {
      return;
    }

    // Load up to 10 users whose email contains [input]
    final usersSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .limit(10)
        .get();

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
    searchAnyUserResults.value = filtered;
  }

  // ----------------------------------------------------------
  // Simple AlertDialog content override (optional)
  // ----------------------------------------------------------
  @override
  Widget alertDialogContent() {
    return const Text('Voulez-vous valider cette attribution ?');
  }
}
