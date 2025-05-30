import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_icon_button/view/custom_icon_button.dart';
import '../controllers/shop_establishment_card_controller.dart';

class ShopEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback onBuy;
  final int index;

  const ShopEstablishmentCard({
    super.key,
    required this.establishment,
    required this.onBuy,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      ShopEstablishmentCardController(),
      tag: 'shop-establishment-card-controller-$index',
    );

    return CustomCardAnimation(
      index: index,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = constraints.maxHeight;

          // On peut calculer un "scale" si on veut adapter la taille de police.
          // ex. base sur 300px de large => scale = cardWidth / 300.0
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
                // --- BANNIÈRE + LOGO + PLAY (40% de la hauteur)
                SizedBox(
                  width: cardWidth,
                  height: cardHeight * 0.40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image bannière
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                        ),
                        child: _buildBanner(),
                      ),

                      // Bouton "PLAY" si videoUrl
                      if (establishment.videoUrl.isNotEmpty)
                        Positioned(
                          bottom: UniquesControllers().data.baseSpace,
                          left: UniquesControllers().data.baseSpace,
                          child: CustomIconButton(
                            tag: 'shop-establishment-card-play-button-$index',
                            onPressed: () =>
                                _launchVideoLink(establishment.videoUrl),
                            iconData: Icons.play_arrow_outlined,
                            backgroundColor: CustomTheme.lightScheme().primary,
                          ),
                        ),

                      // Logo en bas à droite
                      Positioned(
                        bottom: -(UniquesControllers().data.baseSpace * 4),
                        right: UniquesControllers().data.baseSpace,
                        child: _buildLogoAvatar(),
                      ),
                    ],
                  ),
                ),

                // --- ESPACE sous le logo (pour éviter la superposition)
                SizedBox(height: UniquesControllers().data.baseSpace * 4),

                // --- NOM (env. 10% de la hauteur)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UniquesControllers().data.baseSpace,
                  ),
                  child: AutoSizeText(
                    establishment.name,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // On adapte la taille en fonction du scale
                      fontSize: 16 * widthScale,
                    ),
                  ),
                ),

                // --- Catégorie (5%)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UniquesControllers().data.baseSpace,
                  ),
                  child: FutureBuilder<String>(
                    future: cc.getCategoryNameById(establishment.categoryId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final categoryName = snapshot.data ?? '';
                      return AutoSizeText(
                        categoryName.isNotEmpty
                            ? categoryName
                            : 'Catégorie inconnue',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13 * widthScale,
                          color: Colors.grey[700],
                        ),
                      );
                    },
                  ),
                ),

                // --- DESCRIPTION (env. 25%)
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.all(UniquesControllers().data.baseSpace),
                    child: AutoSizeText(
                      establishment.description,
                      minFontSize: 10,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * widthScale,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // --- FOOTER : Bouton + stock bons (env. 20%)
                Padding(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
                  child: FutureBuilder<String>(
                    future: _fetchUserTypeName(establishment.userId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: UniquesControllers().data.baseSpace * 3,
                          height: UniquesControllers().data.baseSpace * 3,
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snap.hasError) {
                        return Text('Erreur: ${snap.error}');
                      }
                      final typeName = snap.data ?? '';

                      // On enchaîne avec un StreamBuilder sur le wallet
                      return StreamBuilder<QuerySnapshot>(
                        stream: UniquesControllers()
                            .data
                            .firebaseFirestore
                            .collection('wallets')
                            .where('user_id', isEqualTo: establishment.userId)
                            .limit(1)
                            .snapshots(),
                        builder: (context, walletSnap) {
                          if (walletSnap.connectionState ==
                              ConnectionState.waiting) {
                            return Row(
                              children: const [
                                Text('Chargement...'),
                                Spacer(),
                                SizedBox(
                                  width: 40,
                                  child: LinearProgressIndicator(),
                                ),
                              ],
                            );
                          }
                          if (!walletSnap.hasData ||
                              walletSnap.data!.docs.isEmpty) {
                            return const Text('Aucun wallet trouvé.');
                          }
                          final data = walletSnap.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final coupons = data['coupons'] ?? 0;

                          // Condition => si typeName == "Association", => "Donner"
                          // Sinon, => "Acheter" (disable si coupons == 0)
                          if (typeName == 'Association') {
                            return Row(
                              children: [
                                // Nombre de bons restants
                                Expanded(
                                  child: AutoSizeText(
                                    '$coupons Bons Restants',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14 * widthScale,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: onBuy,
                                  child: Text(
                                    'Donner',
                                    style: TextStyle(fontSize: 14 * widthScale),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            final bool isDisabled = (coupons == 0);
                            return Row(
                              children: [
                                Expanded(
                                  child: AutoSizeText(
                                    '$coupons Bons Restants',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14 * widthScale,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: isDisabled ? null : onBuy,
                                  child: MediaQuery.of(context).size.width < 600
                                      ? const Icon(Icons.shopping_cart)
                                      : Text(
                                          'Acheter',
                                          style: TextStyle(
                                              fontSize: 14 * widthScale),
                                        ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Récupération du user_type.name en fonction de l'userId
  Future<String> _fetchUserTypeName(String userId) async {
    // 1) Charger doc user
    final snapUser = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();
    if (!snapUser.exists) return '';

    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';

    // 2) Charger doc user_types/<userTypeId>
    final snapType = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();
    if (!snapType.exists) return '';

    final typeData = snapType.data()!;
    final typeName = typeData['name'] ?? '';
    return typeName.toString(); // "Association", "Boutique", etc.
  }

  /// Bannière
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

  /// Logo
  Widget _buildLogoAvatar() {
    final double radius = UniquesControllers().data.baseSpace * 3.5;
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
            Icons.store,
            size: UniquesControllers().data.baseSpace * 3,
          ),
        ),
      );
    }
  }

  void _launchVideoLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication, // Sur mobile : ouvre le navigateur
        webOnlyWindowName: '_blank', // Sur le Web : nouvel onglet
      );
    } else {
      debugPrint("Impossible d'ouvrir l'URL : $url");
    }
  }
}
