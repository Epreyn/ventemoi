import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';

import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_users_screen_controller.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminUsersScreenController(), tag: 'admin-users-screen');

    return ScreenLayout(
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Créer un utilisateur'),
      fabOnPressed: cc.openCreateUserBottomSheet,
      body: _buildBody(cc),
    );
  }

  Widget _buildBody(AdminUsersScreenController cc) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(90),
              ),
            ),
            onChanged: cc.onSearchChanged,
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = cc.filteredUsers;
            if (list.isEmpty) {
              return const Center(
                  child: Text('Aucun utilisateur correspondant'));
            }
            return LayoutBuilder(
              builder: (ctx, constraints) {
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingTextStyle: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 2,
                          fontWeight: FontWeight.bold,
                        ),
                        dataTextStyle: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 1.75,
                          color: Colors.black87,
                        ),
                        columnSpacing: UniquesControllers().data.baseSpace * 4,
                        horizontalMargin:
                            UniquesControllers().data.baseSpace * 2,
                        sortColumnIndex: cc.sortColumnIndex.value,
                        sortAscending: cc.sortAscending.value,
                        columns: cc.dataColumns,
                        rows: cc.dataRows(list),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
