import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports internes
import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_points_requests_screen_controller.dart';

class AdminPointsRequestsScreen extends StatelessWidget {
  const AdminPointsRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminPointsRequestsScreenController());

    return ScreenLayout(
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Attribuer des bons'),
      fabOnPressed: () {
        cc.openBottomSheet(
          'Attribuer des Bons à une Boutique',
          actionName: 'Créer',
          actionIcon: Icons.check,
        );
      },
      body: Obx(() {
        final list = cc.requests.value;
        if (list.isEmpty) {
          return const Center(child: Text('Aucune demande de bons'));
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
                    //rows: cc.dataRows(list),
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
