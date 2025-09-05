// lib/screens/admin_users_screen/controllers/admin_users_screen_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ventemoi/core/classes/controller_mixin.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user.dart' as u;
import '../../../core/models/establishment_category.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';

const String adminTypeDocId = 'admin-user-type-id';

class AdminUsersScreenController extends GetxController with ControllerMixin {
  static const tag = 'admin-users-screen';
  static const adminTypeDocId = 'admin-user-type-id';

  // ------------------------------------------------
  // Observables
  // ------------------------------------------------
  final allUsers = <u.User>[].obs;
  final searchText = ''.obs;
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;
  final userTypeNames = <String, String>{}.obs;

  final selectedUserType = Rx<String?>(null);
  final userTypes = <Map<String, dynamic>>[].obs;
  final selectedFilterUserType = Rx<String?>(null); // Pour le filtre par type

  // Listener
  StreamSubscription<List<u.User>>? _usersSub;

  // ------------------------------------------------
  // Champs de Form pour création d'utilisateur
  // ------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Informations utilisateur
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // Informations établissement
  final establishmentNameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();

  // Options
  final grantFreeAccess = false.obs;
  final freeSubscriptionType = 'standard'.obs;
  final selectedCategoryId = Rx<String?>(null);

  // Étape du formulaire (pour une meilleure UX)
  final currentStep = 0.obs;

