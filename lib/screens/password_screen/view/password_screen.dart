import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar_title/view/custom_app_bar_title.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../../features/custom_icon_button/view/custom_icon_button.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/password_screen_controller.dart';

class PasswordScreen extends StatelessWidget {
  const PasswordScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    PasswordScreenController cc = Get.put(
      PasswordScreenController(),
      tag: 'password-screen',
    );

    return ScreenLayout(
      appBar: CustomAppBar(
        leadingWidgetNumber: 8,
        leading: Row(
          children: [
            CustomIconButton(
              tag: 'backButton',
              iconData: Icons.arrow_back_outlined,
              onPressed: () => Get.offNamed(Routes.login),
            ),
            CustomAppBarTitle(title: cc.pageTitle),
          ],
        ),
      ),
      noFAB: true,
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const CustomSpace(heightMultiplier: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomLogo(),
                    const CustomSpace(widthMultiplier: 2),
                    Column(
                      children: [
                        CustomCardAnimation(
                          index: 1,
                          direction: Direction.left,
                          child: Text(
                            'VENTE MOI',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 6,
                                ),
                          ),
                        ),
                        CustomCardAnimation(
                          index: 1,
                          direction: Direction.left,
                          child: Text(
                            'Le Don des Affaires',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 2,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const CustomSpace(heightMultiplier: 4),
                CustomCardAnimation(
                  index: 2,
                  child: cc.resetText(),
                ),
                const CustomSpace(heightMultiplier: 4),
                CustomCardAnimation(
                  index: 3,
                  child: CustomTextFormField(
                    tag: cc.emailTag,
                    controller: cc.emailController,
                    iconData: cc.emailIconData,
                    labelText: cc.emailLabel,
                    errorText: cc.emailError,
                    keyboardType: cc.emailInputType,
                  ),
                ),
                const CustomSpace(heightMultiplier: 4),
                CustomCardAnimation(
                  index: 4,
                  child: CustomFABButton(
                    tag: cc.resetPasswordTag,
                    text: cc.resetPasswordLabel,
                    iconData: cc.resetPasswordIconData,
                    onPressed: () {
                      cc.resetPassword();
                    },
                  ),
                ),
                const CustomSpace(heightMultiplier: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
