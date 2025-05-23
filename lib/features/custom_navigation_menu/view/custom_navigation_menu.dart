import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../controllers/custom_navigation_menu_controller.dart';
import '../../../features/custom_logo/view/custom_logo.dart'; // <-- votre CustomLogo
import '../../../core/classes/unique_controllers.dart';

class CustomNavigationMenu extends Drawer {
  const CustomNavigationMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cdc = Get.put(CustomNavigationMenuController());

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: const CustomLogo(),
          ),

          // ----- Liste d’items -----
          Expanded(
            child: Obx(() {
              final items = cdc.items;
              if (items.isEmpty) {
                return const Center(child: Text('Aucun menu disponible'));
              }

              return ListView.builder(
                // On ne veut pas de padding en haut
                padding: EdgeInsets.zero,
                itemCount: items.length,

                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return ListTile(
                    leading: Icon(item.iconData,
                        color: UniquesControllers()
                                    .data
                                    .currentNavigationMenuIndex
                                    .value ==
                                i
                            ? CustomTheme.lightScheme().primary
                            : null),
                    title: Text(item.text ?? '',
                        style: TextStyle(
                          color: UniquesControllers()
                                      .data
                                      .currentNavigationMenuIndex
                                      .value ==
                                  i
                              ? CustomTheme.lightScheme().primary
                              : null,
                        )),
                    onTap: () {
                      Navigator.of(context).pop();
                      UniquesControllers()
                          .data
                          .currentNavigationMenuIndex
                          .value = i;
                      cdc.onItemTap(i);
                    },
                  );
                },
              );
            }),
          ),

          // ----- Bouton Déconnexion en bas -----
          ListTile(
            tileColor: CustomTheme.lightScheme().primary,
            leading:
                Icon(Icons.logout, color: CustomTheme.lightScheme().onPrimary),
            title: Text('Déconnexion',
                style: TextStyle(
                  color: CustomTheme.lightScheme().onPrimary,
                )),
            onTap: () {
              Navigator.of(context).pop();

              UniquesControllers().data.firebaseAuth.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
