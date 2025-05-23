import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishment_category.dart';

class AdminCategoriesScreenController extends GetxController with ControllerMixin {
  // Titre / bottom bar
  String pageTitle = 'Catégories'.toUpperCase();
  String customBottomAppBarTag = 'admin-categories-bottom-app-bar';

  // Liste triée par index
  RxList<EstablishmentCategory> categories = <EstablishmentCategory>[].obs;
  StreamSubscription<List<EstablishmentCategory>>? _sub;

  // Pour la BottomSheet "modifier ou ajouter"
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  // On stocke si on est en mode edition ou creation
  RxBool isEditMode = false.obs;
  EstablishmentCategory? tempCategory; // en cas d'édition

  // Pour la suppression => on ouvre un AlertDialog
  EstablishmentCategory? categoryToDelete;

  @override
  void onInit() {
    super.onInit();
    _sub = _listenCategories().listen((list) {
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

  // -----------------------------------------------------------------------------
  // Stream Firestore
  // -----------------------------------------------------------------------------
  Stream<List<EstablishmentCategory>> _listenCategories() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .snapshots()
        .map((snap) => snap.docs.map((d) => EstablishmentCategory.fromDocument(d)).toList());
  }

  // -----------------------------------------------------------------------------
  // Création d’une catégorie : on ouvre un bottomSheet
  // -----------------------------------------------------------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    tempCategory = null;
    variablesToResetToBottomSheet(); // reset nameCtrl etc.
    openBottomSheet('Nouvelle catégorie', actionName: 'Créer', actionIcon: Icons.check);
  }

  // -----------------------------------------------------------------------------
  // Édition d’une catégorie : ouvre aussi le bottomSheet
  // -----------------------------------------------------------------------------
  void openEditBottomSheet(EstablishmentCategory cat) {
    isEditMode.value = true;
    tempCategory = cat;
    variablesToResetToBottomSheet(); // => ça va remplir nameCtrl avec cat.name
    openBottomSheet('Modifier la catégorie', actionName: 'Enregistrer', actionIcon: Icons.save);
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
        child: CustomTextFormField(
          tag: 'name_category',
          controller: nameCtrl,
          labelText: 'Nom de la catégorie',
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
    // user a cliqué sur "Créer" ou "Enregistrer"
    // on ferme le bottomSheet d’abord
    Get.back();
    if (!formKey.currentState!.validate()) {
      return;
    }

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return; // par sécurité

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      if (isEditMode.value && tempCategory != null) {
        // Cas édition
        await _updateCategory(tempCategory!.id, name);
      } else {
        // Cas création
        await _createCategory(name);
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Création = on trouve le plus grand index + 1
  Future<void> _createCategory(String name) async {
    // Récupérer le plus grand index
    int maxIdx = 0;
    for (final c in categories) {
      if (c.index > maxIdx) {
        maxIdx = c.index;
      }
    }
    final nextIndex = maxIdx + 1;

    await UniquesControllers().data.firebaseFirestore.collection('categories').add({
      'name': name,
      'index': nextIndex,
    });
    UniquesControllers().data.snackbar('Succès', 'Catégorie créée.', false);
  }

  Future<void> _updateCategory(String docId, String newName) async {
    await UniquesControllers().data.firebaseFirestore.collection('categories').doc(docId).update({
      'name': newName,
    });
    UniquesControllers().data.snackbar('Succès', 'Catégorie mise à jour.', false);
  }

  // -----------------------------------------------------------------------------
  // Suppression via AlertDialog
  // -----------------------------------------------------------------------------
  void openDeleteAlertDialog(EstablishmentCategory cat) {
    categoryToDelete = cat;
    openAlertDialog('Supprimer la catégorie ?', confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    return const Text('Voulez-vous vraiment supprimer cette catégorie ?');
  }

  @override
  Future<void> actionAlertDialog() async {
    if (categoryToDelete == null) return;
    final docId = categoryToDelete!.id;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      await UniquesControllers().data.firebaseFirestore.collection('categories').doc(docId).delete();
      UniquesControllers().data.snackbar('Succès', 'Catégorie supprimée.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      categoryToDelete = null;
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // -----------------------------------------------------------------------------
  // ReorderableListView => reorder => on met à jour le champ 'index'
  // -----------------------------------------------------------------------------
  void onReorder(int oldIndex, int newIndex) async {
    // Dans le widget, si newIndex > oldIndex, flutter l’a déjà ajusté de +1
    // => on fait un adaptateur
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    // On réordonne localement
    final tmp = categories.removeAt(oldIndex);
    categories.insert(newIndex, tmp);

    // On met à jour en Firestore tous les items
    // (ou au moins ceux impactés, mais plus simple : tous)
    // On va stocker le nouveau i comme index
    final batch = UniquesControllers().data.firebaseFirestore.batch();
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final ref = UniquesControllers().data.firebaseFirestore.collection('categories').doc(cat.id);
      batch.update(ref, {'index': i});
    }

    // On attend la fin du batch
    try {
      await batch.commit();
      UniquesControllers().data.snackbar('Ordre mis à jour', 'L\'ordre d\'affichage a été mis à jour.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
