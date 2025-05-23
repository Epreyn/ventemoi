import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import du Mixin, des controllers, etc.
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
// Import de votre modèle EnterpriseCategory
import '../../../core/models/enterprise_category.dart';
// Import éventuel de votre widget de formulaire CustomTextFormField

class AdminEnterpriseCategoriesScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Catégories Entreprise'.toUpperCase();
  String customBottomAppBarTag = 'admin-enterprise-categories-bottom-app-bar';

  // Liste triée par index
  RxList<EnterpriseCategory> categories = <EnterpriseCategory>[].obs;
  StreamSubscription<List<EnterpriseCategory>>? _sub;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();

  RxBool isEditMode = false.obs;
  EnterpriseCategory? tempCategory; // en cas d'édition
  EnterpriseCategory? categoryToDelete; // en cas de suppression

  @override
  void onInit() {
    super.onInit();
    _sub = _listenEnterpriseCategories().listen((list) {
      // on les trie par index croissant
      list.sort((a, b) => a.index.compareTo(b.index));
      categories.value = list;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Stream
  // ---------------------------------------------------------------------------
  Stream<List<EnterpriseCategory>> _listenEnterpriseCategories() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .snapshots()
        .map((snap) => snap.docs.map((d) => EnterpriseCategory.fromDocument(d)).toList());
  }

  // ---------------------------------------------------------------------------
  // Création
  // ---------------------------------------------------------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    tempCategory = null;
    variablesToResetToBottomSheet();
    openBottomSheet('Nouvelle Catégorie Entreprise', actionName: 'Créer', actionIcon: Icons.check);
  }

  // ---------------------------------------------------------------------------
  // Édition
  // ---------------------------------------------------------------------------
  void openEditBottomSheet(EnterpriseCategory cat) {
    isEditMode.value = true;
    tempCategory = cat;
    variablesToResetToBottomSheet();
    openBottomSheet('Modifier Catégorie Entreprise', actionName: 'Enregistrer', actionIcon: Icons.save);
  }

  @override
  void variablesToResetToBottomSheet() {
    if (isEditMode.value && tempCategory != null) {
      nameCtrl.text = tempCategory!.name;
    } else {
      nameCtrl.clear();
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nom de la catégorie',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(90),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nom requis';
            }
            return null;
          },
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back(); // ferme le bottomSheet
    if (!formKey.currentState!.validate()) {
      return;
    }
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      if (isEditMode.value && tempCategory != null) {
        await _updateCategory(tempCategory!.id, name);
      } else {
        await _createCategory(name);
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<void> _createCategory(String name) async {
    int maxIdx = 0;
    for (final c in categories) {
      if (c.index > maxIdx) {
        maxIdx = c.index;
      }
    }
    final nextIndex = maxIdx + 1;

    await UniquesControllers().data.firebaseFirestore.collection('enterprise_categories').add({
      'name': name,
      'index': nextIndex,
    });
    UniquesControllers().data.snackbar('Succès', 'Catégorie entreprise créée.', false);
  }

  Future<void> _updateCategory(String docId, String newName) async {
    await UniquesControllers().data.firebaseFirestore.collection('enterprise_categories').doc(docId).update({
      'name': newName,
    });
    UniquesControllers().data.snackbar('Succès', 'Catégorie mise à jour.', false);
  }

  // ---------------------------------------------------------------------------
  // Suppression
  // ---------------------------------------------------------------------------
  void openDeleteAlertDialog(EnterpriseCategory cat) {
    categoryToDelete = cat;
    openAlertDialog('Supprimer cette catégorie ?', confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    return const Text('Voulez-vous vraiment supprimer cette catégorie entreprise ?');
  }

  @override
  Future<void> actionAlertDialog() async {
    if (categoryToDelete == null) return;
    final docId = categoryToDelete!.id;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      await UniquesControllers().data.firebaseFirestore.collection('enterprise_categories').doc(docId).delete();
      UniquesControllers().data.snackbar('Succès', 'Catégorie entreprise supprimée.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      categoryToDelete = null;
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reorder
  // ---------------------------------------------------------------------------
  void onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final tmp = categories.removeAt(oldIndex);
    categories.insert(newIndex, tmp);

    final batch = UniquesControllers().data.firebaseFirestore.batch();
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final ref = UniquesControllers().data.firebaseFirestore.collection('enterprise_categories').doc(cat.id);
      batch.update(ref, {'index': i});
    }
    try {
      await batch.commit();
      UniquesControllers().data.snackbar('Ordre mis à jour', 'L\'ordre d\'affichage a été mis à jour.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
