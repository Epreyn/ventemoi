import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

// Vos imports habituels
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user.dart' as u;
import '../../../core/models/user_type.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../widgets/admin_users_type_name_cell.dart';

class AdminUsersScreenController extends GetxController with ControllerMixin {
  // ID du doc "Administrateur" dans user_types => pour filtrer
  static const String adminTypeDocId = '3YxzCA7BewiMswi8FDSt';

  String pageTitle = 'Utilisateurs (Admin)'.toUpperCase();
  String customBottomAppBarTag = 'admin-users-bottom-app-bar';

  RxList<u.User> allUsers = <u.User>[].obs;

  /// Texte de recherche
  RxString searchText = ''.obs;

  /// Indices pour le tri DataTable
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  /// Subscription Firestore
  StreamSubscription<List<u.User>>? _usersSub;

  // ------------------------------------------------
  // Champs de Form (BottomSheet)
  // ------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Contrôleur pour l'email de l'utilisateur à créer
  final emailCtrl = TextEditingController();

  /// Type sélectionné
  Rx<UserType?> currentUserType = Rx<UserType?>(null);

  // ------------------------------------------------
  // Lifecycle
  // ------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // On écoute la collection 'users'
    _usersSub = getAllUsersStream().listen((list) {
      allUsers.value = list;
      _sortUsers();
    });

