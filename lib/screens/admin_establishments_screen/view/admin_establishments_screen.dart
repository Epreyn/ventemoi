import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_establishments_screen_controller.dart';

class AdminEstablishmentsScreen extends StatelessWidget {
  const AdminEstablishmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminEstablishmentsScreenController());

    return ScreenLayout(
      noFAB: true,
      body: Column(
        children: [
          // Même style pour la barre de recherche
          CustomCardAnimation(
            index: 0,
            child: Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un établissement...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
                onChanged: cc.onSearchChanged,
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              final list = cc.filteredEstablishments;
              if (list.isEmpty) {
                return const Center(
                    child: Text('Aucun établissement correspondant'));
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
                            fontSize:
                                UniquesControllers().data.baseSpace * 1.75,
                            color: Colors.black87,
                          ),
                          columnSpacing:
                              UniquesControllers().data.baseSpace * 4,
                          horizontalMargin:
                              UniquesControllers().data.baseSpace * 2,
                          sortColumnIndex: cc.sortColumnIndex.value,
                          sortAscending: cc.sortAscending.value,
                          columns: cc.dataColumns,
                          rows: cc.dataRows,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
