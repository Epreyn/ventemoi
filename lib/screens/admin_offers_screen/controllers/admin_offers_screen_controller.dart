// lib/screens/admin_offers_screen/controllers/admin_offers_screen_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ventemoi/core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/special_offer.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class AdminOffersScreenController extends GetxController with ControllerMixin {
  static const tag = 'admin-offers-screen';

  // Observables
  final allOffers = <SpecialOffer>[].obs;
  final isLoading = false.obs;

  // Form controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  final linkUrlCtrl = TextEditingController();
  final buttonTextCtrl = TextEditingController();
  final backgroundColorCtrl = TextEditingController();
  final textColorCtrl = TextEditingController();
  
  // Form observables
  final isActive = true.obs;
  final priority = 0.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Edition
  String? editingOfferId;

  StreamSubscription<List<SpecialOffer>>? _offersSub;

  @override
  void onInit() {
    super.onInit();
    _loadOffers();
  }

  @override
  void onClose() {
    _offersSub?.cancel();
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    imageUrlCtrl.dispose();
    linkUrlCtrl.dispose();
    buttonTextCtrl.dispose();
    backgroundColorCtrl.dispose();
    textColorCtrl.dispose();
    super.onClose();
  }

  void _loadOffers() {
    _offersSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('special_offers')
        .orderBy('priority', descending: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SpecialOffer.fromDocument(d)).toList())
        .listen((offers) {
          allOffers.value = offers;
        });
  }

  void openCreateOfferBottomSheet() {
    editingOfferId = null;
    variablesToResetToBottomSheet();
    openBottomSheet(
      'Créer une nouvelle offre',
      hasAction: false,
    );
  }

  void openEditOfferBottomSheet(SpecialOffer offer) {
    editingOfferId = offer.id;
    // D'abord on ouvre le bottomSheet
    openBottomSheet(
      'Modifier l\'offre',
      hasAction: false,
    );
    // Ensuite on charge les données après un délai pour s'assurer que le bottomSheet est prêt
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadOfferData(offer);
    });
  }

  void _loadOfferData(SpecialOffer offer) {
    titleCtrl.text = offer.title;
    descriptionCtrl.text = offer.description;
    imageUrlCtrl.text = offer.imageUrl ?? '';
    linkUrlCtrl.text = offer.linkUrl ?? '';
    buttonTextCtrl.text = offer.buttonText ?? '';
    backgroundColorCtrl.text = offer.backgroundColor ?? '#FFF3CD';
    textColorCtrl.text = offer.textColor ?? '#856404';
    isActive.value = offer.isActive;
    priority.value = offer.priority;
    startDate.value = offer.startDate;
    endDate.value = offer.endDate;
  }

  @override
  void variablesToResetToBottomSheet() {
    // Ne réinitialiser que si on n'est pas en mode édition
    if (editingOfferId == null) {
      formKey.currentState?.reset();
      titleCtrl.clear();
      descriptionCtrl.clear();
      imageUrlCtrl.clear();
      linkUrlCtrl.clear();
      buttonTextCtrl.clear();
      backgroundColorCtrl.text = '#FFF3CD';
      textColorCtrl.text = '#856404';
      isActive.value = true;
      priority.value = 0;
      startDate.value = null;
      endDate.value = null;
    }
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      Form(
        key: formKey,
        child: Column(
          children: [
            CustomTextFormField(
              tag: 'offer-title',
              controller: titleCtrl,
              labelText: 'Titre de l\'offre *',
              errorText: 'Titre requis',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Titre requis';
                }
                return null;
              },
              iconData: Icons.title,
            ),
            const SizedBox(height: 16),
            
            CustomTextFormField(
              tag: 'offer-description',
              controller: descriptionCtrl,
              labelText: 'Description *',
              errorText: 'Description requise',
              minLines: 2,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description requise';
                }
                return null;
              },
              iconData: Icons.description,
            ),
            const SizedBox(height: 16),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFormField(
                  tag: 'offer-image-url',
                  controller: imageUrlCtrl,
                  labelText: 'URL de l\'image (optionnel)',
                  keyboardType: TextInputType.url,
                  iconData: Icons.image,
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 40, right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Conseils pour les images',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Formats supportés : JPG, PNG, WebP\n'
                        '• Utilisez Firebase Storage ou Cloudinary\n'
                        '• Évitez WordPress (problèmes CORS)\n'
                        '• Exemple: https://picsum.photos/800/400',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bouton de test avec une image exemple
                      TextButton.icon(
                        onPressed: () {
                          imageUrlCtrl.text = 'https://picsum.photos/800/400';
                        },
                        icon: Icon(Icons.auto_fix_high, size: 16),
                        label: Text('Utiliser une image test'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    tag: 'offer-link-url',
                    controller: linkUrlCtrl,
                    labelText: 'URL du lien',
                    keyboardType: TextInputType.url,
                    iconData: Icons.link,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    tag: 'offer-button-text',
                    controller: buttonTextCtrl,
                    labelText: 'Texte du bouton',
                    iconData: Icons.smart_button,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => showColorPicker(true),
                    child: AbsorbPointer(
                      child: CustomTextFormField(
                        tag: 'offer-bg-color',
                        controller: backgroundColorCtrl,
                        labelText: 'Couleur de fond',
                        iconData: Icons.color_lens,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => showColorPicker(false),
                    child: AbsorbPointer(
                      child: CustomTextFormField(
                        tag: 'offer-text-color',
                        controller: textColorCtrl,
                        labelText: 'Couleur du texte',
                        iconData: Icons.format_color_text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Priorité
            Obx(() => Row(
              children: [
                Icon(Icons.low_priority, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text('Priorité: '),
                const SizedBox(width: 8),
                Slider(
                  value: priority.value.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: priority.value.toString(),
                  onChanged: (value) {
                    priority.value = value.toInt();
                  },
                ),
                Text('${priority.value}'),
              ],
            )),
            const SizedBox(height: 16),
            
            // Switch Actif
            Obx(() => SwitchListTile(
              title: const Text('Offre active'),
              subtitle: Text(
                isActive.value ? 'L\'offre sera visible' : 'L\'offre sera cachée'
              ),
              value: isActive.value,
              onChanged: (value) {
                isActive.value = value;
              },
              secondary: Icon(
                isActive.value ? Icons.visibility : Icons.visibility_off,
                color: isActive.value ? Colors.green : Colors.grey,
              ),
            )),
            const SizedBox(height: 16),
            
            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période de validité (optionnel)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Obx(() => ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Date de début'),
                      subtitle: Text(
                        startDate.value != null
                            ? formatDateFr(startDate.value!)
                            : 'Non définie'
                      ),
                      trailing: startDate.value != null
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () => startDate.value = null,
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: Get.context!,
                          locale: const Locale('fr', 'FR'),
                          initialDate: startDate.value ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.orange,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          startDate.value = date;
                        }
                      },
                    )),
                    
                    Obx(() => ListTile(
                      leading: Icon(Icons.event),
                      title: Text('Date de fin'),
                      subtitle: Text(
                        endDate.value != null
                            ? formatDateFr(endDate.value!)
                            : 'Non définie'
                      ),
                      trailing: endDate.value != null
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () => endDate.value = null,
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: Get.context!,
                          locale: const Locale('fr', 'FR'),
                          initialDate: endDate.value ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.orange,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          endDate.value = date;
                        }
                      },
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => actionBottomSheet(),
                    icon: Icon(
                      editingOfferId != null ? Icons.save : Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      editingOfferId != null ? 'Modifier' : 'Créer',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    if (!formKey.currentState!.validate()) return;

    // Fermer la modale d'abord pour éviter qu'elle reste ouverte
    Get.back();
    
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      final offerData = {
        'title': titleCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'image_url': imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim(),
        'link_url': linkUrlCtrl.text.trim().isEmpty ? null : linkUrlCtrl.text.trim(),
        'button_text': buttonTextCtrl.text.trim().isEmpty ? 'En savoir plus' : buttonTextCtrl.text.trim(),
        'background_color': backgroundColorCtrl.text.trim().isEmpty ? '#FFF3CD' : backgroundColorCtrl.text.trim(),
        'text_color': textColorCtrl.text.trim().isEmpty ? '#856404' : textColorCtrl.text.trim(),
        'is_active': isActive.value,
        'priority': priority.value,
        'start_date': startDate.value != null ? Timestamp.fromDate(startDate.value!) : null,
        'end_date': endDate.value != null ? Timestamp.fromDate(endDate.value!) : null,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (editingOfferId != null) {
        // Mise à jour
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('special_offers')
            .doc(editingOfferId)
            .update(offerData);
        
        UniquesControllers().data.snackbar(
          'Succès',
          'L\'offre a été mise à jour',
          false,
        );
      } else {
        // Création
        offerData['created_at'] = FieldValue.serverTimestamp();
        
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('special_offers')
            .add(offerData);
        
        UniquesControllers().data.snackbar(
          'Succès',
          'L\'offre a été créée',
          false,
        );
      }
      
      // Réinitialiser le formulaire après la sauvegarde
      editingOfferId = null;
      titleCtrl.clear();
      descriptionCtrl.clear();
      imageUrlCtrl.clear();
      linkUrlCtrl.clear();
      buttonTextCtrl.clear();
      backgroundColorCtrl.text = '#FFF3CD';
      textColorCtrl.text = '#856404';
      isActive.value = true;
      priority.value = 0;
      startDate.value = null;
      endDate.value = null;
      
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        e.toString(),
        true,
      );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette offre ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('special_offers')
            .doc(offerId)
            .delete();

        UniquesControllers().data.snackbar(
          'Succès',
          'L\'offre a été supprimée',
          false,
        );
      } catch (e) {
        UniquesControllers().data.snackbar(
          'Erreur',
          e.toString(),
          true,
        );
      }
    }
  }

  Future<void> toggleOfferStatus(String offerId, bool newStatus) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('special_offers')
          .doc(offerId)
          .update({
        'is_active': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      UniquesControllers().data.snackbar(
        'Succès',
        newStatus ? 'Offre activée' : 'Offre désactivée',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        e.toString(),
        true,
      );
    }
  }

  // Prévisualisation du bandeau
  Color parseHexColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('0xFF$hexColor'));
      }
    } catch (e) {}
    return Colors.amber[100]!;
  }

  // Format de date en français
  String formatDateFr(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }

  // Sélecteur de couleur
  void showColorPicker(bool isBackgroundColor) {
    Color currentColor = isBackgroundColor 
        ? parseHexColor(backgroundColorCtrl.text)
        : parseHexColor(textColorCtrl.text);

    Get.dialog(
      AlertDialog(
        title: Text(isBackgroundColor ? 'Couleur de fond' : 'Couleur du texte'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (Color color) {
              String hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              if (isBackgroundColor) {
                backgroundColorCtrl.text = hexColor;
              } else {
                textColorCtrl.text = hexColor;
              }
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}