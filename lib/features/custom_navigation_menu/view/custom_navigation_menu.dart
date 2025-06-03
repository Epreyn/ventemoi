import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../controllers/custom_navigation_menu_controller.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../core/classes/unique_controllers.dart';

class CustomNavigationMenu extends Drawer {
  const CustomNavigationMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cdc = Get.put(CustomNavigationMenuController());

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header moderne avec fond gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomTheme.lightScheme().primary,
                  CustomTheme.lightScheme().primary.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
                child: Column(
                  children: [
                    // Logo avec effet de fond blanc
                    Container(
                      padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: UniquesControllers().data.baseSpace * 10,
                        height: UniquesControllers().data.baseSpace * 10,
                        child: const CustomLogo(),
                      ),
                    ),
                    SizedBox(height: UniquesControllers().data.baseSpace * 2),

                    // Texte du header
                    Text(
                      'VENTE MOI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: UniquesControllers().data.baseSpace * 3,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: UniquesControllers().data.baseSpace),
                    Text(
                      'Le Don des Affaires',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: UniquesControllers().data.baseSpace * 1.8,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Info utilisateur
          _buildUserInfo(),

          // Divider décoratif
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 2,
              vertical: UniquesControllers().data.baseSpace,
            ),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Liste des items de navigation
          Expanded(
            child: Obx(() {
              final items = cdc.items;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: UniquesControllers().data.baseSpace * 6,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: UniquesControllers().data.baseSpace * 2),
                      Text(
                        'Aucun menu disponible',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: UniquesControllers().data.baseSpace * 2,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: UniquesControllers().data.baseSpace,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final isSelected = UniquesControllers()
                          .data
                          .currentNavigationMenuIndex
                          .value ==
                      i;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 1.5,
                      vertical: UniquesControllers().data.baseSpace * 0.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          UniquesControllers()
                              .data
                              .currentNavigationMenuIndex
                              .value = i;
                          cdc.onItemTap(i);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                            vertical: UniquesControllers().data.baseSpace * 1.8,
                          ),
                          child: Row(
                            children: [
                              // Icône avec fond
                              Container(
                                width: UniquesControllers().data.baseSpace * 5,
                                height: UniquesControllers().data.baseSpace * 5,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CustomTheme.lightScheme().primary
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.iconData,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size:
                                      UniquesControllers().data.baseSpace * 2.5,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      UniquesControllers().data.baseSpace * 2),

                              // Texte
                              Expanded(
                                child: Text(
                                  item.text ?? '',
                                  style: TextStyle(
                                    color: isSelected
                                        ? CustomTheme.lightScheme().primary
                                        : Colors.grey[800],
                                    fontSize:
                                        UniquesControllers().data.baseSpace * 2,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),

                              // Indicateur de sélection
                              if (isSelected)
                                Container(
                                  width: 4,
                                  height:
                                      UniquesControllers().data.baseSpace * 3,
                                  decoration: BoxDecoration(
                                    color: CustomTheme.lightScheme().primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Footer avec déconnexion stylisée
          Container(
            margin: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLogoutDialog(context);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UniquesControllers().data.baseSpace * 2,
                    vertical: UniquesControllers().data.baseSpace * 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: UniquesControllers().data.baseSpace),
                      const Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher les infos utilisateur
  Widget _buildUserInfo() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(UniquesControllers().data.firebaseAuth.currentUser?.uid)
          .snapshots()
          .map((snap) => snap.data()),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final userName = userData?['name'] ?? 'Utilisateur';
        final userEmail = userData?['email'] ?? '';
        final imageUrl = userData?['image_url'] ?? '';

        return Container(
          padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
          child: Row(
            children: [
              // Avatar utilisateur
              Container(
                width: UniquesControllers().data.baseSpace * 7,
                height: UniquesControllers().data.baseSpace * 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.8),
                      CustomTheme.lightScheme().primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: Colors.white,
                            size: UniquesControllers().data.baseSpace * 3,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: UniquesControllers().data.baseSpace * 3,
                        ),
                ),
              ),
              SizedBox(width: UniquesControllers().data.baseSpace * 2),

              // Nom et email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: UniquesControllers().data.baseSpace * 2.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 1.6,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog de confirmation de déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
              ),
              SizedBox(width: UniquesControllers().data.baseSpace),
              const Text('Déconnexion'),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                UniquesControllers().data.firebaseAuth.signOut();
                Get.offAllNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
