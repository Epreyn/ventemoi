import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/unique_controllers.dart';

import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_divider/view/custom_divider.dart';
import '../../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_button/view/custom_text_button.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/login_screen_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    LoginScreenController cc = Get.put(
      LoginScreenController(),
      tag: 'login_screen',
    );

    return ScreenLayout(
      noAppBar: true,
      noFAB: true,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomSpace(heightMultiplier: 2),
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
                                          UniquesControllers().data.baseSpace *
                                              6,
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
                                          UniquesControllers().data.baseSpace *
                                              2,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const CustomSpace(heightMultiplier: 8),
                    CustomCardAnimation(
                      index: 2,
                      child: CustomTextFormField(
                        tag: cc.emailTag,
                        controller: cc.emailController,
                        iconData: cc.emailIconData,
                        textInputAction: cc.emailInputAction,
                        labelText: cc.emailLabel,
                        errorText: cc.emailError,
                        keyboardType: cc.emailInputType,
                        onFieldSubmitted: (value) => cc.login(),
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 2),
                    CustomCardAnimation(
                      index: 3,
                      child: CustomTextFormField(
                        tag: cc.passwordTag,
                        controller: cc.passwordController,
                        iconData: cc.passwordIconData,
                        textInputAction: cc.passwordInputAction,
                        labelText: cc.passwordLabel,
                        errorText: cc.passwordError,
                        keyboardType: cc.passwordInputType,
                        onFieldSubmitted: (value) => cc.login(),
                        isPassword: true,
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 1),
                    CustomCardAnimation(
                      index: 4,
                      direction: Direction.left,
                      child: SizedBox(
                        width: cc.maxWith,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CustomTextButton(
                            tag: cc.forgotPasswordTag,
                            text: cc.forgotPasswordLabel,
                            onPressed: () {
                              cc.passwordScreenOnPressed();
                            },
                          ),
                        ),
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 4),
                    CustomCardAnimation(
                      index: 5,
                      direction: Direction.right,
                      child: CustomFABButton(
                        tag: cc.connectionTag,
                        text: cc.connectionLabel,
                        //color: cc.connectionColor,
                        //iconData: cc.connectionIconData,
                        onPressed: () {
                          cc.login();
                        },
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 1),
                    CustomCardAnimation(
                      index: 6,
                      child: CustomDivider(
                        tag: cc.dividerTag,
                        text: cc.dividerLabel,
                        width: cc.dividerWidth,
                        dividerColor: cc.dividerColor,
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 1),
                    CustomCardAnimation(
                      index: 7,
                      direction: Direction.left,
                      child: CustomFABButton(
                        tag: cc.registerTag,
                        text: cc.registerLabel,
                        color: Colors.black,
                        textColor: Colors.white,
                        onPressed: () {
                          cc.registerScreenOnPressed();
                        },
                      ),
                    ),
                    const CustomSpace(heightMultiplier: 2),
                  ],
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('1.3.2'),
            ),
          )
        ],
      ),
    );
  }
}
