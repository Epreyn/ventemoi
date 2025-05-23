import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:ventemoi/firebase_options.dart';

import '../../../core/classes/unique_controllers.dart';

import '../../../features/custom_card_animation/view/custom_card_animation.dart';
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

    return ScreenLayout(
      fabOnPressed: cc.updateProfile,
      fabIcon: const Icon(Icons.save),
      fabText: const Text('Enregistrer les modifications'),
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
                            maxWidth: UniquesControllers().data.baseMaxWidth,
                          ),
                          child: Form(
                            key: cc.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Image / photo de profil
                                CustomCardAnimation(
                                  index: 0,
                                  child: CustomProfileImagePicker(
                                    tag: UniqueKey().toString(),
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomCardAnimation(
                                  index: 1,
                                  child: SizedBox(
                                    width:
                                        UniquesControllers().data.baseMaxWidth,
                                    child: Text(
                                      'Photo de profil',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                      ),
                                    ),
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 2),

                                // Nom
                                CustomCardAnimation(
                                  index: 2,
                                  child: CustomTextFormField(
                                    tag: 'name-text-form-field',
                                    controller: cc.nameController,
                                    labelText: 'Nom',
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                CustomCardAnimation(
                                  index: 3,
                                  child: CustomTextFormField(
                                    tag: 'email-text-form-field',
                                    enabled: false,
                                    controller: cc.emailController,
                                    labelText: 'Email',
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                if (userType == 'Particulier') ...[
                                  CustomCardAnimation(
                                    index: 4,
                                    child: GooglePlaceAutoCompleteTextField(
                                      textEditingController:
                                          cc.personalAddressController,
                                      language: 'fr',
                                      googleAPIKey:
                                          DefaultFirebaseOptions.googleKeyAPI,
                                      inputDecoration: InputDecoration(
                                        hintText: "Entrez une adresse...",
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.search),
                                      ),
                                      debounceTime:
                                          800, // Temps de latence (ms) avant la requête (pour éviter trop d'appels)
                                      countries: [
                                        'fr'
                                      ], // Limite la recherche aux adresses en France [oai_citation:6‡tuto-flutter.fr](https://tuto-flutter.fr/coder-avec-flutter/google-maps/barre-de-recherche#:~:text=%2A%20%60countries%3A%20%5B,son%20ID%20et%20sa%20description)
                                      placeType: PlaceType
                                          .geocode, // Filtre pour ne rechercher que des adresses (géocodes)
                                      isLatLngRequired:
                                          true, // Demande au plugin de récupérer lat & lng pour chaque résultat [oai_citation:7‡tuto-flutter.fr](https://tuto-flutter.fr/coder-avec-flutter/google-maps/barre-de-recherche#:~:text=%2A%20%60countries%3A%20%5B,son%20ID%20et%20sa%20description)
                                      getPlaceDetailWithLatLng: (prediction) {
                                        // Ces champs peuvent être des String
                                        final latString = prediction.lat ?? '0';
                                        final lngString = prediction.lng ?? '0';

                                        // On parse en double
                                        final lat =
                                            double.tryParse(latString) ?? 0.0;
                                        final lng =
                                            double.tryParse(lngString) ?? 0.0;

                                        cc.personalLat.value = lat;
                                        cc.personalLng.value = lng;
                                      },
                                      itemClick: (prediction) {
                                        // Ce callback est appelé au moment du clic sur une suggestion
                                        cc.personalAddressController.text =
                                            prediction.description ?? '';
                                        cc.personalAddressController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: cc
                                                  .personalAddressController
                                                  .text
                                                  .length),
                                        );
                                        // Une fois l'adresse insérée dans le champ, le getPlaceDetailWithLatLng est aussi déclenché si isLatLngRequired=true
                                      },
                                    ),
                                    // child: CustomTextFormField(
                                    //   tag: 'personal-address-field',
                                    //   controller: cc.personalAddressController,
                                    //   labelText: 'Adresse Personnelle',
                                    //   maxLines: 3,
                                    // ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                ],
                                if (userType == 'Boutique') ...[
                                  CustomCardAnimation(
                                    index: 4,
                                    child: CustomTextFormField(
                                      tag: 'coupons-text-form-field',
                                      controller: cc.couponsController,
                                      labelText:
                                          'Nombre de bons (Valeur totale: ${(int.tryParse(cc.couponsController.text) ?? 0) * 50}€)',
                                      keyboardType: TextInputType.number,
                                      enabled: false,
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 5,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: cc.buyCoupons,
                                        icon: const Icon(
                                            Icons.add_shopping_cart_outlined),
                                        label: const Text('Acheter des bons'),
                                      ),
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 4),
                                  // Infos bancaires
                                  CustomCardAnimation(
                                    index: 6,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Informations bancaires',
                                        style: TextStyle(
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              1.8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 7,
                                    child: CustomTextFormField(
                                      tag: 'holder-text-form-field',
                                      controller: cc.holderController,
                                      labelText: 'Titulaire du compte',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 8,
                                    child: CustomTextFormField(
                                      tag: 'iban-text-form-field',
                                      controller: cc.ibanController,
                                      labelText: 'IBAN',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 9,
                                    child: CustomTextFormField(
                                      tag: 'bic-text-form-field',
                                      controller: cc.bicController,
                                      labelText: 'BIC',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                ],
                                if (userType == 'Entreprise') ...[
                                  CustomCardAnimation(
                                    index: 4,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Informations bancaires',
                                        style: TextStyle(
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              1.8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 5,
                                    child: CustomTextFormField(
                                      tag: 'holder-text-form-field',
                                      controller: cc.holderController,
                                      labelText: 'Titulaire du compte',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 6,
                                    child: CustomTextFormField(
                                      tag: 'iban-text-form-field',
                                      controller: cc.ibanController,
                                      labelText: 'IBAN',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  CustomCardAnimation(
                                    index: 7,
                                    child: CustomTextFormField(
                                      tag: 'bic-text-form-field',
                                      controller: cc.bicController,
                                      labelText: 'BIC',
                                    ),
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                ],
                                CustomCardAnimation(
                                  index: UniquesControllers()
                                          .data
                                          .dynamicIconList
                                          .length +
                                      1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => cc.openAlertDialog(
                                        'Supprimer le compte',
                                        confirmText: 'Supprimer',
                                        confirmColor: Colors.red,
                                      ),
                                      icon: const Icon(Icons.delete_forever,
                                          color: Colors.red),
                                      label: const Text(
                                        'Supprimer le compte',
                                        style: TextStyle(color: Colors.red),
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
