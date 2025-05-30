import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

/// Widget pour afficher un établissement "Entreprise" sous forme de carte.
///  - bannière en haut, logo superposé
///  - nom, description, catégories
///  - icônes cliquables en bas pour adresse, email, téléphone
class EnterpriseEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;

  /// Permet d’afficher les libellés de catégories :
  ///  key = categoryId, value = nom de la catégorie
  final RxMap<String, String> enterpriseCategoriesMap;

  const EnterpriseEstablishmentCard({
    super.key,
    required this.establishment,
    required this.index,
    required this.enterpriseCategoriesMap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardAnimation(
      index: index,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = constraints.maxHeight;

          // Petite adaptation de la taille de police
          final widthScale = cardWidth / 300.0;

          return Card(
            elevation: UniquesControllers().data.baseSpace / 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                UniquesControllers().data.baseSpace * 2,
              ),
            ),
            child: Column(
              children: [
                // --- BANNIERE + LOGO + BOUTON PLAY ---
                SizedBox(
                  width: cardWidth,
                  height: cardHeight * 0.4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Bannière
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                        ),
                        child: _buildBanner(),
                      ),
                      // Bouton "play" si videoUrl
                      if (establishment.videoUrl.isNotEmpty)
                        Positioned(
                          bottom: UniquesControllers().data.baseSpace,
                          left: UniquesControllers().data.baseSpace,
                          child: Container(
                            decoration: BoxDecoration(
                              color: CustomTheme.lightScheme().primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: Colors.white,
                              onPressed: () =>
                                  _launchVideo(establishment.videoUrl),
                            ),
                          ),
                        ),
                      // Logo
                      Positioned(
                        bottom: -(UniquesControllers().data.baseSpace * 4),
                        right: UniquesControllers().data.baseSpace,
                        child: _buildLogoAvatar(),
                      ),
                    ],
                  ),
                ),

                // Espace sous le logo
                SizedBox(height: UniquesControllers().data.baseSpace * 4),

                // --- NOM ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UniquesControllers().data.baseSpace,
                  ),
                  child: AutoSizeText(
                    establishment.name,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * widthScale,
                    ),
                  ),
                ),

                // --- DESCRIPTION + CATEGORIES (Expand pour occuper l'espace) ---
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.all(UniquesControllers().data.baseSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        AutoSizeText(
                          establishment.description,
                          minFontSize: 10,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * widthScale,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        // Catégories
                        _buildCategories(widthScale),
                      ],
                    ),
                  ),
                ),

                // --- LIGNE D'ICÔNES "Adresse - Email - Téléphone" ---
                Padding(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
                  child: _buildBottomIconsRow(widthScale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // Banner
  // ----------------------------------------------------------------
  Widget _buildBanner() {
    if (establishment.bannerUrl.isNotEmpty) {
      return Image.network(
        establishment.bannerUrl,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: UniquesControllers().data.baseSpace * 10,
          color: Colors.grey,
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // Logo
  // ----------------------------------------------------------------
  Widget _buildLogoAvatar() {
    final radius = UniquesControllers().data.baseSpace * 3.5;
    if (establishment.logoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: CustomTheme.lightScheme().surface,
        child: CircleAvatar(
          radius: radius - 2,
          backgroundImage: NetworkImage(establishment.logoUrl),
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: CustomTheme.lightScheme().surface,
        child: CircleAvatar(
          radius: radius - 4,
          child: Icon(
            Icons.business,
            size: UniquesControllers().data.baseSpace * 3,
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // Affichage des catégories
  // ----------------------------------------------------------------
  Widget _buildCategories(double scale) {
    // enterpriseCategoryIds => noms via enterpriseCategoriesMap
    if (establishment.enterpriseCategoryIds == null ||
        establishment.enterpriseCategoryIds!.isEmpty) {
      return const SizedBox.shrink();
    }

    final cats = <String>[];
    for (final catId in establishment.enterpriseCategoryIds!) {
      final catName = enterpriseCategoriesMap[catId] ?? catId;
      cats.add(catName);
    }
    final catText = cats.join(', ');

    return AutoSizeText(
      catText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12 * scale,
        color: Colors.blueGrey,
      ),
    );
  }

  // ----------------------------------------------------------------
  // Ligne du bas avec 3 icônes : Adresse / Email / Téléphone
  // ----------------------------------------------------------------
  Widget _buildBottomIconsRow(double scale) {
    final hasAddress = establishment.address.isNotEmpty;
    final hasEmail = establishment.email.isNotEmpty;
    final hasPhone = establishment.telephone.isNotEmpty;

    // On construit une liste d'icônes conditionnellement
    final icons = <Widget>[];

    if (hasAddress) {
      icons.add(_iconButton(
        icon: Icons.location_on_outlined,
        label: establishment.address,
        scale: scale,
        onTap: () => _launchMaps(establishment.address),
      ));
    }
    if (hasEmail) {
      icons.add(_iconButton(
        icon: Icons.email_outlined,
        label: establishment.email,
        scale: scale,
        onTap: () => _launchEmail(establishment.email),
      ));
    }
    if (hasPhone) {
      icons.add(_iconButton(
        icon: Icons.phone_outlined,
        label: establishment.telephone,
        scale: scale,
        onTap: () => _launchTel(establishment.telephone),
      ));
    }

    if (icons.isEmpty) {
      return const SizedBox.shrink();
    }

    // On met un Row, centré horizontalement, avec un spacing
    return Wrap(
      spacing: 8, // un peu d'espace entre éléments
      runSpacing: 4, // espace vertical si ça revient à la ligne
      alignment: WrapAlignment.center,
      children: icons,
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required double scale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20 * scale, color: CustomTheme.lightScheme().primary),
            SizedBox(height: 4),
            // On affiche le label en petite police
            SizedBox(
              width: 60 * scale,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10 * scale, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // Ouvrir un lien vidéo
  // ----------------------------------------------------------------
  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  // ----------------------------------------------------------------
  // Ouvrir mailto
  // ----------------------------------------------------------------
  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ----------------------------------------------------------------
  // Ouvrir tel
  // ----------------------------------------------------------------
  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ----------------------------------------------------------------
  // Ouvrir google maps
  // ----------------------------------------------------------------
  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
