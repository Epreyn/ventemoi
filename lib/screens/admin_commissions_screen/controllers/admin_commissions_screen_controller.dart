import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/commission.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class AdminCommissionsScreenController extends GetxController
    with ControllerMixin {
  // Liste observable des commissions
  RxList<Commission> commissionsList = <Commission>[].obs;
  StreamSubscription<List<Commission>>? _sub;

  // Formulaire
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController minCtrl = TextEditingController();
  final TextEditingController maxCtrl = TextEditingController();
  final TextEditingController percentCtrl = TextEditingController();
  final TextEditingController assocPercentCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  // Indique si on est en mode édition
  RxBool isEditMode = false.obs;
  String? editingCommissionId;

  // isInfinite => pour cocher/décocher, on gère un RxBool
  RxBool isInfiniteCheck = false.obs;

  // Recherche email => possesseur d’entreprise
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;

  // Commission à supprimer
  Commission? commissionToDelete;

  @override
  void onInit() {
    super.onInit();
    // Souscription => "commissions"
    _sub = _listenCommissions().listen((list) {
      // Par exemple, trier par minAmount croissant
      list.sort((a, b) => a.minAmount.compareTo(b.minAmount));
      commissionsList.value = list;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Stream<List<Commission>> _listenCommissions() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('commissions')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Commission.fromDocument(doc)).toList());
  }

  // -----------------------------
  // Ouvrir bottomSheet => creation
  // -----------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    editingCommissionId = null;
    _resetForm();
    openBottomSheet('Nouvelle commission',
        actionName: 'Créer', actionIcon: Icons.check);
  }

  // -----------------------------
  // Ouvrir bottomSheet => edition
  // -----------------------------
  void openEditBottomSheet(Commission c) {
    isEditMode.value = true;
    editingCommissionId = c.id;
    _resetForm(c);
    openBottomSheet('Modifier la commission',
        actionName: 'Enregistrer', actionIcon: Icons.save);
  }

  void _resetForm([Commission? c]) {
    if (c != null) {
      minCtrl.text = '${c.minAmount}';
      maxCtrl.text = '${c.maxAmount}';
      percentCtrl.text = '${c.percentage}';
      assocPercentCtrl.text = '${c.associationPercentage}';
      emailCtrl.text = c.emailException;
      isInfiniteCheck.value = c.isInfinite;
    } else {
      minCtrl.clear();
      maxCtrl.clear();
      percentCtrl.clear();
      assocPercentCtrl.clear();
      emailCtrl.clear();
      isInfiniteCheck.value = false;
      searchResults.clear();
    }
  }

  @override
  void variablesToResetToBottomSheet() {
    if (!isEditMode.value) _resetForm();
  }

  // -----------------------------
  // Validation du BottomSheet
  // -----------------------------
  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    Get.back(); // ferme

    final minVal = double.tryParse(minCtrl.text.trim()) ?? 0.0;
    double maxVal = double.tryParse(maxCtrl.text.trim()) ?? 0.0;
    final perc = double.tryParse(percentCtrl.text.trim()) ?? 0.0;
    final assocPerc = double.tryParse(assocPercentCtrl.text.trim()) ?? 0.0;
    final emailExcept = emailCtrl.text.trim().toLowerCase();
    final isInf = isInfiniteCheck.value;

    // Si isInfinite => on force maxVal=0
    if (isInf) {
      maxVal = 0;
    }

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      if (isEditMode.value && editingCommissionId != null) {
        await _updateCommission(editingCommissionId!, minVal, maxVal, perc,
            isInf, assocPerc, emailExcept);
      } else {
        await _createCommission(
            minVal, maxVal, perc, isInf, assocPerc, emailExcept);
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<void> _createCommission(
    double min,
    double max,
    double perc,
    bool isInf,
    double assocPerc,
    String emailExc,
  ) async {
    final docRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('commissions')
        .doc();
    await docRef.set({
      'min_amount': min,
      'max_amount': max,
      'percentage': perc,
      'isInfinite': isInf,
      'association_percentage': assocPerc,
      'email_exception': emailExc,
    });
    UniquesControllers().data.snackbar('Succès', 'Commission créée.', false);
  }

  Future<void> _updateCommission(
    String docId,
    double min,
    double max,
    double perc,
    bool isInf,
    double assocPerc,
    String emailExc,
  ) async {
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('commissions')
        .doc(docId)
        .update({
      'min_amount': min,
      'max_amount': max,
      'percentage': perc,
      'isInfinite': isInf,
      'association_percentage': assocPerc,
      'email_exception': emailExc,
    });
    UniquesControllers()
        .data
        .snackbar('Succès', 'Commission mise à jour.', false);
  }

  // -----------------------------
  // Suppression
  // -----------------------------
  void deleteCommission(String docId) {
    final c = commissionsList.firstWhereOrNull((x) => x.id == docId);
    if (c == null) return;
    openDeleteAlertDialog(c);
  }

  void openDeleteAlertDialog(Commission c) {
    commissionToDelete = c;
    openAlertDialog('Supprimer cette commission ?',
        confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    if (commissionToDelete == null) {
      return const Text('Supprimer cette commission ?');
    }
    return Text(
      'Voulez-vous vraiment supprimer la commission:\n'
      'De ${commissionToDelete!.minAmount}€ '
      '${commissionToDelete!.isInfinite ? "jusqu\'à l\'infini" : "à ${commissionToDelete!.maxAmount}€"} '
      '=> ${commissionToDelete!.percentage}% ?',
    );
  }

  @override
  Future<void> actionAlertDialog() async {
    if (commissionToDelete == null) return;
    UniquesControllers().data.isInAsyncCall.value = true;
    final docId = commissionToDelete!.id;
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('commissions')
          .doc(docId)
          .delete();
      UniquesControllers()
          .data
          .snackbar('Succès', 'Commission supprimée.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      commissionToDelete = null;
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // -----------------------------
  // Recherche email => possesseurs d’entreprise
  // -----------------------------
  Future<void> searchEnterpriseByEmail(String input) async {
    final txt = input.trim().toLowerCase();
    if (txt.isEmpty) {
      searchResults.clear();
      return;
    }

    // On suppose que l'userType doc "Entreprise" = ?
    final snapType = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .where('name', isEqualTo: 'Entreprise')
        .limit(1)
        .get();
    if (snapType.docs.isEmpty) {
      searchResults.clear();
      return;
    }
    final enterpriseTypeId = snapType.docs.first.id;

    // on cherche dans users => user_type_id=enterpriseTypeId
    final snapUsers = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('user_type_id', isEqualTo: enterpriseTypeId)
        .limit(10)
        .get();

    final allDocs = snapUsers.docs.map((d) {
      final data = d.data();
      return {
        'uid': d.id,
        'email': (data['email'] ?? '').toString().toLowerCase(),
      };
    }).toList();

    final filtered =
        allDocs.where((m) => (m['email'] as String).contains(txt)).toList();
    searchResults.value = filtered;
  }

  // -----------------------------
  // BottomSheet children
  // -----------------------------
  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Montant min
            CustomTextFormField(
              tag: 'comm-min',
              controller: minCtrl,
              labelText: 'Montant minimum',
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Entrez un nombre valide';
                if (double.tryParse(val.trim()) == null)
                  return 'Nombre invalide';
                return null;
              },
            ),
            const CustomSpace(heightMultiplier: 2),

            // Row => Montant max + Checkbox isInfinite
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomSpace(
                  widthMultiplier: 8,
                ),
                Obx(
                  () => CustomTextFormField(
                    tag: 'comm-max',
                    controller: maxCtrl,
                    labelText: 'Montant maximum',
                    keyboardType: TextInputType.number,
                    enabled: !isInfiniteCheck.value,
                    validator: (val) {
                      if (isInfiniteCheck.value) return null; // skip
                      if (val == null || val.trim().isEmpty)
                        return 'Entrez un nombre valide';
                      if (double.tryParse(val.trim()) == null)
                        return 'Nombre invalide';
                      return null;
                    },
                  ),
                ),
                Obx(
                  () => Checkbox(
                    value: isInfiniteCheck.value,
                    onChanged: (val) {
                      if (val == null) return;
                      isInfiniteCheck.value = val;
                    },
                  ),
                ),
                const Text('Infini'),
              ],
            ),
            const CustomSpace(heightMultiplier: 2),

            // Commission percentage
            CustomTextFormField(
              tag: 'comm-percent',
              controller: percentCtrl,
              labelText: 'Pourcentage (%)',
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Entrez un pourcentage';
                if (double.tryParse(val.trim()) == null)
                  return 'Valeur invalide';
                return null;
              },
            ),
            const CustomSpace(heightMultiplier: 2),

            // associationPercentage
            CustomTextFormField(
              tag: 'comm-assoc-percent',
              controller: assocPercentCtrl,
              labelText: 'Pourcentage (Association)',
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                if (double.tryParse(val.trim()) == null)
                  return 'Valeur invalide';
                return null;
              },
            ),
            const CustomSpace(heightMultiplier: 2),

            // Email exception => champ + liste
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFormField(
                  tag: 'comm-email-exception',
                  controller: emailCtrl,
                  labelText: 'Email (Entreprise)',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) async {
                    await searchEnterpriseByEmail(val);
                  },
                  // Pas obligatoire => pas de validator
                ),
                Obx(() {
                  if (searchResults.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: searchResults.map((item) {
                      return SizedBox(
                        width: UniquesControllers().data.baseMaxWidth,
                        child: Card(
                          child: ListTile(
                            title: Text(item['email'] as String),
                            onTap: () {
                              emailCtrl.text = item['email'] as String;
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
          ],
        ),
      ),
    ];
  }
}
