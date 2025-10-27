import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

/// Popup détaillé d'un établissement avec Google Maps
class EstablishmentDetailPopup extends StatefulWidget {
  final Establishment establishment;
  final String userTypeName;
  final int availableCoupons;
  final VoidCallback? onBuy;
  final bool isOwnEstablishment;
  final List<String> categoryNames;

  const EstablishmentDetailPopup({
    Key? key,
    required this.establishment,
    required this.userTypeName,
    required this.availableCoupons,
    this.onBuy,
    required this.isOwnEstablishment,
    required this.categoryNames,
  }) : super(key: key);

  @override
  State<EstablishmentDetailPopup> createState() =>
      _EstablishmentDetailPopupState();
}

class _EstablishmentDetailPopupState extends State<EstablishmentDetailPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnterprise = widget.userTypeName == 'Entreprise';
    final isSponsor = widget.userTypeName == 'Sponsor';
    final isAssociation = widget.userTypeName == 'Association';
    final isBoutique =
        widget.userTypeName == 'Boutique' || widget.userTypeName == 'Commerçant';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header avec image et infos principales
            _buildHeader(isEnterprise, isSponsor, isAssociation),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: CustomTheme.lightScheme().primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: CustomTheme.lightScheme().primary,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Infos'),
                  Tab(icon: Icon(Icons.map_outlined), text: 'Localisation'),
                  Tab(icon: Icon(Icons.photo_library_outlined), text: 'Médias'),
                ],
              ),
            ),

            // Contenu des tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(isEnterprise, isBoutique, isSponsor),
                  _buildMapTab(),
                  _buildMediaTab(),
                ],
              ),
            ),

            // Footer avec actions
            _buildFooter(isEnterprise, isBoutique, isSponsor, isAssociation),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEnterprise, bool isSponsor, bool isAssociation) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.establishment.bannerUrl.isNotEmpty
              ? [Colors.transparent, Colors.black.withOpacity(0.5)]
              : [
                  CustomTheme.lightScheme().primary.withOpacity(0.1),
                  CustomTheme.lightScheme().primary.withOpacity(0.05),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
          if (widget.establishment.bannerUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Image.network(
                widget.establishment.bannerUrl,
                fit: BoxFit.cover,
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Container(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                child: Icon(
                  Icons.business,
                  size: 80,
                  color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                ),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
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

          // Bouton fermer
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          // Logo
          if (widget.establishment.logoUrl.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.establishment.logoUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Infos principales en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.establishment.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.availableCoupons > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CustomTheme.lightScheme().primary,
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.availableCoupons} bon${widget.availableCoupons > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.establishment.address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.establishment.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isEnterprise, bool isBoutique, bool isSponsor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories
          if (widget.categoryNames.isNotEmpty) ...[
            const Text(
              'Catégories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categoryNames
                  .map(
                    (name) => Chip(
                      label: Text(name),
                      backgroundColor:
                          CustomTheme.lightScheme().primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: CustomTheme.lightScheme().primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Description
          if (widget.establishment.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.establishment.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Coordonnées
          const Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.establishment.telephone.isNotEmpty)
            _buildInfoRow(
              Icons.phone,
              'Téléphone',
              widget.establishment.telephone,
              onTap: () => _launchPhone(widget.establishment.telephone),
            ),
          if (widget.establishment.email.isNotEmpty)
            _buildInfoRow(
              Icons.email,
              'Email',
              widget.establishment.email,
              onTap: () => _launchEmail(widget.establishment.email),
            ),
          if (widget.establishment.address.isNotEmpty)
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              widget.establishment.address,
              onTap: () => _launchMaps(widget.establishment.address),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CustomTheme.lightScheme().primary,
                size: 20,
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Container(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.map_outlined,
              size: 80,
              color: CustomTheme.lightScheme().primary,
            ),
          ),
          const SizedBox(height: 32),

          // Adresse
          Text(
            widget.establishment.address,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ouvrir dans Google Maps pour voir la localisation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _launchMaps(widget.establishment.address),
                icon: const Icon(Icons.map),
                label: const Text('Voir sur la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomTheme.lightScheme().primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _launchMaps(widget.establishment.address),
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    final hasVideo = widget.establishment.videoUrl.isNotEmpty;
    final hasImages = widget.establishment.bannerUrl.isNotEmpty ||
        widget.establishment.logoUrl.isNotEmpty;

    if (!hasVideo && !hasImages) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun média disponible',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVideo) ...[
            const Text(
              'Vidéo de présentation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchUrl(widget.establishment.videoUrl),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (widget.establishment.bannerUrl.isNotEmpty) ...[
            const Text(
              'Bannière',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.establishment.bannerUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
      bool isEnterprise, bool isBoutique, bool isSponsor, bool isAssociation) {
    return Container(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Contacts rapides
          if (widget.establishment.telephone.isNotEmpty)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launchPhone(widget.establishment.telephone),
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (widget.establishment.telephone.isNotEmpty &&
              (widget.establishment.email.isNotEmpty ||
                  (!isSponsor && !isAssociation && !widget.isOwnEstablishment)))
            const SizedBox(width: 12),
          if (widget.establishment.email.isNotEmpty)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launchEmail(widget.establishment.email),
                icon: const Icon(Icons.email),
                label: const Text('Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (widget.establishment.email.isNotEmpty &&
              !isSponsor &&
              !isAssociation &&
              !widget.isOwnEstablishment)
            const SizedBox(width: 12),

          // Action principale
          if (!isSponsor && !isAssociation && !widget.isOwnEstablishment)
            Expanded(
              flex: 2,
              child: isEnterprise
                  ? ElevatedButton.icon(
                      onPressed: _openQuoteDialog,
                      icon: const Icon(Icons.request_quote),
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
                      onPressed: widget.onBuy,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Acheter un bon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomTheme.lightScheme().primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
        ],
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
    Get.back(); // Fermer le popup d'abord
    final qc = Get.put(QuotesScreenController());
    Get.dialog(
      QuoteFormDialog(
        enterprise: widget.establishment,
        controller: qc,
      ),
      barrierDismissible: true,
    );
  }
}
