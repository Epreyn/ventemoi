import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/sponsorship_screen_controller.dart';

class SponsorshipScreen extends GetView<SponsorshipScreenController> {
  const SponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(SponsorshipScreenController());

    return ScreenLayout(
      fabOnPressed: cc.openCreateUserBottomSheet,
      fabIcon: const Icon(Icons.person_add),
      fabText: const Text('Ajouter un filleul'),
      body: Obx(() {
        final sponsorship = cc.currentSponsorship.value;
        // On récupère la liste d’emails
        final emails = sponsorship?.sponsoredEmails ?? [];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (emails.isEmpty)
                  const Text('Aucun filleul pour le moment.')
                else
                  Column(
                    children: emails
                        .map((e) => ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(e),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
