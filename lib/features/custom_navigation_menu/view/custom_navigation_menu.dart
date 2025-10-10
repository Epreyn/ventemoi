import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

    // Synchroniser l'index quand le drawer est ouvert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cdc.syncIndexWithCurrentRoute();
    });

    return Drawer(
      backgroundColor: CustomTheme.lightScheme().surface,
      child: Container(
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().surface,
        ),
        child: Stack(
          children: [
            // Cercles décoratifs en arrière-plan
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.15),
                      CustomTheme.lightScheme().primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.1),
                      CustomTheme.lightScheme().primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Contenu principal
            Column(
              children: [
                // Header moderne avec effet glassmorphique
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            CustomTheme.lightScheme().surface.withOpacity(0.7),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CustomTheme.lightScheme().primary.withOpacity(0.15),
                            CustomTheme.lightScheme().primary.withOpacity(0.1),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 3),
                          child: Column(
                            children: [
                              // Logo avec effet glassmorphique
                              Container(
                                padding: EdgeInsets.all(
                                    UniquesControllers().data.baseSpace * 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width:
                                      UniquesControllers().data.baseSpace * 10,
                                  height:
                                      UniquesControllers().data.baseSpace * 10,
                                  child: const CustomLogo(),
                                ),
                              ),
                              SizedBox(
                                  height:
                                      UniquesControllers().data.baseSpace * 2),

                              // Texte du header
                              Text(
                                'VENTE MOI',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 3,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                  height: UniquesControllers().data.baseSpace *
                                      0.5),
                              Text(
                                'Le Don des Affaires',
                                style: TextStyle(
                                  color: CustomTheme.lightScheme().primary,
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            Container(
                              padding: EdgeInsets.all(
                                  UniquesControllers().data.baseSpace * 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.hourglass_empty,
                                size: UniquesControllers().data.baseSpace * 6,
                                color: CustomTheme.lightScheme()
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                            SizedBox(
                                height:
                                    UniquesControllers().data.baseSpace * 2),
                            Text(
                              'Aucun menu disponible',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize:
                                    UniquesControllers().data.baseSpace * 2,
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
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(
                            horizontal:
                                UniquesControllers().data.baseSpace * 1.5,
                            vertical: UniquesControllers().data.baseSpace * 0.5,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: isSelected
                                  ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.15),
                                            CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.08),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
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
                                        horizontal: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                        vertical: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.8,
                                      ),
                                      child: Row(
                                        children: [
                                          // Icône avec fond glassmorphique
                                          Container(
                                            width: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                5,
                                            height: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                5,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: isSelected
                                                    ? [
                                                        CustomTheme
                                                                .lightScheme()
                                                            .primary,
                                                        CustomTheme
                                                                .lightScheme()
                                                            .primary
                                                            .withOpacity(0.8),
                                                      ]
                                                    : [
                                                        Colors.white
                                                            .withOpacity(0.2),
                                                        Colors.white
                                                            .withOpacity(0.1),
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: CustomTheme
                                                                .lightScheme()
                                                            .primary
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Icon(
                                              item.iconData,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              size: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  2.5,
                                            ),
                                          ),
                                          SizedBox(
                                              width: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  2),

                                          // Texte
                                          Expanded(
                                            child: Text(
                                              item.text ?? '',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? CustomTheme.lightScheme()
                                                        .primary
                                                    : Colors.grey[800],
                                                fontSize: UniquesControllers()
                                                        .data
                                                        .baseSpace *
                                                    2,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),

                                          // Flèche indicatrice
                                          if (isSelected)
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: CustomTheme.lightScheme()
                                                  .primary,
                                              size: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  2,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                // Footer avec déconnexion glassmorphique
                Container(
                  margin:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400.withOpacity(0.8),
                              Colors.red.shade600.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showLogoutDialog(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    UniquesControllers().data.baseSpace * 3,
                                vertical:
                                    UniquesControllers().data.baseSpace * 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                      width:
                                          UniquesControllers().data.baseSpace),
                                  Text(
                                    'DÉCONNEXION',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          UniquesControllers().data.baseSpace *
                                              1.8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
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
    );
  }

  // Dialog de confirmation de déconnexion glassmorphique
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Transparent car on gère l'overlay nous-mêmes
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Overlay noir transparent qui couvre tout
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(), // Fermer en cliquant sur l'overlay
                child: Container(
                  color: Colors.black.withOpacity(0.5), // Voile noir semi-transparent
                ),
              ),
            ),
            // Dialog centré
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
              padding:
                  EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône avec effet glassmorphique
                  Container(
                          width: UniquesControllers().data.baseSpace * 10,
                          height: UniquesControllers().data.baseSpace * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400.withOpacity(0.2),
                                Colors.red.shade600.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade600,
                            size: UniquesControllers().data.baseSpace * 5,
                          ),
                        ),
                        SizedBox(
                            height: UniquesControllers().data.baseSpace * 3),

                        // Titre
                        Text(
                          'Déconnexion',
                          style: TextStyle(
                            fontSize: UniquesControllers().data.baseSpace * 3,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                            height: UniquesControllers().data.baseSpace * 2),

                        // Message
                        Container(
                          padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 2),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Êtes-vous sûr de vouloir vous déconnecter ?',
                            style: TextStyle(
                              fontSize: UniquesControllers().data.baseSpace * 2,
                              color: Colors.black.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                            height: UniquesControllers().data.baseSpace * 4),

                        // Boutons
                        Row(
                          children: [
                            // Bouton Annuler
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2,
                                        ),
                                      ),
                                      child: Text(
                                        'Annuler',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                width: UniquesControllers().data.baseSpace * 2),

                            // Bouton Déconnexion
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      // Effacer les identifiants sauvegardés pour éviter la reconnexion automatique
                                      final storage = GetStorage('Storage');
                                      storage.remove('saved_email');
                                      storage.remove('saved_password');
                                      storage.write('remember_me', false);

                                      UniquesControllers()
                                          .data
                                          .firebaseAuth
                                          .signOut();
                                      Get.offAllNamed('/login');
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Déconnexion',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                2,
                                            fontWeight: FontWeight.bold,
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
    ],
  );
      },
    );
  }
}