    // Filtre
    ever(searchText, (_) => _sortUsers());
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    super.onClose();
  }

  // ------------------------------------------------
  // Stream "users"
  // ------------------------------------------------
  Stream<List<u.User>> getAllUsersStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => u.User.fromDocument(d)).toList());
  }

  // ------------------------------------------------
  // Rechercher
  // ------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value.trim().toLowerCase();
  }

  // ------------------------------------------------
  // Filtrage
  // ------------------------------------------------
  List<u.User> get filteredUsers {
    // Exclure admin
    final nonAdmins =
        allUsers.where((u) => u.userTypeID != adminTypeDocId).toList();
    // Filtre text
    final st = searchText.value;
    if (st.isEmpty) {
      return nonAdmins;
    } else {
      return nonAdmins.where((u) {
        final lName = u.name.toLowerCase();
        final lMail = u.email.toLowerCase();
        return lName.contains(st) || lMail.contains(st);
      }).toList();
    }
  }

  // ------------------------------------------------
  // Tri
  // ------------------------------------------------
  void onSortData(int colIndex, bool asc) {
    sortColumnIndex.value = colIndex;
    sortAscending.value = asc;
    _sortUsers();
  }

  void _sortUsers() {
    final sorted = allUsers.toList();
    sorted.sort((a, b) => _compareUsers(a, b));
    allUsers.value = sortAscending.value ? sorted : sorted.reversed.toList();
  }

  int _compareUsers(u.User a, u.User b) {
    switch (sortColumnIndex.value) {
      case 0:
        return a.name.compareTo(b.name);
      case 1:
        return a.email.compareTo(b.email);
      case 2:
        return a.userTypeID.compareTo(b.userTypeID);
      default:
        return 0;
    }
  }

  // ------------------------------------------------
  // Switch isEnabled / isVisible
  // ------------------------------------------------
  Future<void> onSwitchEnabled(u.User user, bool newValue) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.id)
          .update({'isEnable': newValue});
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    }
  }

  Future<void> onSwitchVisible(u.User user, bool newValue) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.id)
          .update({'isVisible': newValue});
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    }
  }

  // ------------------------------------------------
  // Colonnes du DataTable
  // ------------------------------------------------
  List<DataColumn> get dataColumns => [
        DataColumn(
          label:
              const Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label: const Text('Email',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        DataColumn(
          label:
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (colIndex, asc) => onSortData(colIndex, asc),
        ),
        const DataColumn(
            label:
                Text('Activé', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
                Text('Visible', style: TextStyle(fontWeight: FontWeight.bold))),
      ];

  // ------------------------------------------------
  // Lignes du DataTable
  // ------------------------------------------------
  List<DataRow> dataRows(List<u.User> finalList) {
    return List.generate(finalList.length, (i) {
      final u = finalList[i];
      return DataRow(
        cells: [
          DataCell(
            CustomCardAnimation(index: i, child: Text(u.name)),
          ),
          DataCell(
            CustomCardAnimation(index: i + 1, child: Text(u.email)),
          ),
          DataCell(
            CustomCardAnimation(
                index: i + 2,
                child: AdminUserTypeNameCell(userTypeId: u.userTypeID)),
          ),
          DataCell(CustomCardAnimation(
            index: i + 3,
            child: Switch(
                thumbColor: WidgetStateProperty.all(Colors.black),
                value: u.isEnable,
                onChanged: (val) => onSwitchEnabled(u, val)),
          )),
          DataCell(CustomCardAnimation(
            index: i + 4,
            child: Switch(
                thumbColor: WidgetStateProperty.all(Colors.black),
                value: u.isVisible,
                onChanged: (val) => onSwitchVisible(u, val)),
          )),
        ],
      );
    });
  }

  // ------------------------------------------------
  // Création d'un user via BottomSheet
  // ------------------------------------------------
  void openCreateUserBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Créer un utilisateur',
      actionName: 'Créer',
      actionIcon: Icons.check,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    formKey.currentState?.reset();
    emailCtrl.clear();
    currentUserType.value = null;
  }

  /// On suppose que vous avez un stream pour charger les user_types
  /// (excluant l'admin). Cf. l'exemple plus bas
  Stream<List<UserType>> getUserTypesStreamExceptAdmin() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .snapshots()
        .map((snap) {
      // Filtrer le doc "admin" si besoin
      final docs = snap.docs.where((d) => d.id != adminTypeDocId).toList();
      return docs.map((d) => UserType.fromDocument(d)).toList();
    });
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            // Email
            CustomCardAnimation(
              index: 0,
              child: CustomTextFormField(
                tag: 'admin-user-create-email',
                controller: emailCtrl,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                errorText: 'Email invalide',
                validatorPattern: r'^.+@[a-zA-Z]+\.[a-zA-Z]+$', // min check
              ),
            ),
            const CustomSpace(
              heightMultiplier: 2,
            ),

            CustomCardAnimation(
              index: 1,
              child: CustomDropdownStreamBuilder(
                  tag: 'admin-user-create-type',
                  stream: getUserTypesStreamExceptAdmin(),
                  initialItem: currentUserType,
                  labelText: 'Type utilisateur',
                  maxWith: 350,
                  maxHeight: 50,
                  onChanged: (UserType? value) {
                    currentUserType.value = value;
                  }),
            ),

            const CustomSpace(
              heightMultiplier: 1,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) {
      UniquesControllers().data.snackbar('Erreur', 'Formulaire invalide', true);
      return;
    }
    Get.back();

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      final email = emailCtrl.text.trim().toLowerCase();
      final type = currentUserType.value;
      if (type == null) {
        throw 'Type utilisateur non sélectionné';
      }

      await createUserWithoutSwitchingSession(email, type.id);

      UniquesControllers()
          .data
          .snackbar('Succès', 'Utilisateur créé pour $email', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ------------------------------------------------
  // createUserWithoutSwitchingSession
  // ------------------------------------------------
  Future<String> createUserWithoutSwitchingSession(
      String email, String userTypeDocId) async {
    var tmpPass = UniqueKey().toString();
    final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp', options: Firebase.app().options);
    final secondAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final userCred = await secondAuth.createUserWithEmailAndPassword(
          email: email, password: tmpPass);
      final newUid = userCred.user?.uid;
      if (newUid == null) {
        throw Exception("Impossible de créer l'utilisateur secondaire");
      }
      await secondAuth.sendPasswordResetEmail(email: email);

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(newUid)
          .set({
        'name': '',
        'email': email,
        'user_type_id': userTypeDocId,
        'image_url': '',
        'isVisible': true,
        'isEnable': true,
      });

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': newUid,
        'points': 0,
        'coupons': 0,
        'bank_details': {
          'iban': '',
          'bic': '',
          'holder': '',
        },
      });

      if (currentUserType.value?.name != 'Particulier') {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc()
            .set({
          'name': '',
          'user_id': newUid,
          'description': '',
          'address': '',
          'telephone': '',
          'email': '',
          'logo_url': '',
          'banner_url': '',
          'category_id': '',
          'enterprise_categories': [],
          'enterprise_category_slots': 2, // Valeur par défaut
          'video_url': '',
          'has_accepted_contract': false,
        });
      }

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc()
          .set({
        'user_id': newUid,
        'sponsoredEmails': [],
      });

      final whoCreated =
          UniquesControllers().data.firebaseAuth.currentUser?.email ??
              'un administrateur';

      await sendWelcomeEmailForCreatedUser(
        toEmail: email,
        whoDidCreate: whoCreated,
      );

      return newUid;
    } finally {
      await secondAuth.signOut();
      await secondaryApp.delete();
    }
  }
}
