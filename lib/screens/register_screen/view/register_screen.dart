import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/unique_controllers.dart';
import 'package:ventemoi/core/models/user_type.dart';
import 'package:ventemoi/core/routes/app_routes.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';
import 'package:ventemoi/features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import 'package:ventemoi/features/custom_fab_button/view/custom_fab_button.dart';
import 'package:ventemoi/features/custom_icon_button/view/custom_icon_button.dart';
import 'package:ventemoi/features/custom_profile_image_picker/view/custom_profile_image_picker.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';
import 'package:ventemoi/features/custom_text_form_field/view/custom_text_form_field.dart';
import 'package:ventemoi/features/screen_layout/view/screen_layout.dart';

import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar_title/view/custom_app_bar_title.dart';
import '../controllers/register_screen_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      RegisterScreenController(),
      tag: UniqueKey().toString(),
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
        child: Form(
          key: cc.formKey,
          child: ListView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomSpace(heightMultiplier: 4),
                  const CustomCardAnimation(
                    index: 0,
                    child: CustomProfileImagePicker(
                      //tag: UniqueKey().toString(),
                      tag: 'profile-image-picker',
                      haveToReset: true,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  CustomCardAnimation(
                    index: 1,
                    child: SizedBox(
                      width: cc.userTypeMaxWidth,
                      child: Text(
                        'Ajoutez une photo de profil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 2,
                        ),
                      ),
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 4),
                  CustomCardAnimation(
                    index: 2,
                    child: CustomDropdownStreamBuilder(
                      tag: cc.userTypeTag,
                      stream: cc.getUserTypesStreamExceptAdmin(),
                      initialItem: cc.currentUserType,
                      labelText: cc.userTypeLabel,
                      maxWith: cc.userTypeMaxWidth,
                      maxHeight: cc.userTypeMaxHeight,
                      onChanged: (UserType? value) {
                        cc.currentUserType.value = value;
                      },
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  Obx(
                    () => CustomCardAnimation(
                      index: 2,
                      child: SizedBox(
                        width: UniquesControllers().data.baseMaxWidth,
                        child: Text(
                          cc.currentUserType.value?.description ?? '',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  CustomCardAnimation(
                    index: 3,
                    child: CustomTextFormField(
                      tag: cc.nameTag,
                      controller: cc.nameController,
                      iconData: cc.nameIconData,
                      labelText: cc.nameLabel,
                      errorText: cc.nameError,
                      textInputAction: cc.nameTextInputAction,
                      keyboardType: cc.nameInputType,
                      validatorPattern: cc.nameValidatorPattern,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  CustomCardAnimation(
                    index: 4,
                    child: CustomTextFormField(
                      tag: cc.emailTag,
                      controller: cc.emailController,
                      iconData: cc.emailIconData,
                      labelText: cc.emailLabel,
                      errorText: cc.emailError,
                      textInputAction: cc.emailTextInputAction,
                      keyboardType: cc.emailInputType,
                      validatorPattern: cc.emailValidatorPattern,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  CustomCardAnimation(
                    index: 5,
                    child: CustomTextFormField(
                      tag: cc.passwordTag,
                      controller: cc.passwordController,
                      iconData: cc.passwordIconData,
                      labelText: cc.passwordLabel,
                      errorText: cc.passwordError,
                      isPassword: true,
                      textInputAction: cc.passwordTextInputAction,
                      keyboardType: cc.passwordInputType,
                      validatorPattern: cc.passwordValidatorPattern,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  CustomCardAnimation(
                    index: 6,
                    child: CustomTextFormField(
                      tag: cc.confirmPasswordTag,
                      controller: cc.confirmPasswordController,
                      iconData: cc.confirmPasswordIconData,
                      labelText: cc.confirmPasswordLabel,
                      errorText: cc.confirmPasswordError,
                      isPassword: true,
                      textInputAction: cc.confirmPasswordTextInputAction,
                      keyboardType: cc.confirmPasswordInputType,
                      validatorPattern: cc.confirmPasswordValidatorPattern,
                    ),
                  ),
                  // Erreur si pass != confirm
                  Obx(
                    () => Visibility(
                      visible: !cc.isConfirmedPassword.value,
                      child: const Text(
                        'Les mots de passe ne correspondent pas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 4),
                  CustomCardAnimation(
                    index: 7,
                    child: CustomFABButton(
                      tag: 'register-button',
                      iconData: Icons.app_registration_rounded,
                      text: 'S\'inscrire'.toUpperCase(),
                      onPressed: () {
                        cc.isPressedRegisterButton.value = true;
                        if (cc.isPressedRegisterButton.value &&
                            cc.checkPasswordConfirmation()) {
                          cc.isConfirmedPassword.value = true;
                          cc.register();
                        } else {
                          cc.isConfirmedPassword.value = false;
                        }
                      },
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
