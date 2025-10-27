import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

/// Popup détaillé single-page scrollable (Best Practice 2025)
/// Toutes les infos sur une seule page avec scroll fluide
class EstablishmentDetailPopupV3 extends StatelessWidget {
  final Establishment establishment;
  final String userTypeName;
  final int availableCoupons;
  final VoidCallback? onBuy;
  final bool isOwnEstablishment;
  final List<String> categoryNames;

  const EstablishmentDetailPopupV3({
    Key? key,
    required this.establishment,
    required this.userTypeName,
    required this.availableCoupons,
    this.onBuy,
    required this.isOwnEstablishment,
    required this.categoryNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnterprise = userTypeName == 'Entreprise';
    final isSponsor = userTypeName == 'Sponsor';
    final isAssociation = userTypeName == 'Association';
    final isBoutique = userTypeName == 'Boutique' || userTypeName == 'Commerçant';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header fixe avec image
            _buildHeader(),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badges
                    _buildNameSection(isEnterprise, isSponsor, isAssociation),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Catégories
                    if (categoryNames.isNotEmpty) ...[
                      _buildSectionTitle('Catégories', Icons.category),
                      const SizedBox(height: 12),
                      _buildCategories(),
                      const SizedBox(height: 24),
                    ],

                    // Description
                    if (establishment.description.isNotEmpty) ...[
                      _buildSectionTitle('À propos', Icons.info_outline),
                      const SizedBox(height: 12),
                      Text(
                        establishment.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Coordonnées
                    _buildSectionTitle('Coordonnées', Icons.contact_phone),
                    const SizedBox(height: 16),
                    _buildContactInfo(),

                    const SizedBox(height: 24),

                    // Bons disponibles (si applicable)
                    if (availableCoupons > 0) ...[
                      _buildCouponsSection(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Footer fixe avec actions
            _buildFooter(isEnterprise, isBoutique, isSponsor, isAssociation),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Image de fond
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            height: 180,
            width: double.infinity,
            child: establishment.bannerUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        establishment.bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: CustomTheme.lightScheme()
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CustomTheme.lightScheme().primary.withOpacity(0.2),
                          CustomTheme.lightScheme().primary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.business,
                      size: 80,
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    ),
                  ),
          ),
        ),

        // Bouton fermer
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),

        // Logo
        if (establishment.logoUrl.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  establishment.logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.store,
                    color: CustomTheme.lightScheme().primary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameSection(
      bool isEnterprise, bool isSponsor, bool isAssociation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                establishment.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            if (availableCoupons > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CustomTheme.lightScheme().primary,
                      CustomTheme.lightScheme().primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '$availableCoupons bon${availableCoupons > 1 ? 's' : ''} disponible${availableCoupons > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTypeBadge(isEnterprise, isSponsor, isAssociation),
      ],
    );
  }

  Widget _buildTypeBadge(
      bool isEnterprise, bool isSponsor, bool isAssociation) {
    String label;
    IconData icon;
    Color color;

    if (isSponsor) {
      label = 'Sponsor';
      icon = Icons.workspace_premium;
      color = const Color(0xFFCD7F32);
    } else if (isAssociation) {
      label = 'Association';
      icon = Icons.volunteer_activism;
      color = Colors.green;
    } else if (isEnterprise) {
      label = 'Service professionnel';
      icon = Icons.business;
      color = Colors.blue;
    } else {
      label = 'Commerce';
      icon = Icons.store;
      color = CustomTheme.lightScheme().primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: CustomTheme.lightScheme().primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categoryNames
          .map(
            (name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildContactInfo() {
    final hasAnyContact = establishment.telephone.isNotEmpty ||
                          establishment.email.isNotEmpty ||
                          establishment.videoUrl.isNotEmpty ||
                          establishment.address.isNotEmpty;

    return Column(
      children: [
        if (establishment.address.isNotEmpty)
          _buildContactRow(
            Icons.location_on,
            'Adresse',
            establishment.address,
            () => _launchMaps(establishment.address),
          ),
        if (establishment.telephone.isNotEmpty) ...[
          if (establishment.address.isNotEmpty) const SizedBox(height: 12),
          _buildContactRow(
            Icons.phone,
            'Téléphone',
            establishment.telephone,
            () => _launchPhone(establishment.telephone),
          ),
        ],
        if (establishment.email.isNotEmpty) ...[
          if (establishment.telephone.isNotEmpty || establishment.address.isNotEmpty)
            const SizedBox(height: 12),
          _buildContactRow(
            Icons.email,
            'Email',
            establishment.email,
            () => _launchEmail(establishment.email),
          ),
        ],
        if (establishment.videoUrl.isNotEmpty) ...[
          if (establishment.telephone.isNotEmpty ||
              establishment.email.isNotEmpty ||
              establishment.address.isNotEmpty)
            const SizedBox(height: 12),
          _buildVideoRow(),
        ],
      ],
    );
  }

  Widget _buildContactRow(
      IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: CustomTheme.lightScheme().primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoRow() {
    return InkWell(
      onTap: () => _launchUrl(establishment.videoUrl),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: CustomTheme.lightScheme().primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vidéo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Voir la vidéo de présentation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomTheme.lightScheme().primary.withOpacity(0.05),
            CustomTheme.lightScheme().primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: CustomTheme.lightScheme().primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  establishment.address,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchMaps(establishment.address),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Voir sur Maps'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: CustomTheme.lightScheme().primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchMaps(establishment.address),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomTheme.lightScheme().primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (establishment.videoUrl.isNotEmpty) ...[
          InkWell(
            onTap: () => _launchUrl(establishment.videoUrl),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Voir la vidéo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (establishment.bannerUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              establishment.bannerUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }

  Widget _buildCouponsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomTheme.lightScheme().primary.withOpacity(0.1),
            CustomTheme.lightScheme().primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$availableCoupons bon${availableCoupons > 1 ? 's' : ''} cadeau disponible${availableCoupons > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profitez de nos offres exclusives',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
      bool isEnterprise, bool isBoutique, bool isSponsor, bool isAssociation) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: !isSponsor && !isAssociation && !isOwnEstablishment
          ? Row(
              children: [
                Expanded(
                  child: isEnterprise
                      ? ElevatedButton.icon(
                          onPressed: _openQuoteDialog,
                          icon: const Icon(Icons.request_quote, size: 20),
                          label: const Text('Demander un devis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onBuy,
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: const Text('Acheter un bon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CustomTheme.lightScheme().primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ],
            )
          : Center(
              child: TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
                label: const Text('Fermer'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openQuoteDialog() {
    Get.back(); // Fermer le popup
    final qc = Get.put(QuotesScreenController());
    Get.dialog(
      QuoteFormDialog(
        enterprise: establishment,
        controller: qc,
      ),
      barrierDismissible: true,
    );
  }
}
