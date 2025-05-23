import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/client_history_screen_controller.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc =
        Get.put(ClientHistoryScreenController(), tag: 'client-history-screen');

    return ScreenLayout(
      noFAB: true,
      body: Obx(() {
        final list = cc.purchases;
        if (list.isEmpty) {
          return const Center(child: Text('Aucun achat pour l’instant'));
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
