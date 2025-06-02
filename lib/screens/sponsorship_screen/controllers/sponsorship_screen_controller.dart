import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';

// Suppose qu'on a déjà un "ControllerMixin" ou un "UniqueControllers"...
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/sponsorship.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class SponsorshipScreenController extends GetxController with ControllerMixin {
  // Titre, etc.
  String pageTitle = 'Parrainage'.toUpperCase();
  String customBottomAppBarTag = 'sponsorship-bottom-app-bar';

  // Le doc "sponsorship" de l'utilisateur courant
  Rx<Sponsorship?> currentSponsorship = Rx<Sponsorship?>(null);
  StreamSubscription<Sponsorship?>? _sub;

  // Pour le champ "email à parrainer"
  final TextEditingController emailCtrl = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ID du doc sponsorship
  String? sponsorshipDocId;

  @override
  void onInit() {
    super.onInit();

    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      // On écoute la doc sponsorship
      _sub = _listenSponsorshipDoc(uid).listen((s) {
        currentSponsorship.value = s;
      });
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // Stream => on récupère la doc "sponsorship" de l'utilisateur
  Stream<Sponsorship?> _listenSponsorshipDoc(String uid) {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      sponsorshipDocId = doc.id; // on stocke pour l'update
      return Sponsorship.fromDocument(doc);
    });
  }

  Future<void> onAddSponsorship() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    Get.back();

    final emailToSponsor = emailCtrl.text.trim().toLowerCase();
    if (emailToSponsor.isEmpty) return;

    final sponsorUid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (sponsorUid == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;
    try {
      // 1) Vérifier si ce mail est déjà sponsorisé => ex: s'il est déjà dans la liste
      final oldList = currentSponsorship.value?.sponsoredEmails ?? [];
      if (oldList.contains(emailToSponsor)) {
        UniquesControllers().data.snackbar(
              'Attention',
              'Cet email est déjà sponsorisé.',
              true,
            );
        return;
      }

      // 2) Vérifier si un user existe déjà
      final userSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: emailToSponsor)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        // L'utilisateur existe déjà => pas forcément besoin de createUser
        // Mais on peut quand même l'ajouter à la liste sponsor... (à vous de choisir la logique)
        // Ex. on l'ajoute quand même dans sponsoredEmails
        //  => Si vous voulez interdire le parrainage d'un user existant, décommentez ci-dessous:
        UniquesControllers()
            .data
            .snackbar('Erreur', 'Cet utilisateur existe déjà.', true);
        return;

        // Sinon, on peut l'ajouter à la liste
        await _addSponsoredEmailToList(emailToSponsor);

        UniquesControllers().data.snackbar(
              'Info',
              'Utilisateur déjà existant => parrainage enregistré.',
              false,
            );
      } else {
        // 3) Créer l'utilisateur => createUserWithoutSwitchingSession
        final newUid = await createUserWithoutSwitchingSession(emailToSponsor);

        // 4) Envoyer le mail d’information =>
        //    "Vous avez été parrainé par X, vous allez recevoir un lien etc."
        final whoDidCreateEmail =
            UniquesControllers().data.firebaseAuth.currentUser?.email ??
                'Un Parrain';
        await sendWelcomeEmailForCreatedUser(
          toEmail: emailToSponsor,
          whoDidCreate: whoDidCreateEmail,
        );

        // 5) Ajouter l'email à la liste sponsoredEmails
        await _addSponsoredEmailToList(emailToSponsor);

        UniquesControllers().data.snackbar(
              'Succès',
              'Utilisateur $emailToSponsor créé et parrainé !',
              false,
            );
      }
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<String> createUserWithoutSwitchingSession(String email) async {
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

      // On récupère l'id du userType "Particulier"
      final userTypeIdParticulier = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .where('name', isEqualTo: 'Particulier')
          .limit(1)
          .get();
      final partId = userTypeIdParticulier.docs.first.id;

      // On crée la doc user
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(newUid)
          .set({
        'name': '',
        'email': email,
        'user_type_id': partId,
        'image_url': '',
        'isEnable': true,
        'isVisible': true,
      });
      // On crée la doc wallet
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': newUid,
        'points': 0,
        'coupons': 0,
        'bank_details': null,
      });
      // On crée doc sponsorship (si besoin)
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

  // Met à jour la doc sponsorship => ajoute [email] dans sponsoredEmails
  Future<void> _addSponsoredEmailToList(String email) async {
    if (sponsorshipDocId == null) {
      // Il n'y a pas encore de doc => on la crée
      final newRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc();
      sponsorshipDocId = newRef.id;
      final sponsorUid =
          UniquesControllers().data.firebaseAuth.currentUser?.uid;

      await newRef.set({
        'user_id': sponsorUid,
        'sponsored_emails': [email],
      });
    } else {
      // On update
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc(sponsorshipDocId!)
          .update({
        'sponsored_emails': FieldValue.arrayUnion([email]),
      });
    }
  }

  @override
  void variablesToResetToBottomSheet() {
    emailCtrl.clear();
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            CustomTextFormField(
              tag: UniqueKey().toString(),
              controller: emailCtrl,
              labelText: 'Email du filleul',
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
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    await onAddSponsorship();
  }

  void openCreateUserBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Ajouter un Filleul',
      actionName: 'Ajouter',
      actionIcon: Icons.person_add,
    );
  }

  late Widget addFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.dynamicIconList.length,
    child: FloatingActionButton.extended(
      onPressed: openCreateUserBottomSheet,
      icon: const Icon(Icons.person_add),
      label: const Text('Ajouter un filleul'),
    ),
  );
}
