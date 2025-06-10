import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController priorityCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();

  // États
  RxBool isEditMode = false.obs;
  String? editingCommissionId;
  RxBool isInfiniteCheck = false.obs;
  RxBool isDefaultCommission = false.obs;

  // Recherche email
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;

  // Simulateur
  final TextEditingController simulatorAmountCtrl = TextEditingController();
  final TextEditingController simulatorEmailCtrl = TextEditingController();
  Rx<Commission?> simulatedCommission = Rx<Commission?>(null);
  RxDouble simulatedCommissionAmount = 0.0.obs;

  // Commission à supprimer
  Commission? commissionToDelete;

  // Validation des conflits
  RxString validationMessage = ''.obs;
  RxBool hasConflict = false.obs;

  @override
  void onInit() {
    super.onInit();
    _sub = _listenCommissions().listen((list) {
      // Trier par priorité puis par minAmount
      list.sort((a, b) {
        final priorityCompare = (b.priority ?? 0).compareTo(a.priority ?? 0);
        if (priorityCompare != 0) return priorityCompare;
        return a.minAmount.compareTo(b.minAmount);
      });
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
  // Statistiques
  // -----------------------------
  Map<String, dynamic> getCommissionStatistics() {
    final total = commissionsList.length;
    final exceptions =
        commissionsList.where((c) => c.emailException.isNotEmpty).length;
    final average = total > 0
        ? commissionsList.map((c) => c.percentage).reduce((a, b) => a + b) /
            total
        : 0.0;

    return {
      'total': total,
      'exceptions': exceptions,
      'average': average,
    };
  }

  // -----------------------------
  // Validation des conflits
  // -----------------------------
  bool validateCommissionRange(double min, double max, bool isInfinite,
      String? excludeId, String emailException) {
    hasConflict.value = false;
    validationMessage.value = '';

    // Si c'est une exception email, on vérifie seulement les conflits avec le même email
    final commissionsToCheck = emailException.isNotEmpty
        ? commissionsList.where((c) =>
            c.id != excludeId &&
            (c.emailException == emailException || c.emailException.isEmpty))
        : commissionsList
            .where((c) => c.id != excludeId && c.emailException.isEmpty);

    for (final existing in commissionsToCheck) {
      // Vérifier les chevauchements
      bool hasOverlap = false;

      if (isInfinite && existing.isInfinite) {
        // Deux commissions infinies
        if (min <= existing.minAmount) {
          hasOverlap = true;
        }
      } else if (isInfinite && !existing.isInfinite) {
        // Nouvelle infinie vs existante finie
        if (min <= existing.maxAmount) {
          hasOverlap = true;
        }
      } else if (!isInfinite && existing.isInfinite) {
        // Nouvelle finie vs existante infinie
        if (max >= existing.minAmount) {
          hasOverlap = true;
        }
      } else {
        // Deux commissions finies
        if (!(max <= existing.minAmount || min >= existing.maxAmount)) {
          hasOverlap = true;
        }
      }

      if (hasOverlap) {
        hasConflict.value = true;
        validationMessage.value = emailException.isNotEmpty
            ? 'Conflit avec une commission existante pour cet email'
            : 'Conflit avec la plage ${existing.minAmount}€ - ${existing.isInfinite ? "∞" : "${existing.maxAmount}€"}';
        return false;
      }
    }

    return true;
  }

  // -----------------------------
  // Simulateur de commission
  // -----------------------------
  void openCommissionSimulator() {
    simulatorAmountCtrl.clear();
    simulatorEmailCtrl.clear();
    simulatedCommission.value = null;
    simulatedCommissionAmount.value = 0.0;

    Get.dialog(
      AlertDialog(
        title: const Text('Simulateur de commission'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextFormField(
                tag: 'simulator-amount',
                controller: simulatorAmountCtrl,
                labelText: 'Montant (€)',
                keyboardType: TextInputType.number,
                onChanged: (_) => simulateCommission(),
              ),
              const CustomSpace(heightMultiplier: 2),
              CustomTextFormField(
                tag: 'simulator-email',
                controller: simulatorEmailCtrl,
                labelText: 'Email entreprise (optionnel)',
                onChanged: (_) => simulateCommission(),
              ),
              const CustomSpace(heightMultiplier: 3),
              Obx(() => _buildSimulationResult()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationResult() {
    if (simulatedCommission.value == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Entrez un montant pour voir la commission applicable',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final comm = simulatedCommission.value!;
    final amount = simulatedCommissionAmount.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Commission applicable: ${comm.percentage}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Montant de commission: ${amount.toStringAsFixed(2)}€'),
          if (comm.associationPercentage > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Part association: ${(amount * comm.associationPercentage / comm.percentage).toStringAsFixed(2)}€',
              style: const TextStyle(color: Colors.green),
            ),
          ],
          if (comm.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              comm.description!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void simulateCommission() {
    final amount = double.tryParse(simulatorAmountCtrl.text) ?? 0;
    final email = simulatorEmailCtrl.text.trim().toLowerCase();

    if (amount <= 0) {
      simulatedCommission.value = null;
      simulatedCommissionAmount.value = 0;
      return;
    }

    final commission = findApplicableCommission(amount, email);
    simulatedCommission.value = commission;
    simulatedCommissionAmount.value =
        commission != null ? amount * commission.percentage / 100 : 0;
  }

  Commission? findApplicableCommission(double amount, String email) {
    // Chercher d'abord les commissions avec exception email
    if (email.isNotEmpty) {
      final emailSpecific = commissionsList
          .where((c) => c.emailException == email && isAmountInRange(amount, c))
          .toList();

      if (emailSpecific.isNotEmpty) {
        // Retourner celle avec la plus haute priorité
        emailSpecific
            .sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
        return emailSpecific.first;
      }
    }

    // Chercher les commissions générales
    final general = commissionsList
        .where((c) => c.emailException.isEmpty && isAmountInRange(amount, c))
        .toList();

    if (general.isNotEmpty) {
      // Retourner celle avec la plus haute priorité
      general.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
      return general.first;
    }

    // Chercher une commission par défaut
    final defaultComm =
        commissionsList.where((c) => c.isDefault ?? false).toList();

    if (defaultComm.isNotEmpty) {
      return defaultComm.first;
    }

    return null;
  }

  bool isAmountInRange(double amount, Commission comm) {
    if (amount < comm.minAmount) return false;
    if (comm.isInfinite) return true;
    return amount < comm.maxAmount;
  }

  // -----------------------------
  // Création/Édition
  // -----------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    editingCommissionId = null;
    _resetForm();
    openBottomSheet('Nouvelle commission',
        actionName: 'Créer', actionIcon: Icons.check);
  }

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
      priorityCtrl.text = '${c.priority ?? 0}';
      descriptionCtrl.text = c.description ?? '';
      isInfiniteCheck.value = c.isInfinite;
      isDefaultCommission.value = c.isDefault ?? false;
    } else {
      minCtrl.clear();
      maxCtrl.clear();
      percentCtrl.clear();
      assocPercentCtrl.clear();
      emailCtrl.clear();
      priorityCtrl.text = '0';
      descriptionCtrl.clear();
      isInfiniteCheck.value = false;
      isDefaultCommission.value = false;
      searchResults.clear();
    }
    hasConflict.value = false;
    validationMessage.value = '';
  }

  @override
  void variablesToResetToBottomSheet() {
    if (!isEditMode.value) _resetForm();
  }

  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }

    final minVal = double.tryParse(minCtrl.text.trim()) ?? 0.0;
    double maxVal = double.tryParse(maxCtrl.text.trim()) ?? 0.0;
    final perc = double.tryParse(percentCtrl.text.trim()) ?? 0.0;
    final assocPerc = double.tryParse(assocPercentCtrl.text.trim()) ?? 0.0;
    final emailExcept = emailCtrl.text.trim().toLowerCase();
    final priority = int.tryParse(priorityCtrl.text.trim()) ?? 0;
    final description = descriptionCtrl.text.trim();
    final isInf = isInfiniteCheck.value;
    final isDefault = isDefaultCommission.value;

    if (isInf) {
      maxVal = 0;
    }

    // Valider les conflits
    if (!validateCommissionRange(
        minVal, maxVal, isInf, editingCommissionId, emailExcept)) {
      UniquesControllers()
          .data
          .snackbar('Erreur', validationMessage.value, true);
      return;
    }

    Get.back();
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      if (isEditMode.value && editingCommissionId != null) {
        await _updateCommission(editingCommissionId!, minVal, maxVal, perc,
            isInf, assocPerc, emailExcept, priority, description, isDefault);
      } else {
        await _createCommission(minVal, maxVal, perc, isInf, assocPerc,
            emailExcept, priority, description, isDefault);
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
    int priority,
    String description,
    bool isDefault,
  ) async {
    // Si c'est une commission par défaut, désactiver les autres
    if (isDefault) {
      await _unsetOtherDefaultCommissions();
    }

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
      'priority': priority,
      'description': description,
      'isDefault': isDefault,
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
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
    int priority,
    String description,
    bool isDefault,
  ) async {
    // Si c'est une commission par défaut, désactiver les autres
    if (isDefault) {
      await _unsetOtherDefaultCommissions(docId);
    }

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
      'priority': priority,
      'description': description,
      'isDefault': isDefault,
      'updated_at': DateTime.now(),
    });

    UniquesControllers()
        .data
        .snackbar('Succès', 'Commission mise à jour.', false);
  }

  Future<void> _unsetOtherDefaultCommissions([String? excludeId]) async {
    final batch = UniquesControllers().data.firebaseFirestore.batch();

    final query = excludeId != null
        ? UniquesControllers()
            .data
            .firebaseFirestore
            .collection('commissions')
            .where('isDefault', isEqualTo: true)
            .where(FieldPath.documentId, isNotEqualTo: excludeId)
        : UniquesControllers()
            .data
            .firebaseFirestore
            .collection('commissions')
            .where('isDefault', isEqualTo: true);

    final snap = await query.get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    await batch.commit();
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
  // Recherche email
  // -----------------------------
  Future<void> searchEnterpriseByEmail(String input) async {
    final txt = input.trim().toLowerCase();
    if (txt.isEmpty) {
      searchResults.clear();
      return;
    }

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
  // BottomSheet children amélioré
  // -----------------------------
  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Montants
            Card(
              elevation: 0,
              color: Colors.blue.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.euro, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Plage de montants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            tag: 'comm-min',
                            controller: minCtrl,
                            labelText: 'Montant minimum',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _validateRange(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Requis';
                              if (double.tryParse(val.trim()) == null)
                                return 'Nombre invalide';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => CustomTextFormField(
                              tag: 'comm-max',
                              controller: maxCtrl,
                              labelText: 'Montant maximum',
                              keyboardType: TextInputType.number,
                              enabled: !isInfiniteCheck.value,
                              onChanged: (_) => _validateRange(),
                              validator: (val) {
                                if (isInfiniteCheck.value) return null;
                                if (val == null || val.trim().isEmpty)
                                  return 'Requis';
                                final num = double.tryParse(val.trim());
                                if (num == null) return 'Nombre invalide';
                                final min = double.tryParse(minCtrl.text) ?? 0;
                                if (num <= min) return 'Doit être > min';
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => CheckboxListTile(
                        value: isInfiniteCheck.value,
                        onChanged: (val) {
                          isInfiniteCheck.value = val ?? false;
                          _validateRange();
                        },
                        title: const Text('Plage infinie'),
                        subtitle: const Text(
                            'S\'applique à tous les montants supérieurs au minimum'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section: Commissions
            Card(
              elevation: 0,
              color: Colors.green.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.percent, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Taux de commission',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            tag: 'comm-percent',
                            controller: percentCtrl,
                            labelText: 'Commission (%)',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Requis';
                              final num = double.tryParse(val.trim());
                              if (num == null) return 'Nombre invalide';
                              if (num < 0 || num > 100) return 'Entre 0 et 100';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextFormField(
                            tag: 'comm-assoc-percent',
                            controller: assocPercentCtrl,
                            labelText: 'Part association (%)',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return null;
                              final num = double.tryParse(val.trim());
                              if (num == null) return 'Nombre invalide';
                              if (num < 0 || num > 100) return 'Entre 0 et 100';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section: Options avancées
            Card(
              elevation: 0,
              color: Colors.purple.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings,
                            color: Colors.purple[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Options avancées',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextFormField(
                      tag: 'comm-priority',
                      controller: priorityCtrl,
                      labelText: 'Priorité',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        if (int.tryParse(val.trim()) == null)
                          return 'Nombre entier requis';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextFormField(
                      tag: 'comm-description',
                      controller: descriptionCtrl,
                      labelText: 'Description (optionnel)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CustomTextFormField(
                      tag: 'comm-email-exception',
                      controller: emailCtrl,
                      labelText: 'Exception email entreprise',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) async {
                        await searchEnterpriseByEmail(val);
                        _validateRange();
                      },
                    ),
                    Obx(() {
                      if (searchResults.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.business),
                                title: Text(item['email'] as String),
                                onTap: () {
                                  emailCtrl.text = item['email'] as String;
                                  searchResults.clear();
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Obx(
                      () => CheckboxListTile(
                        value: isDefaultCommission.value,
                        onChanged: (val) {
                          isDefaultCommission.value = val ?? false;
                        },
                        title: const Text('Commission par défaut'),
                        subtitle: const Text(
                            'S\'applique si aucune autre commission ne correspond'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Message de validation
            Obx(() {
              if (validationMessage.value.isEmpty)
                return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasConflict.value
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasConflict.value
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasConflict.value ? Icons.warning : Icons.check_circle,
                      color: hasConflict.value ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        validationMessage.value,
                        style: TextStyle(
                          color: hasConflict.value ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }

  void _validateRange() {
    final min = double.tryParse(minCtrl.text) ?? 0;
    final max = double.tryParse(maxCtrl.text) ?? 0;
    final isInf = isInfiniteCheck.value;
    final email = emailCtrl.text.trim().toLowerCase();

    validateCommissionRange(min, max, isInf, editingCommissionId, email);
  }
}
