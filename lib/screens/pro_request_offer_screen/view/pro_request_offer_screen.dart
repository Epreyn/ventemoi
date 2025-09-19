import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_animation/view/custom_animation.dart';
import '../controllers/pro_request_offer_controller.dart';
import '../widgets/simple_image_uploader_widget.dart';

class ProRequestOfferScreen extends StatelessWidget {
  const ProRequestOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProRequestOfferController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final isMobile = screenWidth <= 600;

    return ScreenLayout(
      appBar: CustomAppBar(
        title: Text(
          'Demande d\'offre publicitaire',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      noFAB: true,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            padding: EdgeInsets.all(
              isMobile ? 16 : isTablet ? 24 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte d'information avec animation
                CustomAnimation(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 100),
                  xStartPosition: -30,
                  isOpacity: true,
                  child: _buildModernInfoCard(),
                ),
                const SizedBox(height: 32),

                // Layout responsive pour le formulaire
                isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Formulaire principal à gauche
                        Expanded(
                          flex: 2,
                          child: _buildMainForm(controller, isDesktop, isTablet),
                        ),
                        const SizedBox(width: 32),
                        // Prévisualisation à droite sur desktop
                        Expanded(
                          child: Column(
                            children: [
                              _buildLivePreview(controller),
                              const SizedBox(height: 24),
                              _buildSubmitSection(controller),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMainForm(controller, isDesktop, isTablet),
                        const SizedBox(height: 32),
                        _buildLivePreview(controller),
                        const SizedBox(height: 24),
                        _buildSubmitSection(controller),
                      ],
                    ),

                const SizedBox(height: 48),

                // Section des demandes et offres
                CustomAnimation(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 400),
                  yStartPosition: 30,
                  isOpacity: true,
                  child: _buildRequestsAndOffersSection(controller, isDesktop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomTheme.lightScheme().primary.withOpacity(0.1),
            CustomTheme.lightScheme().primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Pattern de fond
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CustomTheme.lightScheme().primary.withOpacity(0.05),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offres publicitaires Premium',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CustomTheme.lightScheme().primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Augmentez votre visibilité avec une offre dans la section "Offres du moment". Validation sous 24-48h.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
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

  Widget _buildMainForm(ProRequestOfferController controller, bool isDesktop, bool isTablet) {
    return CustomAnimation(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      yStartPosition: 30,
      isOpacity: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de section
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: CustomTheme.lightScheme().primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Informations de l\'offre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Champs du formulaire avec layout responsive
              _buildFormSection(
                title: 'Contact',
                icon: Icons.contact_phone_rounded,
                children: [
                  if (isDesktop || isTablet)
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: controller.establishmentNameCtrl,
                            label: 'Nom de l\'établissement',
                            icon: Icons.business_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            controller: controller.contactPhoneCtrl,
                            label: 'Téléphone',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Téléphone requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildModernTextField(
                      controller: controller.establishmentNameCtrl,
                      label: 'Nom de l\'établissement',
                      icon: Icons.business_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nom requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: controller.contactPhoneCtrl,
                      label: 'Téléphone',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Téléphone requis';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              _buildFormSection(
                title: 'Contenu de l\'offre',
                icon: Icons.article_rounded,
                children: [
                  _buildModernTextField(
                    controller: controller.titleCtrl,
                    label: 'Titre de l\'offre',
                    icon: Icons.title_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Titre requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: controller.descriptionCtrl,
                    label: 'Description détaillée',
                    icon: Icons.description_rounded,
                    minLines: 4,
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description requise';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildFormSection(
                title: 'Médias et liens',
                icon: Icons.link_rounded,
                children: [
                  // Choix entre URL ou création de bannière
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomTheme.lightScheme().primary.withOpacity(0.05),
                          CustomTheme.lightScheme().primary.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: CustomTheme.lightScheme().primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Téléversez une image pour votre offre',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showImageUploader(controller),
                                icon: Icon(Icons.add_photo_alternate_rounded,
                                  size: 18,
                                  color: Colors.orange.shade600,
                                ),
                                label: Text(
                                  'Téléverser une image',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: Colors.orange.shade600,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OU',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: controller.imageUrlCtrl,
                          label: 'URL de l\'image existante',
                          icon: Icons.link_rounded,
                          keyboardType: TextInputType.url,
                          helperText: 'Utilisez une image existante',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isDesktop || isTablet)
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: controller.linkUrlCtrl,
                            label: 'Lien de l\'offre',
                            icon: Icons.link_rounded,
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            controller: controller.buttonTextCtrl,
                            label: 'Texte du bouton',
                            icon: Icons.smart_button_rounded,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildModernTextField(
                      controller: controller.linkUrlCtrl,
                      label: 'Lien de l\'offre',
                      icon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: controller.buttonTextCtrl,
                      label: 'Texte du bouton',
                      icon: Icons.smart_button_rounded,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              _buildFormSection(
                title: 'Période de diffusion',
                icon: Icons.calendar_month_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          context: Get.context!,
                          controller: controller,
                          isStartDate: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          context: Get.context!,
                          controller: controller,
                          isStartDate: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: CustomTheme.lightScheme().primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CustomTheme.lightScheme().primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required ProRequestOfferController controller,
    required bool isStartDate,
  }) {
    return Obx(() => InkWell(
      onTap: () => _selectDate(context, controller, isStartDate),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              isStartDate ? Icons.calendar_today_rounded : Icons.event_rounded,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStartDate ? 'Date de début' : 'Date de fin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isStartDate
                        ? (controller.startDate.value != null
                            ? DateFormat('dd/MM/yyyy').format(controller.startDate.value!)
                            : 'Sélectionner')
                        : (controller.endDate.value != null
                            ? DateFormat('dd/MM/yyyy').format(controller.endDate.value!)
                            : 'Sélectionner'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: (isStartDate ? controller.startDate.value : controller.endDate.value) != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLivePreview(ProRequestOfferController controller) {
    return CustomAnimation(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      yStartPosition: 30,
      isOpacity: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber[50]!, Colors.orange[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber[200]!,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    size: 20,
                    color: Colors.amber[800],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Prévisualisation en temps réel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contenu de la preview
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.imageUrlCtrl,
                    builder: (context, value, child) {
                    if (value.text.isNotEmpty) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            value.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image non disponible',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                          style: BorderStyle.none,
                        ),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune image',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },),
                  const SizedBox(height: 16),

                  // Titre
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.titleCtrl,
                    builder: (context, value, child) => Text(
                      value.text.isEmpty
                          ? 'Titre de votre offre'
                          : value.text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: value.text.isEmpty
                            ? Colors.grey[400]
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.descriptionCtrl,
                    builder: (context, value, child) => Text(
                      value.text.isEmpty
                          ? 'La description de votre offre apparaîtra ici...'
                          : value.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: value.text.isEmpty
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                    ),
                  ),

                  // Bouton CTA
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.linkUrlCtrl,
                    builder: (context, linkValue, child) {
                      if (linkValue.text.isNotEmpty) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller.buttonTextCtrl,
                          builder: (context, buttonValue, child) => Column(
                            children: [
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CustomTheme.lightScheme().primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    buttonValue.text.isEmpty
                                        ? 'En savoir plus'
                                        : buttonValue.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitSection(ProRequestOfferController controller) {
    return CustomAnimation(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      yStartPosition: 30,
      isOpacity: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Prêt à publier ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre offre avant de soumettre',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.submitOfferRequest(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomTheme.lightScheme().primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: controller.isLoading.value ? 0 : 3,
                ),
                child: controller.isLoading.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Envoi en cours...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Soumettre la demande',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsAndOffersSection(ProRequestOfferController controller, bool isDesktop) {
    return Column(
      children: [
        // Demandes en attente
        Obx(() {
          if (controller.pendingRequests.isEmpty) return const SizedBox.shrink();

          return _buildSection(
            title: 'Demandes en attente',
            icon: Icons.hourglass_empty_rounded,
            color: Colors.orange,
            items: controller.pendingRequests,
            itemBuilder: (request) => _buildRequestCard(
              request: request,
              controller: controller,
              isPending: true,
            ),
          );
        }),

        const SizedBox(height: 32),

        // Offres approuvées
        Obx(() {
          if (controller.approvedOffers.isEmpty) return const SizedBox.shrink();

          return _buildSection(
            title: 'Offres approuvées',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            items: controller.approvedOffers,
            itemBuilder: (offer) => _buildRequestCard(
              request: offer,
              controller: controller,
              isPending: false,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required Widget Function(dynamic) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map(itemBuilder).toList(),
      ],
    );
  }

  Widget _buildRequestCard({
    required dynamic request,
    required ProRequestOfferController controller,
    required bool isPending,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPending ? Icons.schedule_rounded : Icons.verified_rounded,
                    color: isPending ? Colors.orange[700] : Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPending
                            ? 'Soumis le ${_formatDate(request['created_at'])}'
                            : 'Approuvé le ${_formatDate(request['approved_at'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (!isPending && request['start_date'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatDate(request['start_date'])} - ${_formatDate(request['end_date'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isPending)
                  IconButton(
                    onPressed: () => controller.cancelRequest(request['id']),
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.red[400],
                    ),
                    tooltip: 'Annuler la demande',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    ProRequestOfferController controller,
    bool isStartDate
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (controller.startDate.value ?? DateTime.now())
          : (controller.endDate.value ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('fr', 'FR'),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: CustomTheme.lightScheme().primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
      },
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

  void _showImageUploader(ProRequestOfferController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SimpleImageUploaderWidget(
            onImageUploaded: (imageUrl) {
              controller.imageUrlCtrl.text = imageUrl;
              Get.back();
            },
            onCancel: () => Get.back(),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}