  // ------------------------------------------------
  // Lifecycle
  // ------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    _usersSub = getAllUsersStream().listen((list) {
      allUsers.value = list;
      _sortUsers();
    });

    _loadUserTypeNames();
    _loadUserTypes();
    ever(searchText, (_) => _sortUsers());
    ever(selectedFilterUserType, (_) => _sortUsers());
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    emailCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
    establishmentNameCtrl.dispose();
    descriptionCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    postalCodeCtrl.dispose();
    websiteCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadUserTypes() async {
    try {
      final typesSnapshot = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .orderBy('index')
          .get();

      final types = <Map<String, dynamic>>[];
      for (final doc in typesSnapshot.docs) {
        final data = doc.data();
        // Exclure le type admin
        if (data['name'] != 'Administrateur') {
          types.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'description': data['description'] ?? '',
            'icon': _getTypeIcon(data['name'] ?? ''),
            'color': _getTypeColor(data['name'] ?? ''),
          });
        }
      }
      userTypes.value = types;
    } catch (e) {
    }
  }

  IconData _getTypeIcon(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'boutique':
        return Icons.store;
      case 'entreprise':
        return Icons.business;
      case 'association':
        return Icons.group;
      case 'particulier':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'boutique':
        return Colors.blue;
      case 'entreprise':
        return Colors.orange;
      case 'association':
        return Colors.green;
      case 'particulier':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ------------------------------------------------
  // Streams et chargement de données
  // ------------------------------------------------
  Stream<List<u.User>> getAllUsersStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => u.User.fromDocument(d)).toList());
  }

  Stream<List<EstablishmentCategory>> getCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .orderBy('index')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EstablishmentCategory.fromDocument(doc))
            .toList());
  }

  Future<void> _loadUserTypeNames() async {
    try {
      final typesSnapshot = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .get();

      final Map<String, String> names = {};
      for (final doc in typesSnapshot.docs) {
        names[doc.id] = doc.data()['name'] ?? 'Inconnu';
      }
      userTypeNames.value = names;
    } catch (e) {
    }
  }

  String getUserTypeName(String userTypeId) {
    if (userTypeId.isEmpty) return 'Non défini';
    return userTypeNames[userTypeId] ?? 'Inconnu';
  }

  // ------------------------------------------------
  // Recherche et filtrage
  // ------------------------------------------------
  void onSearchChanged(String value) {
    searchText.value = value.trim().toLowerCase();
  }

  List<u.User> get filteredUsers {
    var filtered =
        allUsers.where((u) => u.userTypeID != adminTypeDocId).toList();
    
    // Filtrage par type d'utilisateur
    if (selectedFilterUserType.value != null && selectedFilterUserType.value!.isNotEmpty) {
      filtered = filtered.where((u) => u.userTypeID == selectedFilterUserType.value).toList();
    }
    
    // Filtrage par recherche
    final st = searchText.value;
    if (st.isNotEmpty) {
      filtered = filtered.where((u) {
        final lName = u.name.toLowerCase();
        final lMail = u.email.toLowerCase();
        return lName.contains(st) || lMail.contains(st);
      }).toList();
    }
    
    return filtered;
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
        final typeNameA = getUserTypeName(a.userTypeID);
        final typeNameB = getUserTypeName(b.userTypeID);
        return typeNameA.compareTo(typeNameB);
      default:
        return 0;
    }
  }

  // ------------------------------------------------
  // Actions sur les utilisateurs
  // ------------------------------------------------
  Future<void> onSwitchEnabled(u.User user, bool newValue) async {
    return onSwitchActive(user, newValue);
  }

  Future<void> onSwitchActive(u.User user, bool newValue) async {
    try {
      if (user.id.isEmpty) {
        UniquesControllers().data.snackbar(
              'Erreur',
              'ID utilisateur invalide',
              true,
            );
        return;
      }

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(user.id)
          .update({'isEnable': newValue});

      UniquesControllers().data.snackbar(
            newValue ? 'Utilisateur activé' : 'Utilisateur désactivé',
            '${user.name} a été ${newValue ? "activé" : "désactivé"}',
            false,
          );
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

  Future<void> toggleAssociationVisibilityOverride(
      String establishmentId, bool newValue) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentId)
          .update({
        'force_visible_override': newValue,
        'updated_at': FieldValue.serverTimestamp(),
      });

      UniquesControllers().data.snackbar(
            'Succès',
            newValue
                ? 'Visibilité forcée activée'
                : 'Visibilité forcée désactivée',
            false,
          );
    } catch (err) {
      UniquesControllers().data.snackbar('Erreur', err.toString(), true);
    }
  }

  // Obtenir les infos de paiement d'un utilisateur
  Future<Map<String, dynamic>> getUserPaymentInfo(String userId) async {
    try {
      // Récupérer les infos utilisateur
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;

      // Récupérer les infos établissement
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isEmpty) {
        return {
          'has_free_access': userData['has_free_access'] ?? false,
          'free_subscription_type': userData['free_subscription_type'],
          'has_establishment': false,
        };
      }

      final estabData = estabQuery.docs.first.data();

      return {
        'has_free_access': estabData['is_free_access'] ?? false,
        'free_subscription_type': estabData['payment_option'],
        'has_active_subscription':
            estabData['has_active_subscription'] ?? false,
        'subscription_status': estabData['subscription_status'],
        'subscription_end_date': estabData['subscription_end_date'],
        'free_access_granted_by': estabData['free_access_granted_by'],
        'establishment_id': estabQuery.docs.first.id,
        'has_establishment': true,
      };
    } catch (e) {
      return {};
    }
  }

  // Basculer l'accès gratuit
  Future<void> toggleFreeAccess(
      String userId, bool grantFreeAccess, String subscriptionType) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Mettre à jour l'utilisateur
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .update({
        'has_free_access': grantFreeAccess,
        'free_subscription_type': grantFreeAccess ? subscriptionType : null,
      });

      // Mettre à jour l'établissement
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final estabId = estabQuery.docs.first.id;

        if (grantFreeAccess) {
          // Activer l'accès gratuit
          await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('establishments')
              .doc(estabId)
              .update({
            'is_free_access': true,
            'free_access_granted_by':
                UniquesControllers().data.firebaseAuth.currentUser?.email ??
                    'admin',
            'free_access_granted_at': FieldValue.serverTimestamp(),
            'has_accepted_contract': true,
            'has_active_subscription': true,
            'subscription_status': subscriptionType,
            'payment_option': subscriptionType,
            'subscription_end_date':
                Timestamp.fromDate(DateTime.now().add(Duration(days: 36500))),
            'enterprise_category_slots': _getCategorySlots(subscriptionType),
            'force_visible_override': true,
            'is_visible': true, // Rendre visible immédiatement
          });

          // Récupérer les informations de l'utilisateur pour l'email
          final userDoc = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userEmail = userData['email'] ?? '';
            final userName = userData['name'] ?? '';

            // Envoyer l'email de notification d'activation d'accès gratuit
            await sendFreeAccessGrantedEmail(
              toEmail: userEmail,
              name: userName,
              subscriptionType: subscriptionType,
            );
          }

          UniquesControllers().data.snackbar(
                'Succès',
                'Accès gratuit activé - L\'utilisateur a été notifié par email',
                false,
              );
        } else {
          // Désactiver l'accès gratuit - IMPORTANT : réinitialiser complètement
          await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('establishments')
              .doc(estabId)
              .update({
            'is_free_access': false,
            'free_access_granted_by': null,
            'free_access_granted_at': null,
            'has_active_subscription': false,
            'subscription_status': null,
            'subscription_end_date': null,
            'force_visible_override': false,
            'is_visible': false, // Rendre l'établissement invisible immédiatement
            // IMPORTANT : NE PAS réinitialiser has_accepted_contract ici
            // On le garde pour savoir que l'utilisateur a déjà accepté les CGU
            // Mais on ajoute un flag pour indiquer qu'il doit repayer
            'requires_payment': true,
            'free_access_removed_at': FieldValue.serverTimestamp(),
          });

          // Récupérer les informations de l'utilisateur pour l'email
          final userDoc = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userEmail = userData['email'] ?? '';
            final userName = userData['name'] ?? '';

            // Envoyer l'email de notification de retrait d'accès gratuit
            await sendFreeAccessRevokedEmail(
              toEmail: userEmail,
              name: userName,
            );
          }

          UniquesControllers().data.snackbar(
                'Succès',
                'Accès gratuit désactivé - L\'utilisateur a été notifié par email',
                false,
              );
        }
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<String?> getUserEstablishmentId(String userId) async {
    try {
      final query = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAssociationEstablishmentInfo(
      String userId) async {
    try {
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isEmpty) {
        return null;
      }

      final estabDoc = estabQuery.docs.first;
      final estabData = estabDoc.data();

      final sponsorsQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .where('sponsored_establishment_id', isEqualTo: estabDoc.id)
          .where('status', isEqualTo: 'active')
          .get();

      final sponsorCount = sponsorsQuery.docs.length;

      return {
        'establishmentId': estabDoc.id,
        'name': estabData['name'] ?? '',
        'sponsorCount': sponsorCount,
        'isVisible': estabData['is_visible'] ?? false,
        'forceVisibleOverride': estabData['force_visible_override'] ?? false,
        'hasActiveSubscription': estabData['has_active_subscription'] ?? false,
        'category': estabData['category'] ?? '',
        'city': estabData['city'] ?? '',
        'createdAt': estabData['created_at'],
        'updatedAt': estabData['updated_at'],
      };
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------
  // Création d'utilisateur via BottomSheet
  // ------------------------------------------------
  void openCreateUserBottomSheet() {
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Créer un nouvel utilisateur',
      hasAction: false,
      // actionName: 'Créer le compte',
      // actionIcon: Icons.person_add,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    formKey.currentState?.reset();
    emailCtrl.clear();
    nameCtrl.clear();
    passwordCtrl.clear();
    establishmentNameCtrl.clear();
    descriptionCtrl.clear();
    phoneCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    postalCodeCtrl.clear();
    websiteCtrl.clear();
    grantFreeAccess.value = false;
    freeSubscriptionType.value = 'standard';
    selectedCategoryId.value = null;
    selectedUserType.value = null;
    currentStep.value = 0;
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Obx(() => Column(
            children: [
              // Indicateur d'étapes
              _buildStepIndicator(),
              const SizedBox(height: 20),

              // Contenu selon l'étape
              if (currentStep.value == 0) _buildStep0UserType(), // Nouveau
              if (currentStep.value == 1) _buildStep1UserInfo(),
              if (currentStep.value == 2) _buildStep2EstablishmentInfo(),
              if (currentStep.value == 3) _buildStep3Options(),

              const SizedBox(height: 20),

              // Boutons de navigation
              _buildNavigationButtons(),
            ],
          )),
    ];
  }

  // Ajoutez cette méthode dans la classe AdminUsersScreen :

  Widget buildInfoRow(String label, String value,
      {IconData? icon, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: color ?? Colors.grey[600],
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Type'),
        Expanded(child: _buildStepLine(0)),
        _buildStepDot(1, 'Utilisateur'),
        Expanded(child: _buildStepLine(1)),
        _buildStepDot(2, 'Établissement'),
        Expanded(child: _buildStepLine(2)),
        _buildStepDot(3, 'Options'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = currentStep.value >= step;
    final isCurrent = currentStep.value == step;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: Colors.orange[800]!, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isCurrent ? Colors.orange[800] : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = currentStep.value > step;
    return Container(
      height: 2,
      color: isActive ? Colors.orange : Colors.grey[300],
      margin: EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildStep0UserType() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.category_outlined, color: Colors.amber[700]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Type de compte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grille des types
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: userTypes.length,
          itemBuilder: (context, index) {
            final type = userTypes[index];
            final isSelected = selectedUserType.value == type['id'];

            return CustomCardAnimation(
              index: index,
              child: InkWell(
                onTap: () {
                  selectedUserType.value = type['id'];
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? (type['color'] as Color)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? (type['color'] as Color).withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 32,
                        color: isSelected
                            ? (type['color'] as Color)
                            : Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        type['name'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (type['color'] as Color)
                              : Colors.grey[800],
                        ),
                      ),
                      if (type['description'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            type['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Info selon le type sélectionné
        if (selectedUserType.value != null) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.blue[700],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTypeInfoMessage(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getTypeInfoMessage() {
    final typeName = userTypes.firstWhere(
      (type) => type['id'] == selectedUserType.value,
      orElse: () => {'name': ''},
    )['name'];

    switch (typeName.toLowerCase()) {
      case 'boutique':
        return 'Un compte boutique permet de vendre des produits et d\'accumuler des points.';
      case 'entreprise':
        return 'Un compte entreprise offre des services professionnels et peut avoir plusieurs catégories.';
      case 'association':
        return 'Un compte association nécessite 15 affiliés pour être visible (sauf override admin).';
      case 'particulier':
        return 'Un compte particulier permet d\'acheter et de parrainer d\'autres utilisateurs.';
      default:
        return '';
    }
  }

  Widget _buildStep1UserInfo() {
    return Form(
      key: currentStep.value == 1 ? formKey : null,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Informations de connexion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomCardAnimation(
            index: 0,
            child: CustomTextFormField(
              tag: 'admin-user-email',
              controller: emailCtrl,
              labelText: 'Email *',
              keyboardType: TextInputType.emailAddress,
              errorText: 'Email invalide',
              validatorPattern: r'^.+@[a-zA-Z]+\.[a-zA-Z]+$',
              iconData: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 16),
          CustomCardAnimation(
            index: 1,
            child: CustomTextFormField(
              tag: 'admin-user-name',
              controller: nameCtrl,
              labelText: 'Nom complet *',
              errorText: 'Nom requis',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom requis';
                }
                return null;
              },
              iconData: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          CustomCardAnimation(
            index: 2,
            child: CustomTextFormField(
              tag: 'admin-user-password',
              controller: passwordCtrl,
              labelText: 'Mot de passe *',
              isPassword: true,
              errorText: 'Min. 6 caractères',
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Min. 6 caractères';
                }
                return null;
              },
              iconData: Icons.lock_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2EstablishmentInfo() {
    final typeName = userTypes
        .firstWhere(
          (type) => type['id'] == selectedUserType.value,
          orElse: () => {'name': ''},
        )['name']
        .toString()
        .toLowerCase();

    // Si c'est un particulier, pas d'établissement
    if (typeName == 'particulier') {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16),
            Text(
              'Compte Particulier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les particuliers n\'ont pas d\'établissement',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Form(
      key: currentStep.value == 2 ? formKey : null,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.store_outlined, color: Colors.green[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de l\'établissement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Laissez vide pour utiliser les valeurs par défaut',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          CustomCardAnimation(
            index: 0,
            child: CustomTextFormField(
              tag: 'admin-establishment-name',
              controller: establishmentNameCtrl,
              labelText: 'Nom de l\'établissement',
              iconData: Icons.business,
            ),
          ),
          const SizedBox(height: 16),

          CustomCardAnimation(
            index: 1,
            child: CustomTextFormField(
              tag: 'admin-establishment-description',
              controller: descriptionCtrl,
              labelText: 'Description',
              minLines: 3,
              maxLines: 5,
              iconData: Icons.description_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Catégorie
          CustomCardAnimation(
            index: 2,
            child: StreamBuilder<List<EstablishmentCategory>>(
              stream: getCategoriesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!;

                return Obx(() {
                  // Ajout du Obx ici
                  // Vérifier que la catégorie sélectionnée existe toujours
                  if (selectedCategoryId.value != null) {
                    final exists = categories
                        .any((cat) => cat.id == selectedCategoryId.value);
                    if (!exists) {
                      selectedCategoryId.value = null;
                    }
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId.value,
                        hint: Text('Sélectionner une catégorie'),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down),
                        onChanged: (String? categoryId) {
                          selectedCategoryId.value = categoryId;
                        },
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }); // Fin du Obx
              },
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomCardAnimation(
                  index: 3,
                  child: CustomTextFormField(
                    tag: 'admin-establishment-phone',
                    controller: phoneCtrl,
                    labelText: 'Téléphone',
                    keyboardType: TextInputType.phone,
                    iconData: Icons.phone_outlined,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomCardAnimation(
                  index: 4,
                  child: CustomTextFormField(
                    tag: 'admin-establishment-website',
                    controller: websiteCtrl,
                    labelText: 'Site web',
                    keyboardType: TextInputType.url,
                    iconData: Icons.language,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomCardAnimation(
            index: 5,
            child: CustomTextFormField(
              tag: 'admin-establishment-address',
              controller: addressCtrl,
              labelText: 'Adresse',
              iconData: Icons.location_on_outlined,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomCardAnimation(
                  index: 6,
                  child: CustomTextFormField(
                    tag: 'admin-establishment-city',
                    controller: cityCtrl,
                    labelText: 'Ville',
                    iconData: Icons.location_city,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomCardAnimation(
                  index: 7,
                  child: CustomTextFormField(
                    tag: 'admin-establishment-postal',
                    controller: postalCodeCtrl,
                    labelText: 'Code postal',
                    keyboardType: TextInputType.number,
                    iconData: Icons.pin_drop_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Options() {
    return Column(
      children: [
        // Option accès gratuit
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: Colors.purple[700],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accès Premium Gratuit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                  Switch(
                    value: grantFreeAccess.value,
                    onChanged: (value) {
                      grantFreeAccess.value = value;
                    },
                    activeColor: Colors.purple[700],
                  ),
                ],
              ),
              if (grantFreeAccess.value) ...[
                SizedBox(height: 12),
                Text(
                  'L\'utilisateur aura accès à toutes les fonctionnalités premium sans payer.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.purple[600],
                  ),
                ),
                SizedBox(height: 16),
                // Sélecteur du type d'abonnement
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple[300]!,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: freeSubscriptionType.value,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.purple[700],
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        freeSubscriptionType.value = value;
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'basic',
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Basic - 2 catégories'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'standard',
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Standard - 3 catégories'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'premium',
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Premium - 5 catégories'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow(
                          '✅ Toutes les fonctionnalités débloquées'),
                      _buildBenefitRow('✅ 50 points de bienvenue offerts'),
                      _buildBenefitRow('✅ Bon cadeau de 50€'),
                      _buildBenefitRow('✅ Visibilité immédiate'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Résumé
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résumé',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              _buildSummaryRow(
                'Type de compte',
                userTypes.firstWhere(
                  (type) => type['id'] == selectedUserType.value,
                  orElse: () => {'name': 'Non défini'},
                )['name'],
                color: userTypes.firstWhere(
                  (type) => type['id'] == selectedUserType.value,
                  orElse: () => {'color': Colors.grey},
                )['color'] as Color,
              ),
              _buildSummaryRow('Email',
                  emailCtrl.text.isEmpty ? 'Non renseigné' : emailCtrl.text),
              _buildSummaryRow('Nom',
                  nameCtrl.text.isEmpty ? 'Non renseigné' : nameCtrl.text),
              _buildSummaryRow(
                  'Établissement',
                  establishmentNameCtrl.text.isEmpty
                      ? 'Utilisera le nom de l\'utilisateur'
                      : establishmentNameCtrl.text),
              if (grantFreeAccess.value)
                _buildSummaryRow('Accès gratuit',
                    '${freeSubscriptionType.value.toUpperCase()} à vie',
                    color: Colors.purple[700]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (currentStep.value > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                currentStep.value--;
              },
              child: Text('Précédent'),
            ),
          ),
        if (currentStep.value > 0) SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (currentStep.value < 3) {
                // Valider l'étape actuelle avant de continuer
                if (currentStep.value == 0 && !_validateStep0()) {
                  return;
                }
                if (currentStep.value == 1 && !_validateStep1()) {
                  return;
                }
                currentStep.value++;
              } else {
                // Dernière étape : créer le compte
                actionBottomSheet();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  currentStep.value == 3 ? Colors.green : Colors.orange,
            ),
            child: Text(
              currentStep.value == 3 ? 'Créer le compte' : 'Suivant',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  bool _validateStep0() {
    if (selectedUserType.value == null) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Veuillez sélectionner un type de compte',
            true,
          );
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    // Vérifier manuellement les champs au lieu d'utiliser formKey
    if (emailCtrl.text.trim().isEmpty) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'L\'email est obligatoire',
            true,
          );
      return false;
    }

    if (nameCtrl.text.trim().isEmpty) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Le nom est obligatoire',
            true,
          );
      return false;
    }

    if (passwordCtrl.text.length < 6) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Le mot de passe doit contenir au moins 6 caractères',
            true,
          );
      return false;
    }

    // Valider le format email
    final emailRegex = RegExp(r'^.+@[a-zA-Z]+\.[a-zA-Z]+$');
    if (!emailRegex.hasMatch(emailCtrl.text.trim())) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Format d\'email invalide',
            true,
          );
      return false;
    }

    return true;
  }

  @override
  Future<void> actionBottomSheet() async {
    // Valider les champs obligatoires
    if (emailCtrl.text.isEmpty ||
        nameCtrl.text.isEmpty ||
        passwordCtrl.text.length < 6) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Email, nom et mot de passe (min 6 caractères) sont obligatoires',
            true,
          );
      currentStep.value = 0;
      return;
    }

    Get.back();
    await _createDirectAccount();
  }

  // Créer un compte directement
  Future<void> _createDirectAccount() async {
    UniquesControllers().data.isInAsyncCall.value = true;
    auth.UserCredential? newUserCredential;

    try {
      final email = emailCtrl.text.trim().toLowerCase();
      final name = nameCtrl.text.trim();
      final password = passwordCtrl.text;

      // Vérifier si l'utilisateur existe déjà
      final existingUsers = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw 'Un utilisateur avec cet email existe déjà';
      }

      // Sauvegarder l'utilisateur actuel
      final currentUser = UniquesControllers().data.firebaseAuth.currentUser;

      // Créer le nouveau compte
      newUserCredential = await UniquesControllers()
          .data
          .firebaseAuth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

      if (newUserCredential.user != null) {
        final newUserId = newUserCredential.user!.uid;

        // Mettre à jour le nom d'affichage
        await newUserCredential.user!.updateDisplayName(name);

        // Créer le document utilisateur
        final userData = {
          'email': email,
          'name': name,
          'created_at': FieldValue.serverTimestamp(),
          'isActive': true,
          'isEnable': true,
          'isVisible': true,
          'has_completed_onboarding': true, // Toujours true car admin crée
          'userTypeID': selectedUserType.value ?? '',
          'user_type_id':
              selectedUserType.value ?? '', // Doublon pour compatibilité
          'points': 0,
          'created_by_admin': true,
          'created_by': currentUser?.email ?? 'admin',
          'has_free_access': grantFreeAccess.value,
          'free_subscription_type':
              grantFreeAccess.value ? freeSubscriptionType.value : null,
          'personal_address': '',
          'image_url': '',
        };

        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('users')
            .doc(newUserId)
            .set(userData);

        final typeName = userTypes
            .firstWhere(
              (type) => type['id'] == selectedUserType.value,
              orElse: () => {'name': ''},
            )['name']
            .toString()
            .toLowerCase();

        if (typeName != 'particulier') {
          await _createEstablishmentWithFreeAccess(newUserId, name, email);
        } else if (grantFreeAccess.value) {
          // Pour un particulier avec accès gratuit, créer juste le wallet
          await _createWalletWithWelcomePoints(newUserId);
        }

        // Envoyer l'email avec les identifiants
        await sendAccountCreatedEmail(
          toEmail: email,
          name: name,
          password: password,
          hasFreeAccess: grantFreeAccess.value,
          subscriptionType: freeSubscriptionType.value,
        );

        UniquesControllers().data.snackbar(
              'Succès',
              'Compte créé pour $name ($email)',
              false,
            );
      }
    } catch (e) {
      // Si erreur, supprimer le compte créé
      if (newUserCredential?.user != null) {
        try {
          await newUserCredential!.user!.delete();
        } catch (_) {}
      }
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Créer l'établissement avec accès gratuit
  Future<void> _createEstablishmentWithFreeAccess(
    String userId,
    String userName,
    String userEmail,
  ) async {
    try {
      // Utiliser le nom de l'établissement ou celui de l'utilisateur
      final establishmentName = establishmentNameCtrl.text.trim().isEmpty
          ? userName
          : establishmentNameCtrl.text.trim();

      final establishmentData = {
        'user_id': userId,
        'name': establishmentName,
        'email': userEmail,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),

        // Champs critiques pour l'accès payant
        'has_accepted_contract': grantFreeAccess.value,
        'contract_accepted_at':
            grantFreeAccess.value ? FieldValue.serverTimestamp() : null,
        'has_active_subscription': grantFreeAccess.value,
        'subscription_status':
            grantFreeAccess.value ? freeSubscriptionType.value : null,
        'subscription_start_date':
            grantFreeAccess.value ? FieldValue.serverTimestamp() : null,
        'subscription_end_date': grantFreeAccess.value
            ? Timestamp.fromDate(DateTime.now().add(Duration(days: 36500)))
            : null,
        'payment_option':
            grantFreeAccess.value ? freeSubscriptionType.value : null,

        // Marquer comme accès gratuit
        'is_free_access': grantFreeAccess.value,
        'free_access_granted_by': grantFreeAccess.value
            ? (UniquesControllers().data.firebaseAuth.currentUser?.email ??
                'admin')
            : null,
        'free_access_granted_at':
            grantFreeAccess.value ? FieldValue.serverTimestamp() : null,

        // Slots de catégories
        'enterprise_category_slots': grantFreeAccess.value
            ? _getCategorySlots(freeSubscriptionType.value)
            : 2,

        // Statuts de visibilité
        'is_visible': grantFreeAccess.value,
        'is_active': true,
        'force_visible_override': grantFreeAccess.value,

        // Champs remplis par l'admin ou par défaut
        'description': descriptionCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'telephone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'postal_code': postalCodeCtrl.text.trim(),
        'country': 'France',
        'website': websiteCtrl.text.trim(),
        'category_id': selectedCategoryId.value ?? '',
        'video_url': '',
        'opening_hours': {},
        'social_networks': {},
        'images': [],
        'logo_url': '',
        'banner_url': '',
        'cover_url': '',
        'tags': [],
        'rating': 0.0,
        'reviews_count': 0,
        'likes_count': 0,
        'enterprise_categories': [],
      };

      final docRef = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .add(establishmentData);


      // Si accès gratuit, créer le wallet et le bon cadeau
      if (grantFreeAccess.value) {
        await _createWalletWithWelcomePoints(userId);
        await _createWelcomeGiftVoucher(docRef.id);
      }
    } catch (e) {
    }
  }

  // Les autres méthodes restent identiques...
  Future<void> _createWalletWithWelcomePoints(String userId) async {
    try {
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (walletQuery.docs.isEmpty) {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .add({
          'user_id': userId,
          'points': 50,
          'coupons': 0,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
    }
  }

  Future<void> _createWelcomeGiftVoucher(String establishmentId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('gift_vouchers')
          .add({
        'establishment_id': establishmentId,
        'amount': 50.0,
        'type': 'welcome',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'code': 'WELCOME-${DateTime.now().millisecondsSinceEpoch}',
        'is_free_access_gift': true,
      });
    } catch (e) {
    }
  }

  int _getCategorySlots(String subscriptionType) {
    switch (subscriptionType) {
      case 'premium':
        return 5;
      case 'standard':
        return 3;
      case 'basic':
      default:
        return 2;
    }
  }

  Future<void> sendFreeAccessGrantedEmail({
    required String toEmail,
    required String name,
    required String subscriptionType,
  }) async {
    String subscriptionName = subscriptionType == 'premium'
        ? 'Premium'
        : subscriptionType == 'standard'
            ? 'Standard'
            : 'Basic';

    int slots = _getCategorySlots(subscriptionType);

    final content = '''
      <h2>🎉 Bonne nouvelle : Accès Premium offert !</h2>

      <p>Bonjour $name,</p>

      <p>
        Nous avons le plaisir de vous informer qu'un administrateur de Vente Moi 
        vient de vous octroyer un <strong>accès $subscriptionName gratuit à vie</strong> !
      </p>

      <div style="background-color: #f3e5f5; padding: 20px; border-radius: 12px; margin: 20px 0;">
        <h3 style="color: #6a1b9a; margin-top: 0;">🎁 Vos avantages Premium</h3>
        <ul style="color: #4a148c; margin: 10px 0;">
          <li>✅ <strong>Toutes les fonctionnalités premium débloquées</strong></li>
          <li>✅ <strong>$slots catégories d'entreprise</strong> disponibles</li>
          <li>✅ <strong>50 points de bienvenue</strong> offerts</li>
          <li>✅ <strong>Bon cadeau de 50€</strong> pour vos achats</li>
          <li>✅ <strong>Visibilité immédiate</strong> de votre établissement</li>
          <li>✅ <strong>Accès à vie</strong> - aucun paiement requis</li>
        </ul>
      </div>

      <div style="background-color: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h3 style="color: #2e7d32; margin-top: 0;">✨ Que pouvez-vous faire maintenant ?</h3>
        <ul style="margin: 10px 0;">
          <li>Modifier et enrichir votre profil d'établissement</li>
          <li>Ajouter des photos et vidéos</li>
          <li>Configurer vos catégories d'entreprise</li>
          <li>Commencer à accumuler des points</li>
          <li>Parrainer d'autres utilisateurs</li>
        </ul>
      </div>

      <div style="margin-top: 30px; text-align: center;">
        <a href="https://ventemoi.com/login"
           style="display: inline-block; padding: 15px 30px; background-color: #ff6b35;
                  color: white; text-decoration: none; border-radius: 30px; font-weight: bold;">
          Accéder à mon compte
        </a>
      </div>

      <p style="margin-top: 30px; color: #666; font-size: 12px; font-style: italic;">
        Cet accès gratuit vous a été offert par ${UniquesControllers().data.firebaseAuth.currentUser?.email ?? 'un administrateur'}.
      </p>

      <p style="color: #666;">
        Si vous avez des questions, n'hésitez pas à nous contacter.
      </p>

      <p>
        Cordialement,<br>
        <strong>L'équipe Vente Moi</strong>
      </p>
    ''';

    final emailData = {
      'to': toEmail,
      'message': {
        'subject': '🎉 Votre accès Premium Vente Moi a été activé !',
        'html': content,
      },
    };

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('mail')
        .add(emailData);
  }

  Future<void> sendFreeAccessRevokedEmail({
    required String toEmail,
    required String name,
  }) async {
    final content = '''
      <h2>Important : Modification de votre accès Vente Moi</h2>

      <p>Bonjour $name,</p>

      <p>
        Nous vous informons que votre accès gratuit Premium à la plateforme Vente Moi 
        vient d'être désactivé par un administrateur.
      </p>

      <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; border-left: 4px solid #ffc107; margin: 20px 0;">
        <h3 style="color: #856404; margin-top: 0;">⚠️ Action requise</h3>
        <p style="color: #856404; margin-bottom: 10px;">
          <strong>Votre établissement n'est plus visible sur la plateforme.</strong>
        </p>
        <p style="color: #856404;">
          Pour retrouver votre visibilité et accéder à toutes les fonctionnalités, 
          vous devez souscrire à un abonnement payant.
        </p>
      </div>

      <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h3 style="margin-top: 0;">Nos offres d'abonnement :</h3>
        <ul style="margin: 10px 0;">
          <li><strong>Basic</strong> : 2 catégories d'entreprise - 9,99€/mois</li>
          <li><strong>Standard</strong> : 3 catégories d'entreprise - 19,99€/mois</li>
          <li><strong>Premium</strong> : 5 catégories d'entreprise - 29,99€/mois</li>
        </ul>
        <p style="font-size: 14px; color: #666;">
          💡 Économisez 20% avec un abonnement annuel !
        </p>
      </div>

      <div style="margin-top: 30px; text-align: center;">
        <a href="https://ventemoi.com/login"
           style="display: inline-block; padding: 15px 30px; background-color: #ff6b35;
                  color: white; text-decoration: none; border-radius: 30px; font-weight: bold;">
          Souscrire maintenant
        </a>
      </div>

      <p style="margin-top: 30px; color: #666;">
        <strong>Important :</strong> Vous pouvez toujours vous connecter à votre compte et 
        modifier vos informations. Cependant, votre établissement ne sera visible qu'après 
        la souscription d'un abonnement.
      </p>

      <p style="color: #666;">
        Si vous pensez qu'il s'agit d'une erreur ou si vous avez des questions, 
        n'hésitez pas à nous contacter.
      </p>

      <p>
        Cordialement,<br>
        <strong>L'équipe Vente Moi</strong>
      </p>
    ''';

    final emailData = {
      'to': toEmail,
      'message': {
        'subject': '⚠️ Votre accès gratuit Vente Moi a été désactivé',
        'html': content,
      },
    };

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('mail')
        .add(emailData);
  }

  Future<void> sendAccountCreatedEmail({
    required String toEmail,
    required String name,
    required String password,
    required bool hasFreeAccess,
    required String subscriptionType,
  }) async {
    String accessInfo = '';
    if (hasFreeAccess) {
      String subscriptionName = subscriptionType == 'premium'
          ? 'Premium'
          : subscriptionType == 'standard'
              ? 'Standard'
              : 'Basic';

      int slots = _getCategorySlots(subscriptionType);

      accessInfo = '''
      <div style="background-color: #f3e5f5; padding: 20px; border-radius: 12px; margin: 20px 0;">
        <h3 style="color: #6a1b9a; margin-top: 0;">🎁 Accès Premium Offert !</h3>
        <p style="color: #4a148c; margin-bottom: 8px;">
          Vous bénéficiez d'un accès <strong>$subscriptionName gratuit</strong> à vie !
        </p>
        <ul style="color: #666; font-size: 14px; margin: 10px 0;">
          <li>✅ Toutes les fonctionnalités premium débloquées</li>
          <li>✅ $slots catégories d'entreprise disponibles</li>
          <li>✅ 50 points de bienvenue offerts</li>
          <li>✅ Bon cadeau de 50€ pour vos premiers achats</li>
          <li>✅ Profil visible immédiatement</li>
        </ul>
        <p style="color: #666; font-size: 12px; margin-bottom: 0; font-style: italic;">
          Cet accès gratuit vous a été offert par ${UniquesControllers().data.firebaseAuth.currentUser?.email ?? 'un administrateur'}.
        </p>
      </div>
      ''';
    }

    final establishmentInfo = establishmentNameCtrl.text.trim().isNotEmpty
        ? '''
        <p><strong>Votre établissement :</strong> ${establishmentNameCtrl.text.trim()}</p>
        '''
        : '';

    final content = '''
      <h2>Bienvenue sur Vente Moi, $name ! 🎉</h2>

      <p>
        Un compte a été créé pour vous par un administrateur de la plateforme Vente Moi.
      </p>

      $accessInfo

      <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h3 style="margin-top: 0;">Vos identifiants de connexion :</h3>
        <p><strong>Email :</strong> $toEmail</p>
        <p><strong>Mot de passe :</strong> $password</p>
        $establishmentInfo
      </div>

      <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; border-left: 4px solid #ffc107;">
        <p style="margin: 0; color: #856404;">
          <strong>Important :</strong> Nous vous recommandons de changer votre mot de passe
          lors de votre première connexion pour des raisons de sécurité.
        </p>
      </div>

      <div style="margin-top: 30px; text-align: center;">
        <a href="https://ventemoi.com/login"
           style="display: inline-block; padding: 15px 30px; background-color: #ff6b35;
                  color: white; text-decoration: none; border-radius: 30px; font-weight: bold;">
          Se connecter maintenant
        </a>
      </div>

      <p style="margin-top: 30px; color: #666;">
        Si vous avez des questions, n'hésitez pas à nous contacter.
      </p>

      <p>
        À très bientôt sur Vente Moi !<br>
        <strong>L'équipe Vente Moi</strong>
      </p>
    ''';

    final emailData = {
      'to': toEmail,
      'message': {
        'subject': 'Votre compte Vente Moi a été créé',
        'html': content,
      },
    };

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('mail')
        .add(emailData);
  }
}
