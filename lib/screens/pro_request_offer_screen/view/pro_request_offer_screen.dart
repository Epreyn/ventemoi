import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../controllers/pro_request_offer_controller.dart';

class ProRequestOfferScreen extends StatelessWidget {
  const ProRequestOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProRequestOfferController());
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header avec flèche retour
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'Demande d\'offre publicitaire',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Contenu
            Expanded(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'information
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Formulaire de demande
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle demande d\'offre',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CustomTheme.lightScheme().primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informations de contact
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              tag: 'establishment-name',
                              controller: controller.establishmentNameCtrl,
                              labelText: 'Nom de l\'établissement *',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nom requis';
                                }
                                return null;
                              },
                              iconData: Icons.business,
                            ),
                          ),
                          if (isTablet) const SizedBox(width: 16),
                          if (isTablet)
                            Expanded(
                              child: CustomTextFormField(
                                tag: 'contact-phone',
                                controller: controller.contactPhoneCtrl,
                                labelText: 'Téléphone de contact *',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Téléphone requis';
                                  }
                                  return null;
                                },
                                iconData: Icons.phone,
                              ),
                            ),
                        ],
                      ),
                      if (!isTablet) const SizedBox(height: 16),
                      if (!isTablet)
                        CustomTextFormField(
                          tag: 'contact-phone',
                          controller: controller.contactPhoneCtrl,
                          labelText: 'Téléphone de contact *',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Téléphone requis';
                            }
                            return null;
                          },
                          iconData: Icons.phone,
                        ),
                      const SizedBox(height: 16),

                      // Titre et description
                      CustomTextFormField(
                        tag: 'offer-title',
                        controller: controller.titleCtrl,
                        labelText: 'Titre de l\'offre *',
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
                        controller: controller.descriptionCtrl,
                        labelText: 'Description de l\'offre *',
                        minLines: 3,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description requise';
                          }
                          return null;
                        },
                        iconData: Icons.description,
                      ),
                      const SizedBox(height: 16),

                      // URL de l'image
                      CustomTextFormField(
                        tag: 'offer-image',
                        controller: controller.imageUrlCtrl,
                        labelText: 'URL de l\'image (optionnel)',
                        keyboardType: TextInputType.url,
                        iconData: Icons.image,
                      ),
                      const SizedBox(height: 8),

                      // Info sur les images
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Format recommandé: 800x400px, JPG ou PNG',
                                style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lien et bouton
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              tag: 'offer-link',
                              controller: controller.linkUrlCtrl,
                              labelText: 'Lien de l\'offre',
                              keyboardType: TextInputType.url,
                              iconData: Icons.link,
                            ),
                          ),
                          if (isTablet) const SizedBox(width: 16),
                          if (isTablet)
                            Expanded(
                              child: CustomTextFormField(
                                tag: 'button-text',
                                controller: controller.buttonTextCtrl,
                                labelText: 'Texte du bouton',
                                iconData: Icons.smart_button,
                              ),
                            ),
                        ],
                      ),
                      if (!isTablet) const SizedBox(height: 16),
                      if (!isTablet)
                        CustomTextFormField(
                          tag: 'button-text',
                          controller: controller.buttonTextCtrl,
                          labelText: 'Texte du bouton',
                          iconData: Icons.smart_button,
                        ),
                      const SizedBox(height: 20),

                      // Dates
                      Text(
                        'Période de diffusion souhaitée',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => InkWell(
                              onTap: () => _selectDate(context, controller, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date de début',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  controller.startDate.value != null
                                      ? DateFormat('dd/MM/yyyy').format(controller.startDate.value!)
                                      : 'Sélectionner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: controller.startDate.value != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(() => InkWell(
                              onTap: () => _selectDate(context, controller, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date de fin',
                                  prefixIcon: Icon(Icons.event),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  controller.endDate.value != null
                                      ? DateFormat('dd/MM/yyyy').format(controller.endDate.value!)
                                      : 'Sélectionner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: controller.endDate.value != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Prévisualisation
                      _buildPreviewSection(controller),
                      const SizedBox(height: 24),

                      // Bouton soumettre
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Obx(() => ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.submitOfferRequest(),
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white),
                          label: Text(
                            controller.isLoading.value ? 'Envoi...' : 'Soumettre la demande',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomTheme.lightScheme().primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Liste des demandes en attente
            _buildPendingRequests(controller),
            const SizedBox(height: 24),

            // Liste des offres approuvées
            _buildApprovedOffers(controller),
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign, size: 40, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres publicitaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Soumettez votre offre pour apparaître dans la section "Offres du moment". Notre équipe validera votre demande sous 24-48h.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ProRequestOfferController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, color: CustomTheme.lightScheme().primary),
            const SizedBox(width: 8),
            Text(
              'Prévisualisation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CustomTheme.lightScheme().primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              if (controller.imageUrlCtrl.text.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      controller.imageUrlCtrl.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('Image non disponible', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (controller.imageUrlCtrl.text.isNotEmpty) const SizedBox(height: 12),
              
              // Titre
              Text(
                controller.titleCtrl.text.isEmpty 
                    ? 'Titre de votre offre' 
                    : controller.titleCtrl.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: controller.titleCtrl.text.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                controller.descriptionCtrl.text.isEmpty
                    ? 'Description de votre offre...'
                    : controller.descriptionCtrl.text,
                style: TextStyle(
                  fontSize: 14,
                  color: controller.descriptionCtrl.text.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),
              
              // Bouton
              if (controller.linkUrlCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomTheme.lightScheme().primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    controller.buttonTextCtrl.text.isEmpty
                        ? 'En savoir plus'
                        : controller.buttonTextCtrl.text,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequests(ProRequestOfferController controller) {
    return Obx(() {
      if (controller.pendingRequests.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demandes en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...controller.pendingRequests.map((request) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.hourglass_empty, color: Colors.orange[700]),
                ),
                title: Text(request['title'] ?? ''),
                subtitle: Text(
                  'Soumis le ${_formatDate(request['created_at'])}',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => controller.cancelRequest(request['id']),
                ),
              ),
            );
          }).toList(),
        ],
      );
    });
  }

  Widget _buildApprovedOffers(ProRequestOfferController controller) {
    return Obx(() {
      if (controller.approvedOffers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offres approuvées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...controller.approvedOffers.map((offer) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.check_circle, color: Colors.green[700]),
                ),
                title: Text(offer['title'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approuvé le ${_formatDate(offer['approved_at'])}',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (offer['start_date'] != null)
                      Text(
                        'Diffusion: ${_formatDate(offer['start_date'])} - ${_formatDate(offer['end_date'])}',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      );
    });
  }

  Future<void> _selectDate(BuildContext context, ProRequestOfferController controller, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (controller.startDate.value ?? DateTime.now())
          : (controller.endDate.value ?? DateTime.now().add(Duration(days: 7))),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      if (isStartDate) {
        controller.startDate.value = picked;
      } else {
        controller.endDate.value = picked;
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }
    return '';
  }
}