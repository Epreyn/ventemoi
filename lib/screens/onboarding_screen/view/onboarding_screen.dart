import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../controllers/onboarding_screen_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: CustomTheme.lightScheme().surface,
      body: Stack(
        children: [
          // Fond avec gradient subtil
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomTheme.lightScheme().surface,
                  CustomTheme.lightScheme().surface.withOpacity(0.95),
                  CustomTheme.lightScheme().primary.withOpacity(0.05),
                ],
              ),
            ),
          ),

          // Cercles décoratifs en arrière-plan
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CustomTheme.lightScheme().primary.withOpacity(0.1),
                    CustomTheme.lightScheme().primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CustomTheme.lightScheme().primary.withOpacity(0.08),
                    CustomTheme.lightScheme().primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Header avec skip button glassmorphique
                Padding(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo et titre
                      CustomCardAnimation(
                        index: 0,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: const CustomLogo(),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VENTE MOI',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Le Don des Affaires',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CustomTheme.lightScheme().primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Skip button glassmorphique
                      CustomCardAnimation(
                        index: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: controller.skipOnboarding,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        UniquesControllers().data.baseSpace * 2,
                                    vertical:
                                        UniquesControllers().data.baseSpace,
                                  ),
                                ),
                                child: Text(
                                  'Passer',
                                  style: TextStyle(
                                    color: CustomTheme.lightScheme()
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontSize:
                                        UniquesControllers().data.baseSpace *
                                            1.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu de la page
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 60 : 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Container glassmorphique pour l'image
                              CustomCardAnimation(
                                index: 2,
                                child: Container(
                                  height: screenHeight * 0.35,
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    maxWidth: isTablet ? 500 : 400,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        child: _buildImage(page.imagePath),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const CustomSpace(heightMultiplier: 4),

                              // Titre avec animation
                              CustomCardAnimation(
                                index: 3,
                                child: Text(
                                  page.title,
                                  style: TextStyle(
                                    fontSize: isTablet ? 32 : 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const CustomSpace(heightMultiplier: 2),

                              // Description dans un container glassmorphique
                              CustomCardAnimation(
                                index: 4,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isTablet ? 450 : 350,
                                  ),
                                  padding: EdgeInsets.all(
                                      UniquesControllers().data.baseSpace * 2),
                                  decoration: BoxDecoration(
                                    color: CustomTheme.lightScheme()
                                        .primary
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    page.description,
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      color: CustomTheme.lightScheme()
                                          .onSurface
                                          .withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),

                // Navigation bottom sans effet de flou
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
                  child: Column(
                    children: [
                      // Indicateurs de page avec design minimaliste
                      CustomCardAnimation(
                        index: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                            vertical: UniquesControllers().data.baseSpace,
                          ),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Obx(() => Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  controller.pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: EdgeInsets.symmetric(
                                      horizontal:
                                          UniquesControllers().data.baseSpace *
                                              0.5,
                                    ),
                                    width: controller.currentPage.value == index
                                        ? UniquesControllers().data.baseSpace *
                                            4
                                        : UniquesControllers().data.baseSpace *
                                            1.5,
                                    height:
                                        UniquesControllers().data.baseSpace *
                                            1.5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        UniquesControllers().data.baseSpace,
                                      ),
                                      color: controller.currentPage.value ==
                                              index
                                          ? CustomTheme.lightScheme().primary
                                          : CustomTheme.lightScheme()
                                              .primary
                                              .withOpacity(0.2),
                                      boxShadow: controller.currentPage.value ==
                                              index
                                          ? [
                                              BoxShadow(
                                                color: CustomTheme.lightScheme()
                                                    .primary
                                                    .withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                  ),
                                ),
                              )),
                        ),
                      ),

                      const CustomSpace(heightMultiplier: 3),

                      // Bouton d'action principal avec design épuré
                      CustomCardAnimation(
                        index: 6,
                        child: Obx(() {
                          final isLastPage = controller.currentPage.value ==
                              controller.pages.length - 1;
                          final buttonText = controller.pages.isNotEmpty &&
                                  isLastPage &&
                                  controller.pages[controller.currentPage.value]
                                          .buttonText !=
                                      null
                              ? controller.pages[controller.currentPage.value]
                                  .buttonText!
                              : 'Suivant';

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  CustomTheme.lightScheme().primary,
                                  CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: controller.nextPage,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical:
                                        UniquesControllers().data.baseSpace * 2,
                                    horizontal: isLastPage
                                        ? UniquesControllers().data.baseSpace *
                                            6
                                        : UniquesControllers().data.baseSpace *
                                            8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        buttonText.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      if (!isLastPage) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2.5,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    return FutureBuilder(
      future: _checkImageExists(imagePath),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.asset(
            imagePath,
            fit: BoxFit.contain,
          );
        } else {
          // Logo avec effet glassmorphique si pas d'image
          return Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CustomLogo(),
              ),
            ),
          );
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
