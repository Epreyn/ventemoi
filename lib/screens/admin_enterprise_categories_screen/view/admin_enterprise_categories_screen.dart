import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

// Imports divers
import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_enterprise_categories_screen_controller.dart';

class AdminEnterpriseCategoriesScreen extends StatelessWidget {
  const AdminEnterpriseCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminEnterpriseCategoriesScreenController(),
        tag: 'admin-enterprise-categories-screen');

    return ScreenLayout(
      fabOnPressed: cc.openCreateBottomSheet,
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Ajouter Catégorie Entreprise'),
      body: Obx(() {
        final list = cc.categories;
        if (list.isEmpty) {
          return const Center(child: Text('Aucune catégorie entreprise.'));
        }
        return ReorderableListView.builder(
          itemCount: list.length,
          onReorder: cc.onReorder,
          padding: EdgeInsets.only(
            top: UniquesControllers().data.baseSpace * 2,
            bottom: UniquesControllers().data.baseSpace * 8,
          ),
          itemBuilder: (context, index) {
            final cat = list[index];
            return Column(
              key: ValueKey(cat.id),
              children: [
                ListTile(
                  title: Text(cat.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => cc.openEditBottomSheet(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => cc.openDeleteAlertDialog(cat),
                      ),
                      const CustomSpace(widthMultiplier: 2),
                    ],
                  ),
                ),
                Divider(
                  height: 0,
                  thickness: 1,
                  indent: UniquesControllers().data.baseSpace * 2,
                  endIndent: UniquesControllers().data.baseSpace * 2,
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
