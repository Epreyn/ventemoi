import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/pro_points_screen_controller.dart';

class ProPointsScreen extends StatelessWidget {
  const ProPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ProPointsScreenController(), tag: 'pro-points-screen');

    return ScreenLayout(
      fabOnPressed: cc.openAddPointsBottomSheet,
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Attribuer des Points'),
      body: Obx(() {
        final list = cc.pointsList;
        if (list.isEmpty) {
          return const Center(child: Text('Aucune attribution de points'));
        }
        return LayoutBuilder(
          builder: (ctx, constraints) {
            return SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                    horizontalMargin: UniquesControllers().data.baseSpace * 2,
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
    );
  }
}
