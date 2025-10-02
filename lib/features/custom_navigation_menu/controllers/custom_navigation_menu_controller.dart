import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_bottom_app_bar/models/custom_bottom_app_bar_icon_button_model.dart';

class CustomNavigationMenuController extends GetxController {
  RxList<CustomBottomAppBarIconButtonModel> items =
      <CustomBottomAppBarIconButtonModel>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadItems();
    syncIndexWithCurrentRoute();
  }

  Future<void> loadItems() async {
    await UniquesControllers().data.loadIconList(
          UniquesControllers().data.firebaseAuth.currentUser!.uid,
        );
    items.value = UniquesControllers().data.dynamicIconList;
    // Synchroniser après le chargement des items
    syncIndexWithCurrentRoute();
  }

  void onItemTap(int index) {
    if (index < 0 || index >= items.length) return;
    UniquesControllers().data.currentNavigationMenuIndex.value = index;
    final item = items[index];
    item.onPressed();
  }

  // Méthode pour synchroniser l'index avec la route actuelle
  void syncIndexWithCurrentRoute() {
    if (items.isEmpty) return;

    final currentRoute = Get.currentRoute;
    print('Current route: $currentRoute');

    // Mapping des routes vers les index
    int newIndex = 0; // Par défaut sur Explorer

    // Map de correspondance route -> nom de menu (basé sur les routes officielles)
    final routeToMenuMap = {
      '/shop-establishment': ['explorer', 'home', 'accueil'],
      '/pro-establishment-profile': ['fiche', 'établissement', 'ma fiche', 'ma boutique'],
      '/quotes': ['devis', 'quote'],
      '/profile': ['profil', 'profile', 'mon profil'],
      '/pro-sells': ['vente', 'sell', 'mes ventes'],
      '/client-history': ['achat', 'purchase', 'mes achats', 'historique'],
      '/pro-points': ['point', 'fidélité', 'mes points'],
      '/admin-users': ['admin', 'administration', 'utilisateur'],
      '/admin-establishments': ['admin', 'administration', 'établissement'],
      '/admin-sells': ['admin', 'administration', 'vente'],
      '/admin-quotes': ['admin', 'administration', 'devis', 'quote'],
      '/admin-points': ['admin', 'administration', 'point'],
      '/admin-categories': ['admin', 'administration', 'catégorie'],
      '/admin-commissions': ['admin', 'administration', 'commission'],
      '/sponsorship': ['parrainage', 'sponsor', 'filleul'],
      '/pro-request-offer': ['offre', 'offer', 'promotion'],
    };

    // Chercher la correspondance exacte d'abord
    bool found = false;
    for (final entry in routeToMenuMap.entries) {
      if (currentRoute.contains(entry.key)) {
        // Trouver l'item correspondant dans le menu
        for (int i = 0; i < items.length; i++) {
          final itemName = (items[i].text ?? items[i].tag).toLowerCase();
          for (final keyword in entry.value) {
            if (itemName.contains(keyword)) {
              newIndex = i;
              found = true;
              break;
            }
          }
          if (found) break;
        }
        if (found) break;
      }
    }

    // Si pas de correspondance trouvée, utiliser une logique de fallback
    if (!found) {
      // Cas spécial : entreprise non enregistrée arrive sur fiche établissement
      if (currentRoute.contains('establishment') || currentRoute.contains('boutique')) {
        for (int i = 0; i < items.length; i++) {
          final itemText = (items[i].text ?? items[i].tag).toLowerCase();
          if (itemText.contains('fiche') ||
              itemText.contains('établissement') ||
              itemText.contains('boutique')) {
            newIndex = i;
            found = true;
            break;
          }
        }
      }
      // Cas admin générique
      else if (currentRoute.contains('/admin')) {
        for (int i = 0; i < items.length; i++) {
          if ((items[i].text ?? items[i].tag).toLowerCase().contains('admin')) {
            newIndex = i;
            found = true;
            break;
          }
        }
      }
      // Cas pro générique
      else if (currentRoute.contains('/pro-')) {
        for (int i = 0; i < items.length; i++) {
          final itemText = (items[i].text ?? items[i].tag).toLowerCase();
          if (itemText.contains('pro') || itemText.contains('espace')) {
            newIndex = i;
            found = true;
            break;
          }
        }
      }
      // Par défaut sur Explorer/Home
      else if (currentRoute == '/' || currentRoute.isEmpty) {
        newIndex = 0;
      }
    }

    // Log pour debug
    final itemText = items.length > newIndex ? (items[newIndex].text ?? items[newIndex].tag) : 'none';
    print('Sync menu: route=$currentRoute, index=$newIndex, item=$itemText');

    // Mettre à jour l'index
    UniquesControllers().data.currentNavigationMenuIndex.value = newIndex;
  }

  // Helper pour extraire la route d'un item
  String _getRouteFromItem(CustomBottomAppBarIconButtonModel item) {
    // Extraire la route basée sur le texte ou tag de l'item
    final name = (item.text ?? item.tag).toLowerCase();

    if (name.contains('explorer') || name.contains('home')) return '/';
    if (name.contains('fiche') || name.contains('établissement')) return '/establishment';
    if (name.contains('devis')) return '/quotes';
    if (name.contains('profil')) return '/profile';
    if (name.contains('pro')) return '/pro-screen';
    if (name.contains('vente')) return '/sells';
    if (name.contains('achat')) return '/purchases';
    if (name.contains('admin')) return '/admin';

    return '/';
  }
}
