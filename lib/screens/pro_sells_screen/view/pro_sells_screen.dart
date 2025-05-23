import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports internes
import '../../../core/classes/unique_controllers.dart';

import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/pro_sells_screen_controller.dart';

class ProSellsScreen extends StatelessWidget {
  const ProSellsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ProSellsScreenController());

    return ScreenLayout(
      noFAB: true,
      body: Obx(() {
        final list = cc.purchases;
        if (list.isEmpty) {
          return const Center(child: Text('Aucune vente trouvée.'));
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

                    // Indices de tri
                    sortColumnIndex: cc.sortColumnIndex.value,
                    sortAscending: cc.sortAscending.value,

                    // Les colonnes
                    columns: cc.dataColumns,

                    // Les lignes
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
