import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/onboarding_screen_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingScreenController());

    return Scaffold(
      backgroundColor: CustomTheme.lightScheme().surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                    EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                child: TextButton(
                  onPressed: controller.skipOnboarding,
                  child: Text(
                    'Passer',
                    style: TextStyle(
                      color:
                          CustomTheme.lightScheme().onSurface.withOpacity(0.6),
                      fontSize: UniquesControllers().data.baseSpace * 2,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: Obx(() {
                if (controller.pages.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: CustomTheme.lightScheme().primary,
                    ),
                  );
                }

                return PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: (index) =>
                      controller.currentPage.value = index,
                  itemCount: controller.pages.length,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];
                    return Padding(
                      padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image
                          Expanded(
                            flex: 3,
                            child: _buildImage(page.imagePath),
                          ),

                          const CustomSpace(heightMultiplier: 4),

                          // Title
                          Text(
                            page.title,
                            style: TextStyle(
                              fontSize:
                                  UniquesControllers().data.baseSpace * 3.5,
                              fontWeight: FontWeight.bold,
                              color: CustomTheme.lightScheme().onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const CustomSpace(heightMultiplier: 2),

                          // Description
                          Text(
                            page.description,
                            style: TextStyle(
                              fontSize: UniquesControllers().data.baseSpace * 2,
                              color: CustomTheme.lightScheme()
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const CustomSpace(heightMultiplier: 4),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // Bottom navigation
            Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 4),
              child: Column(
                children: [
                  // Page indicators
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          controller.pages.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: UniquesControllers().data.baseSpace,
                            ),
                            width: UniquesControllers().data.baseSpace * 1.5,
                            height: UniquesControllers().data.baseSpace * 1.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.currentPage.value == index
                                  ? CustomTheme.lightScheme().primary
                                  : CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.3),
                            ),
                          ),
                        ),
                      )),

                  const CustomSpace(heightMultiplier: 4),

                  // Action button
                  Obx(() {
                    final isLastPage = controller.currentPage.value ==
                        controller.pages.length - 1;
                    final buttonText = controller.pages.isNotEmpty &&
                            isLastPage &&
                            controller.pages[controller.currentPage.value]
                                    .buttonText !=
                                null
                        ? controller
                            .pages[controller.currentPage.value].buttonText!
                        : 'Suivant';

                    return ElevatedButton(
                      onPressed: controller.nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomTheme.lightScheme().primary,
                        foregroundColor: CustomTheme.lightScheme().onPrimary,
                        padding: EdgeInsets.symmetric(
                          vertical: UniquesControllers().data.baseSpace * 2,
                          horizontal: UniquesControllers().data.baseSpace * 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            UniquesControllers().data.baseSpace * 3,
                          ),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    // Vérifier si l'image existe, sinon afficher le logo
    return FutureBuilder(
      future: _checkImageExists(imagePath),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.asset(
            imagePath,
            fit: BoxFit.contain,
          );
        } else {
          // Si l'image n'existe pas, afficher le logo par défaut
          return const CustomLogo();
        }
      },
    );
  }

  Future<bool> _checkImageExists(String path) async {
    try {
      await precacheImage(AssetImage(path), Get.context!);
      return true;
    } catch (_) {
      return false;
    }
  }
}
