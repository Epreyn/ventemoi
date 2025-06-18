import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:ventemoi/firebase_options.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';

import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_places_autocompletion/view/custom_places_autocompletion.dart';
import '../../../features/custom_profile_image_picker/view/custom_profile_image_picker.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/profile_screen_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ProfileScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      fabOnPressed: cc.updateProfile,
      fabIcon: const Icon(Icons.save_rounded),
      fabText: const Text('Enregistrer'),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: cc.getUserDocStream(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data;
          cc.updateControllers(userData);

          return StreamBuilder<Map<String, dynamic>?>(
            stream: cc.getWalletDocStream(),
            builder: (context, walletSnapshot) {
              final walletData = walletSnapshot.data;
              if (walletData != null) {
                final coupons = walletData['coupons'] ?? 0;
                cc.couponsController.text = '$coupons';

                final bankDetails =
                    walletData['bank_details'] as Map<String, dynamic>?;
                if (bankDetails != null) {
                  cc.holderController.text = bankDetails['holder'] ?? '';
                  cc.ibanController.text = bankDetails['iban'] ?? '';
                  cc.bicController.text = bankDetails['bic'] ?? '';
                }
              } else {
                cc.couponsController.text = '0';
                cc.holderController.text = '';
                cc.ibanController.text = '';
                cc.bicController.text = '';
              }

              return FutureBuilder<String>(
                future: cc.getUserTypeNameByUserId(
                  UniquesControllers().data.firebaseAuth.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  final userType = snapshot.data ?? '';

                  return Center(
                    child: ScrollConfiguration(
                      behavior:
                          const ScrollBehavior().copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet
                                ? 600
                                : UniquesControllers().data.baseMaxWidth,
                          ),
                          child: Form(
                            key: cc.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Section Photo de profil avec glassmorphisme
                                Center(
                                  child: CustomCardAnimation(
                                    index: 0,
                                    child: Container(
                                      width: UniquesControllers()
                                              .data
                                              .baseMaxWidth +
                                          (UniquesControllers().data.baseSpace *
                                              5),
                                      padding: EdgeInsets.all(
                                        UniquesControllers().data.baseSpace * 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.35),
                                            Colors.white.withOpacity(0.25),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.15),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        //borderRadius: BorderRadius.circular(28),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Column(
                                            children: [
                                              CustomProfileImagePicker(
                                                tag: UniqueKey().toString(),
                                              ),
                                              const CustomSpace(
                                                  heightMultiplier: 2),
                                              Text(
                                                'Photo de profil',
                                                style: TextStyle(
                                                  fontSize: UniquesControllers()
                                                          .data
                                                          .baseSpace *
                                                      2.2,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 3),

                                // Section Informations personnelles
                                Center(
                                  child: CustomCardAnimation(
                                    index: 1,
                                    child: Container(
                                      width: UniquesControllers()
                                              .data
                                              .baseMaxWidth +
                                          (UniquesControllers().data.baseSpace *
                                              5),
                                      padding: EdgeInsets.all(
                                        UniquesControllers().data.baseSpace *
                                            2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.35),
                                            Colors.white.withOpacity(0.25),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.15),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        //borderRadius: BorderRadius.circular(28),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: CustomTheme
                                                              .lightScheme()
                                                          .primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .person_outline_rounded,
                                                      color: CustomTheme
                                                              .lightScheme()
                                                          .primary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Informations personnelles',
                                                    style: TextStyle(
                                                      fontSize:
                                                          UniquesControllers()
                                                                  .data
                                                                  .baseSpace *
                                                              2,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const CustomSpace(
                                                  heightMultiplier: 3),
                                              CustomTextFormField(
                                                tag: 'name-text-form-field',
                                                controller: cc.nameController,
                                                labelText: 'Nom',
                                                iconData: Icons.badge_outlined,
                                              ),
                                              const CustomSpace(
                                                  heightMultiplier: 2),
                                              CustomTextFormField(
                                                tag: 'email-text-form-field',
                                                enabled: false,
                                                controller: cc.emailController,
                                                labelText: 'Email',
                                                iconData: Icons.email_outlined,
                                              ),
                                              if (userType ==
                                                  'Particulier') ...[
                                                const CustomSpace(
                                                    heightMultiplier: 2),
                                                CustomPlacesAutocomplete(
                                                  controller: cc
                                                      .personalAddressController,
                                                  apiKey: DefaultFirebaseOptions
                                                      .googleKeyAPI,
                                                  labelText:
                                                      'Adresse personnelle',
                                                  iconData: Icons.home_outlined,
                                                  countries: ['fr'],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                if (userType == 'Boutique') ...[
                                  const CustomSpace(heightMultiplier: 3),
                                  // Section Bons d'achat
                                  Center(
                                    child: CustomCardAnimation(
                                      index: 2,
                                      child: Container(
                                        width: UniquesControllers()
                                                .data
                                                .baseMaxWidth +
                                            (UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                5),
                                        padding: EdgeInsets.all(
                                          UniquesControllers().data.baseSpace *
                                              2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.35),
                                              Colors.white.withOpacity(0.25),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.15),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 8, sigmaY: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: CustomTheme
                                                                .lightScheme()
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .confirmation_number_outlined,
                                                        color: CustomTheme
                                                                .lightScheme()
                                                            .primary,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Bons d\'achat',
                                                      style: TextStyle(
                                                        fontSize:
                                                            UniquesControllers()
                                                                    .data
                                                                    .baseSpace *
                                                                2,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const CustomSpace(
                                                    heightMultiplier: 3),
                                                CustomTextFormField(
                                                  tag:
                                                      'coupons-text-form-field',
                                                  controller:
                                                      cc.couponsController,
                                                  labelText:
                                                      'Nombre de bons (Valeur: ${(int.tryParse(cc.couponsController.text) ?? 0) * 50}€)',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  enabled: false,
                                                  iconData: Icons
                                                      .receipt_long_outlined,
                                                ),
                                                const CustomSpace(
                                                    heightMultiplier: 2),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          CustomTheme
                                                                  .lightScheme()
                                                              .primary,
                                                          CustomTheme
                                                                  .lightScheme()
                                                              .primary
                                                              .withOpacity(0.8),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: CustomTheme
                                                                  .lightScheme()
                                                              .primary
                                                              .withOpacity(0.3),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                              0, 5),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: cc.buyCoupons,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal:
                                                                UniquesControllers()
                                                                        .data
                                                                        .baseSpace *
                                                                    3,
                                                            vertical:
                                                                UniquesControllers()
                                                                        .data
                                                                        .baseSpace *
                                                                    1.5,
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .add_shopping_cart_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                'ACHETER DES BONS',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  letterSpacing:
                                                                      1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                if (userType == 'Boutique' ||
                                    userType == 'Entreprise') ...[
                                  const CustomSpace(heightMultiplier: 3),
                                  // Section Informations bancaires
                                  Center(
                                    child: CustomCardAnimation(
                                      index: 3,
                                      child: Container(
                                        width: UniquesControllers()
                                                .data
                                                .baseMaxWidth +
                                            (UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                5),
                                        padding: EdgeInsets.all(
                                          UniquesControllers().data.baseSpace *
                                              2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.35),
                                              Colors.white.withOpacity(0.25),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.15),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 8, sigmaY: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: CustomTheme
                                                                .lightScheme()
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .account_balance_outlined,
                                                        color: CustomTheme
                                                                .lightScheme()
                                                            .primary,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Informations bancaires',
                                                      style: TextStyle(
                                                        fontSize:
                                                            UniquesControllers()
                                                                    .data
                                                                    .baseSpace *
                                                                2,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const CustomSpace(
                                                    heightMultiplier: 3),
                                                CustomTextFormField(
                                                  tag: 'holder-text-form-field',
                                                  controller:
                                                      cc.holderController,
                                                  labelText:
                                                      'Titulaire du compte',
                                                  iconData:
                                                      Icons.person_outline,
                                                ),
                                                const CustomSpace(
                                                    heightMultiplier: 2),
                                                CustomTextFormField(
                                                  tag: 'iban-text-form-field',
                                                  controller: cc.ibanController,
                                                  labelText: 'IBAN',
                                                  iconData: Icons
                                                      .credit_card_outlined,
                                                ),
                                                const CustomSpace(
                                                    heightMultiplier: 2),
                                                CustomTextFormField(
                                                  tag: 'bic-text-form-field',
                                                  controller: cc.bicController,
                                                  labelText: 'BIC',
                                                  iconData:
                                                      Icons.business_outlined,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const CustomSpace(heightMultiplier: 3),
                                // Bouton Supprimer le compte stylisé
                                CustomCardAnimation(
                                  index: 4,
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => cc.openAlertDialog(
                                            'Supprimer le compte',
                                            confirmText: 'Supprimer',
                                            confirmColor: Colors.red,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  3,
                                              vertical: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  1.8,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'SUPPRIMER LE COMPTE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
