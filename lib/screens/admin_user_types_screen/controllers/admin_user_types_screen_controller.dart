import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user_type.dart';
import '../../../features/custom_space/view/custom_space.dart';

class AdminUserTypesScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Types d’Utilisateurs'.toUpperCase();
  String customBottomAppBarTag = 'admin-user-types-bottom-app-bar';

  RxList<UserType> userTypes = <UserType>[].obs;
  StreamSubscription<List<UserType>>? _sub;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  RxBool isEditMode = false.obs;
  UserType? tempUserType; // pour edit
  UserType? userTypeToDelete; // pour delete

  @override
  void onInit() {
    super.onInit();
    _sub = _listenUserTypes().listen((all) {
      // on ignore index == 0 => c’est Admin
      final filtered = all.where((u) => u.index != 0).toList();
      // on trie par index
      filtered.sort((a, b) => a.index.compareTo(b.index));
      userTypes.value = filtered;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Stream<List<UserType>> _listenUserTypes() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserType.fromDocument(d)).toList());
  }

  // ------------------------------------------------------
  // Création => bottomSheet
  // ------------------------------------------------------
  void openCreateBottomSheet() {
    isEditMode.value = false;
    tempUserType = null;
    variablesToResetToBottomSheet();
    openBottomSheet('Nouveau Type d\'utilisateur', actionName: 'Créer', actionIcon: Icons.check);
  }

  // ------------------------------------------------------
  // Édition => bottomSheet
  // ------------------------------------------------------
  void openEditBottomSheet(UserType u) {
    isEditMode.value = true;
    tempUserType = u;
    variablesToResetToBottomSheet();
    openBottomSheet('Modifier Type d\'utilisateur', actionName: 'Enregistrer', actionIcon: Icons.save);
  }

  @override
  void variablesToResetToBottomSheet() {
    if (isEditMode.value && tempUserType != null) {
      nameCtrl.text = tempUserType!.name;
      descCtrl.text = tempUserType!.description;
    } else {
      nameCtrl.clear();
      descCtrl.clear();
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            CustomTextFormField(
              tag: 'name_user_type',
              controller: nameCtrl,
              labelText: 'Nom du Type d\'Utilisateur',
              errorText: 'Nom invalide ou vide',
            ),
            const CustomSpace(heightMultiplier: 2),
            CustomTextFormField(
              tag: 'desc_user_type',
              controller: descCtrl,
              labelText: 'Description',
              minLines: 1,
              maxLines: 5,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();
    if (!formKey.currentState!.validate()) {
      return;
    }
    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      final name = nameCtrl.text.trim();
      final desc = descCtrl.text.trim();

      if (isEditMode.value && tempUserType != null) {
        await _updateUserType(tempUserType!.id, name, desc);
      } else {
        await _createUserType(name, desc);
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<void> _createUserType(String name, String desc) async {
    // On cherche le maxIndex actuel (hors index=0)
    int maxIndex = 0;
    for (final u in userTypes) {
      if (u.index > maxIndex) {
        maxIndex = u.index;
      }
    }
    final nextIndex = maxIndex + 1;

    await UniquesControllers().data.firebaseFirestore.collection('user_types').add({
      'name': name,
      'description': desc,
      'index': nextIndex,
    });

    UniquesControllers().data.snackbar('Succès', 'Type d\'utilisateur créé.', false);
  }

  Future<void> _updateUserType(String docId, String newName, String newDesc) async {
    await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(docId).update({
      'name': newName,
      'description': newDesc,
    });
    UniquesControllers().data.snackbar('Succès', 'Type mis à jour.', false);
  }

  // ------------------------------------------------------
  // Suppression => alertDialog
  // ------------------------------------------------------
  void openDeleteAlertDialog(UserType u) {
    userTypeToDelete = u;
    openAlertDialog('Supprimer ce Type ?', confirmText: 'Supprimer', confirmColor: Colors.red);
  }

  @override
  Widget alertDialogContent() {
    return const Text('Voulez-vous vraiment supprimer ce type d\'utilisateur ?');
  }

  @override
  Future<void> actionAlertDialog() async {
    final toDel = userTypeToDelete;
    if (toDel == null) return;
    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(toDel.id).delete();
      UniquesControllers().data.snackbar('Succès', 'Type d\'utilisateur supprimé.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      userTypeToDelete = null;
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ------------------------------------------------------
  // reorder => ne jamais toucher l’index 0
  // ------------------------------------------------------
  void onReorder(int oldIndex, int newIndex) async {
    // Si on glisse un item vers le bas => newIndex s’incrémente
    if (newIndex > oldIndex) newIndex--;

    // Pas de changement
    if (oldIndex == newIndex) return;

    final list = userTypes;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // On recalcule: l’élément en position 0 aura index=1, etc.
    final batch = UniquesControllers().data.firebaseFirestore.batch();
    for (int i = 0; i < list.length; i++) {
      final docId = list[i].id;
      // i=0 => index=1, i=1 => index=2, etc.
      final newIdx = i + 1;
      final ref = UniquesControllers().data.firebaseFirestore.collection('user_types').doc(docId);
      batch.update(ref, {'index': newIdx});
    }
    try {
      await batch.commit();
      UniquesControllers().data.snackbar('Ordre mis à jour', 'L\'ordre d\'affichage a été mis à jour.', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
