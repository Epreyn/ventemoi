import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_commissions_screen_controller.dart';

class AdminCommissionsScreen extends StatelessWidget {
  const AdminCommissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminCommissionsScreenController());

    return ScreenLayout(
      fabOnPressed: cc.openCreateBottomSheet,
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Créer une commission'),
      body: Obx(() {
        final list = cc.commissionsList;
        if (list.isEmpty) {
          return const Center(child: Text('Aucune commission définie.'));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final comm = list[index];
            final minVal = comm.minAmount;
            final maxVal = comm.isInfinite ? '∞' : '${comm.maxAmount}';
            final mainLine = 'De $minVal € à $maxVal € => ${comm.percentage}%';

            String subLine = '';
            if (comm.emailException.isNotEmpty) {
              subLine += 'Exception pour email: ${comm.emailException} | ';
            }
            if (comm.associationPercentage > 0) {
              subLine += 'Assoc: ${comm.associationPercentage}%';
            }

            return ListTile(
              title: Text(mainLine),
              subtitle: subLine.isNotEmpty ? Text(subLine) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => cc.openEditBottomSheet(comm),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => cc.deleteCommission(comm.id),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
