import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
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

  // Pour gérer la catégorie parente
  Rx<String?> selectedParentId = Rx<String?>(null);

  RxBool isEditMode = false.obs;
  EnterpriseCategory? tempCategory;
  EnterpriseCategory? categoryToDelete;

  // Variables pour la recherche et le tri
  RxString searchText = ''.obs;
  RxString sortBy = 'hierarchy'.obs; // 'hierarchy', 'index' ou 'name'

  // Obtenir uniquement les catégories principales
  List<EnterpriseCategory> get mainCategories {
    return categories.where((c) => c.isMainCategory).toList();
  }

  // Obtenir les sous-catégories d'une catégorie donnée
  List<EnterpriseCategory> getSubcategories(String parentId) {
    return categories.where((c) => c.parentId == parentId).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  // Liste organisée hiérarchiquement
  List<EnterpriseCategory> get hierarchicalCategories {
    final List<EnterpriseCategory> result = [];

    // D'abord les catégories principales
    final mains = mainCategories..sort((a, b) => a.index.compareTo(b.index));

    for (final main in mains) {
      result.add(main);
      // Puis leurs sous-catégories
      final subs = getSubcategories(main.id);
      result.addAll(subs);
    }

    return result;
  }

  // Liste filtrée pour l'affichage
  RxList<EnterpriseCategory> get filteredCategories {
    var filtered = categories.where((category) {
      if (searchText.value.isEmpty) return true;

      final search = searchText.value.toLowerCase();
      return category.name.toLowerCase().contains(search) ||
          category.getFullName(categories).toLowerCase().contains(search);
    }).toList();

    // Appliquer le tri
    switch (sortBy.value) {
      case 'name':
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'index':
        filtered.sort((a, b) => a.index.compareTo(b.index));
        break;
      case 'hierarchy':
      default:
        // Utiliser la liste hiérarchique filtrée
        final hierarchical = hierarchicalCategories;
        filtered = hierarchical.where((c) => filtered.contains(c)).toList();
        break;
    }

    return filtered.obs;
  }

  @override
  void onInit() {
    super.onInit();
    _sub = _listenEnterpriseCategories().listen((list) {
      categories.value = list;
    });

    ever(sortBy, (_) => categories.refresh());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Stream<List<EnterpriseCategory>> _listenEnterpriseCategories() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => EnterpriseCategory.fromDocument(d)).toList());
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void openCreateBottomSheet({String? parentId}) {
    isEditMode.value = false;
    tempCategory = null;
    selectedParentId.value = parentId;
    variablesToResetToBottomSheet();
  }

  void openEditBottomSheet(EnterpriseCategory cat) {
    isEditMode.value = true;
    tempCategory = cat;
    selectedParentId.value = cat.parentId;
    variablesToResetToBottomSheet();
  }

  @override
  void variablesToResetToBottomSheet() {
    if (isEditMode.value && tempCategory != null) {
      nameCtrl.text = tempCategory!.name;
      selectedParentId.value = tempCategory!.parentId;
    } else {
      nameCtrl.clear();
      // selectedParentId est déjà défini dans openCreateBottomSheet
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();
    if (!formKey.currentState!.validate()) {
      return;
    }
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      if (isEditMode.value && tempCategory != null) {
        await _updateCategory(tempCategory!.id, name, selectedParentId.value);
      } else {
        await _createCategory(name, selectedParentId.value);
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<void> _createCategory(String name, String? parentId) async {
    // Calculer l'index en fonction du contexte (principal ou sous-catégorie)
    int maxIdx = 0;
    final relevantCategories =
        parentId == null ? mainCategories : getSubcategories(parentId);

    for (final c in relevantCategories) {
      if (c.index > maxIdx) {
        maxIdx = c.index;
      }
    }
    final nextIndex = maxIdx + 1;

    // Déterminer le niveau
    int level = 0;
    if (parentId != null) {
      final parent = categories.firstWhereOrNull((c) => c.id == parentId);
      if (parent != null) {
        level = parent.level + 1;
      }
    }

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .add({
      'name': name,
      'index': nextIndex,
      'parent_id': parentId,
      'level': level,
    });

    UniquesControllers()
        .data
        .snackbar('Succès', 'Catégorie entreprise créée.', false);
  }

  Future<void> _updateCategory(
      String docId, String newName, String? newParentId) async {
    // Vérifier qu'on ne crée pas de boucle (catégorie parente de sa propre sous-catégorie)
    if (newParentId != null && _wouldCreateLoop(docId, newParentId)) {
      UniquesControllers().data.snackbar(
          'Erreur',
          'Impossible de définir cette catégorie parente car cela créerait une boucle.',
          true);
      return;
    }

    // Calculer le nouveau niveau
    int newLevel = 0;
    if (newParentId != null) {
      final parent = categories.firstWhereOrNull((c) => c.id == newParentId);
      if (parent != null) {
        newLevel = parent.level + 1;
      }
    }

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(docId)
        .update({
      'name': newName,
      'parent_id': newParentId,
      'level': newLevel,
    });

    // Mettre à jour les niveaux des sous-catégories si nécessaire
    await _updateSubcategoriesLevels(docId);

    UniquesControllers()
        .data
        .snackbar('Succès', 'Catégorie mise à jour.', false);
  }

  // Vérifier si définir newParentId comme parent de categoryId créerait une boucle
  bool _wouldCreateLoop(String categoryId, String newParentId) {
    if (categoryId == newParentId) return true;

    String? currentId = newParentId;
    while (currentId != null) {
      if (currentId == categoryId) return true;
      final parent = categories.firstWhereOrNull((c) => c.id == currentId);
      currentId = parent?.parentId;
    }
    return false;
  }

  // Mettre à jour récursivement les niveaux des sous-catégories
  Future<void> _updateSubcategoriesLevels(String parentId) async {
    final parent = categories.firstWhereOrNull((c) => c.id == parentId);
    if (parent == null) return;

    final subcats = getSubcategories(parentId);
    final batch = UniquesControllers().data.firebaseFirestore.batch();

    for (final subcat in subcats) {
      final ref = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('enterprise_categories')
          .doc(subcat.id);
      batch.update(ref, {'level': parent.level + 1});
    }

    await batch.commit();

    // Récursion pour les sous-sous-catégories
    for (final subcat in subcats) {
      await _updateSubcategoriesLevels(subcat.id);
    }
  }

  void openDeleteAlertDialog(EnterpriseCategory cat) {
    // Vérifier s'il y a des sous-catégories
    final subcats = getSubcategories(cat.id);
    if (subcats.isNotEmpty) {
      UniquesControllers().data.snackbar(
          'Impossible de supprimer',
          'Cette catégorie contient ${subcats.length} sous-catégorie(s). Supprimez d\'abord les sous-catégories.',
          true);
      return;
    }

    categoryToDelete = cat;
    openAlertDialog('Supprimer cette catégorie ?',
        confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    return Text(
        'Voulez-vous vraiment supprimer cette catégorie entreprise ?\n\n'
        'Catégorie : ${categoryToDelete?.getFullName(categories) ?? ""}');
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

  // Déplacer une catégorie principale
  Future<void> moveCategory(EnterpriseCategory category, bool moveUp) async {
    if (!category.isMainCategory) return;

    final mainCats = mainCategories;
    final currentIndex = mainCats.indexWhere((c) => c.id == category.id);

    if (currentIndex == -1) return;
    if (moveUp && currentIndex == 0) return;
    if (!moveUp && currentIndex == mainCats.length - 1) return;

    final targetIndex = moveUp ? currentIndex - 1 : currentIndex + 1;
    final targetCategory = mainCats[targetIndex];

    // Échanger les index
    final batch = UniquesControllers().data.firebaseFirestore.batch();

    final catRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(category.id);

    final targetRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(targetCategory.id);

    batch.update(catRef, {'index': targetCategory.index});
    batch.update(targetRef, {'index': category.index});

    try {
      await batch.commit();
      UniquesControllers().data.snackbar('Succès', 'Ordre mis à jour', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  // Déplacer une sous-catégorie
  Future<void> moveSubcategory(
    String parentId,
    EnterpriseCategory subcategory,
    bool moveUp,
  ) async {
    if (!subcategory.isSubCategory || subcategory.parentId != parentId) return;

    final subcats = getSubcategories(parentId);
    final currentIndex = subcats.indexWhere((c) => c.id == subcategory.id);

    if (currentIndex == -1) return;
    if (moveUp && currentIndex == 0) return;
    if (!moveUp && currentIndex == subcats.length - 1) return;

    final targetIndex = moveUp ? currentIndex - 1 : currentIndex + 1;
    final targetSubcategory = subcats[targetIndex];

    // Échanger les index
    final batch = UniquesControllers().data.firebaseFirestore.batch();

    final subcatRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(subcategory.id);

    final targetRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(targetSubcategory.id);

    batch.update(subcatRef, {'index': targetSubcategory.index});
    batch.update(targetRef, {'index': subcategory.index});

    try {
      await batch.commit();
      UniquesControllers()
          .data
          .snackbar('Succès', 'Ordre des sous-catégories mis à jour', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  void onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    if (sortBy.value != 'hierarchy') {
      UniquesControllers().data.snackbar(
          'Info',
          'Changez le tri sur "Hiérarchie" pour réorganiser les catégories.',
          false);
      return;
    }

    // Cette méthode est maintenant remplacée par moveCategory et moveSubcategory
    UniquesControllers().data.snackbar(
        'Info', 'Utilisez les flèches pour réorganiser les catégories.', false);
  }
}
