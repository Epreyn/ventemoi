import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';

class ProSellsScreenController extends GetxController with ControllerMixin {
  String pageTitle = 'Ventes'.toUpperCase();
  String customBottomAppBarTag = 'pro-sells-bottom-app-bar';

  RxList<Purchase> purchases = <Purchase>[].obs;
  RxList<Purchase> filteredPurchases = <Purchase>[].obs;

  final RxString filterStatus = 'all'.obs;
  final RxString sortOrder = 'date_desc'.obs;
  final RxString periodFilter = 'all'.obs;
  final TextEditingController searchController = TextEditingController();

  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  StreamSubscription<List<Purchase>>? _purchasesSub;

  // Pour la validation (switch) => code
  Rx<Purchase?> editingPurchase = Rx<Purchase?>(null);
  final TextEditingController codeController = TextEditingController();

  // Cache pour les informations des utilisateurs
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void onInit() {
    super.onInit();
    _purchasesSub = getProPurchasesStream().listen((list) {
      purchases.value = list;
      applyFilters();
    });
  }

  @override
  void onClose() {
    _purchasesSub?.cancel();
    codeController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Récupération des purchases où seller_id == currentUser
  Stream<List<Purchase>> getProPurchasesStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('purchases')
        .where('seller_id', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Purchase.fromDocumentSnapshot(d)).toList());
  }

  // Méthode pour appliquer les filtres et le tri
  void applyFilters() async {
    List<Purchase> filtered = purchases.toList();

    // Filtre par statut
    switch (filterStatus.value) {
      case 'pending':
        filtered = filtered.where((p) => !p.isReclaimed).toList();
        break;
      case 'reclaimed':
        filtered = filtered.where((p) => p.isReclaimed).toList();
        break;
      default:
        // 'all' - pas de filtre
        break;
    }

    // Filtre par période
    final now = DateTime.now();
    switch (periodFilter.value) {
      case 'today':
        filtered = filtered.where((p) {
          return p.date.year == now.year &&
              p.date.month == now.month &&
              p.date.day == now.day;
        }).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((p) => p.date.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered = filtered.where((p) => p.date.isAfter(monthAgo)).toList();
        break;
      default:
        // 'all' - pas de filtre de période
        break;
    }

    // Filtre par recherche
    final searchQuery = searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      // Charger les informations des utilisateurs si nécessaire
      for (final purchase in filtered) {
        if (!_userCache.containsKey(purchase.buyerId)) {
          try {
            final userDoc = await UniquesControllers()
                .data
                .firebaseFirestore
                .collection('users')
                .doc(purchase.buyerId)
                .get();

            if (userDoc.exists) {
              _userCache[purchase.buyerId] =
                  userDoc.data() as Map<String, dynamic>;
            }
          } catch (e) {
            // Ignorer les erreurs
          }
        }
      }

      // Filtrer par nom ou email
      filtered = filtered.where((p) {
        final userData = _userCache[p.buyerId];
        if (userData == null) return false;

        final name = (userData['name'] ?? '').toString().toLowerCase();
        final email = (userData['email'] ?? '').toString().toLowerCase();

        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    }

    // Tri
    switch (sortOrder.value) {
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount_asc':
        filtered.sort(
            (a, b) => (a.couponsCount * 50).compareTo(b.couponsCount * 50));
        break;
      case 'amount_desc':
        filtered.sort(
            (a, b) => (b.couponsCount * 50).compareTo(a.couponsCount * 50));
        break;
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    filteredPurchases.value = filtered;
  }

  // Méthode pour définir le filtre de statut
  void setFilter(String filter) {
    filterStatus.value = filter;
    applyFilters();
  }

  // Méthode pour définir l'ordre de tri
  void setSortOrder(String order) {
    sortOrder.value = order;
    applyFilters();
  }

  // Méthode pour définir le filtre de période
  void setPeriodFilter(String period) {
    periodFilter.value = period;
    applyFilters();
  }

  // Méthode pour réinitialiser tous les filtres
  void clearFilters() {
    searchController.clear();
    filterStatus.value = 'all';
    periodFilter.value = 'all';
    sortOrder.value = 'date_desc';
    applyFilters();
  }

  // Getter réactif pour vérifier s'il y a des filtres actifs
  bool get hasActiveFilters {
    return filterStatus.value != 'all' ||
        periodFilter.value != 'all' ||
        searchController.text.isNotEmpty ||
        sortOrder.value != 'date_desc';
  }

  // Méthode pour ouvrir la boîte de dialogue de réclamation
  void openReclaimDialog() {
    codeController.clear();
    _showReclaimDialog();
  }

  // Méthode privée pour afficher la boîte de dialogue personnalisée
  void _showReclaimDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: CustomTheme.lightScheme().primary.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding:
                    EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.lock_open,
                        color: CustomTheme.lightScheme().primary,
                        size: 40,
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 2),

                    // Titre
                    Text(
                      'Validation de la récupération',
                      style: TextStyle(
                        fontSize: UniquesControllers().data.baseSpace * 2.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const CustomSpace(heightMultiplier: 1),

                    // Sous-titre
                    Text(
                      'Entrez le code fourni par le client',
                      style: TextStyle(
                        fontSize: UniquesControllers().data.baseSpace * 1.6,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const CustomSpace(heightMultiplier: 3),

                    // Champ de code
                    TextField(
                      controller: codeController,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: UniquesControllers().data.baseSpace * 2.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 2.5,
                          color: Colors.grey[400],
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: CustomTheme.lightScheme().primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: UniquesControllers().data.baseSpace * 3,
                          vertical: UniquesControllers().data.baseSpace * 2,
                        ),
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 3),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    UniquesControllers().data.baseSpace * 1.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize:
                                    UniquesControllers().data.baseSpace * 1.8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  CustomTheme.lightScheme().primary,
                                  CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  Get.back();
                                  await validateReclamation();
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical:
                                        UniquesControllers().data.baseSpace *
                                            1.8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Valider',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Méthode pour valider la réclamation
  Future<void> validateReclamation() async {
    final pur = editingPurchase.value;
    if (pur == null) return;

    final inputCode = codeController.text.trim();
    codeController.clear();

    if (inputCode.isEmpty) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Veuillez entrer un code',
            true,
          );
      return;
    }

    if (inputCode != pur.reclamationPassword) {
      UniquesControllers().data.snackbar(
            'Code invalide',
            'Le code entré ne correspond pas',
            true,
          );
      return;
    }

    // code correct => isReclaimed = true
    try {
      UniquesControllers().data.isInAsyncCall.value = true;
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('purchases')
          .doc(pur.id)
          .update({
        'isReclaimed': true,
      });
      UniquesControllers().data.isInAsyncCall.value = false;

      // Message de succès avec style
      UniquesControllers().data.snackbar(
            'Succès',
            'La vente a été validée avec succès',
            false,
          );
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar(
            'Erreur',
            'Une erreur est survenue',
            true,
          );
    }
  }

  // Override requis par ControllerMixin avec tous les paramètres
  @override
  void openAlertDialog(String title,
      {String? confirmText, Color? confirmColor, IconData? icon}) {
    // Cette méthode n'est pas utilisée dans ce contrôleur
    // On utilise plutôt openReclaimDialog() et _showReclaimDialog()
  }

  // Override requis par ControllerMixin
  @override
  Widget alertDialogContent() => const SizedBox.shrink();

  // Override requis par ControllerMixin
  @override
  Future<void> actionAlertDialog() async {
    // Cette méthode n'est pas utilisée dans ce contrôleur
    // On utilise plutôt validateReclamation()
  }
}
