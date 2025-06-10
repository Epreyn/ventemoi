import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import du Mixin, des controllers, etc.
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
// Import de votre modèle EnterpriseCategory
import '../../../core/models/enterprise_category.dart';

class AdminEnterpriseCategoriesScreenController extends GetxController
    with ControllerMixin {
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

  // Nouvelles variables pour la recherche et le tri
  RxString searchText = ''.obs;
  RxString sortBy = 'index'.obs; // 'index' ou 'name'

  // Liste filtrée pour l'affichage
  RxList<EnterpriseCategory> get filteredCategories {
    var filtered = categories.where((category) {
      if (searchText.value.isEmpty) return true;

      final search = searchText.value.toLowerCase();
      return category.name.toLowerCase().contains(search);
    }).toList();

    // Appliquer le tri
    switch (sortBy.value) {
      case 'name':
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'index':
      default:
        filtered.sort((a, b) => a.index.compareTo(b.index));
        break;
    }

    return filtered.obs;
  }

  @override
  void onInit() {
    super.onInit();
    _sub = _listenEnterpriseCategories().listen((list) {
      // on les trie par index croissant
      list.sort((a, b) => a.index.compareTo(b.index));
      categories.value = list;
    });

    // Écouter les changements de tri pour forcer le rafraîchissement
    ever(sortBy, (_) => categories.refresh());
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
        .map((snap) =>
            snap.docs.map((d) => EnterpriseCategory.fromDocument(d)).toList());
  }

  // ---------------------------------------------------------------------------
  // Recherche
  // ---------------------------------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value;
  }

  // ---------------------------------------------------------------------------
  // Création
  // ---------------------------------------------------------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    tempCategory = null;
    variablesToResetToBottomSheet();
    // Note: Le dialog est maintenant géré dans la vue
  }

  // ---------------------------------------------------------------------------
  // Édition
  // ---------------------------------------------------------------------------
  void openEditBottomSheet(EnterpriseCategory cat) {
    isEditMode.value = true;
    tempCategory = cat;
    variablesToResetToBottomSheet();
    // Note: Le dialog est maintenant géré dans la vue
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
    // Cette méthode n'est plus utilisée car on utilise des dialogs maintenant
    return [];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back(); // ferme le dialog
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

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .add({
      'name': name,
      'index': nextIndex,
    });
    UniquesControllers()
        .data
        .snackbar('Succès', 'Catégorie entreprise créée.', false);
  }

  Future<void> _updateCategory(String docId, String newName) async {
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(docId)
        .update({
      'name': newName,
    });
    UniquesControllers()
        .data
        .snackbar('Succès', 'Catégorie mise à jour.', false);
  }

  // ---------------------------------------------------------------------------
  // Suppression
  // ---------------------------------------------------------------------------
  void openDeleteAlertDialog(EnterpriseCategory cat) {
    categoryToDelete = cat;
    openAlertDialog('Supprimer cette catégorie ?',
        confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    return const Text(
        'Voulez-vous vraiment supprimer cette catégorie entreprise ?');
  }

  @override
  Future<void> actionAlertDialog() async {
    if (categoryToDelete == null) return;
    final docId = categoryToDelete!.id;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('enterprise_categories')
          .doc(docId)
          .delete();
      UniquesControllers()
          .data
          .snackbar('Succès', 'Catégorie entreprise supprimée.', false);
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

    // Travailler avec la liste filtrée
    final filtered = filteredCategories;
    final tmp = filtered.removeAt(oldIndex);
    filtered.insert(newIndex, tmp);

    // Mettre à jour tous les index en fonction de la nouvelle position dans la liste filtrée
    final batch = UniquesControllers().data.firebaseFirestore.batch();

    if (sortBy.value == 'index') {
      // Si on est trié par index, on met à jour les index en conséquence
      for (int i = 0; i < filtered.length; i++) {
        final cat = filtered[i];
        final ref = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('enterprise_categories')
            .doc(cat.id);
        batch.update(ref, {'index': i});
      }
    } else {
      // Si on est trié par nom, on doit recalculer les index pour maintenir l'ordre
      UniquesControllers().data.snackbar('Info',
          'Changez le tri sur "Ordre" pour réorganiser les catégories.', false);
      return;
    }

    try {
      await batch.commit();
      UniquesControllers().data.snackbar(
          'Ordre mis à jour', 'L\'ordre d\'affichage a été mis à jour.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
