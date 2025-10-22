import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';

// Version 6: Ajout des boutons de contact
class ProgressiveEstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final VoidCallback? onBuy;
  final int index;
  final bool isOwnEstablishment;
  final String? userTypeName; // Pour déterminer l'icône
  final Map<String, String>? enterpriseCategoriesMap;
  final Map<String, String>? categoriesMap; // Pour boutiques/associations

  const ProgressiveEstablishmentCard({
    super.key,
    required this.establishment,
    this.onBuy,
    required this.index,
    this.isOwnEstablishment = false,
    this.userTypeName,
    this.enterpriseCategoriesMap,
    this.categoriesMap,
  });

  @override
  State<ProgressiveEstablishmentCard> createState() => _ProgressiveEstablishmentCardState();
}

class _ProgressiveEstablishmentCardState extends State<ProgressiveEstablishmentCard> {
  bool _isDescriptionExpanded = false;

  // Méthodes pour les boutons de contact (V6)
  Future<void> _launchUrl(String url) async {
    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    final establishment = widget.establishment;
    final isOwnEstablishment = widget.isOwnEstablishment;
    final userTypeName = widget.userTypeName;
    final enterpriseCategoriesMap = widget.enterpriseCategoriesMap;
    final categoriesMap = widget.categoriesMap;
    final onBuy = widget.onBuy;
    final isEnterprise = userTypeName == 'Entreprise';
    final isAssociation = userTypeName == 'Association';
    final isBoutique = userTypeName == 'Boutique' || userTypeName == 'Commerçant';
    final isSponsor = userTypeName == 'Sponsor';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOwnEstablishment
            ? BorderSide(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER avec logo et nom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo simple
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    border: Border.all(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isEnterprise
                        ? Icons.business
                        : isAssociation
                            ? Icons.volunteer_activism
                            : isSponsor
                                ? Icons.workspace_premium
                                : Icons.store,
                    size: 24,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Nom et badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              establishment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge "Vous"
                          if (isOwnEstablishment)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Vous',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CustomTheme.lightScheme().primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge cashback pour entreprises
                if (isEnterprise && establishment.cashbackPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.savings,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${establishment.cashbackPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // CATEGORIES SIMPLES (sans scroll)
            if (isEnterprise &&
                establishment.enterpriseCategoryIds != null &&
                establishment.enterpriseCategoryIds!.isNotEmpty &&
                enterpriseCategoriesMap != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  children: establishment.enterpriseCategoryIds!.map((catId) {
                    final categoryName = enterpriseCategoriesMap![catId] ?? catId;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomTheme.lightScheme().primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else if (!isEnterprise && establishment.categoryId.isNotEmpty && categoriesMap != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  categoriesMap![establishment.categoryId] ?? establishment.categoryId,
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomTheme.lightScheme().primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // IMAGE DE BANNIERE (V4)
            if (establishment.bannerUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: establishment.bannerUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

            // DESCRIPTION AVEC "VOIR PLUS" (V5)
            if (establishment.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    establishment.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: _isDescriptionExpanded ? null : 3,
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (establishment.description.length > 150)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _isDescriptionExpanded ? 'Voir moins' : 'Voir plus',
                          style: TextStyle(
                            fontSize: 12,
                            color: CustomTheme.lightScheme().primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // BOUTONS DE CONTACT (V6)
            if (establishment.telephone.isNotEmpty ||
                establishment.email.isNotEmpty ||
                (establishment.website != null && establishment.website!.isNotEmpty))
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    // Bouton téléphone
                    if (establishment.telephone.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: OutlinedButton.icon(
                            onPressed: () => _makePhoneCall(establishment.telephone),
                            icon: Icon(
                              Icons.phone,
                              size: 16,
                              color: CustomTheme.lightScheme().primary,
                            ),
                            label: Text(
                              'Appeler',
                              style: TextStyle(
                                fontSize: 12,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              side: BorderSide(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bouton email
                    if (establishment.email.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: establishment.telephone.isNotEmpty ? 4 : 0,
                            right: (establishment.website != null && establishment.website!.isNotEmpty) ? 4 : 0,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _sendEmail(establishment.email),
                            icon: Icon(
                              Icons.email,
                              size: 16,
                              color: CustomTheme.lightScheme().primary,
                            ),
                            label: Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              side: BorderSide(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bouton site web
                    if (establishment.website != null && establishment.website!.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: OutlinedButton.icon(
                            onPressed: () => _launchUrl(establishment.website!),
                            icon: Icon(
                              Icons.language,
                              size: 16,
                              color: CustomTheme.lightScheme().primary,
                            ),
                            label: Text(
                              'Site',
                              style: TextStyle(
                                fontSize: 12,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              side: BorderSide(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const Spacer(),

            // Bouton d'action simple
            if (onBuy != null && !isOwnEstablishment)
              ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomTheme.lightScheme().primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Action',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}