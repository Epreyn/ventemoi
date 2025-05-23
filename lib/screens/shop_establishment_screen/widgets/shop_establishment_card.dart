import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ventemoi/features/custom_icon_button/view/custom_icon_button.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
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
      child: Card(
        elevation: UniquesControllers().data.baseSpace / 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            UniquesControllers().data.baseSpace * 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Partie haute : bannière + logo
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        UniquesControllers().data.baseSpace * 2,
                      ),
                    ),
                    child: _buildBanner(),
                  ),

                  // -- Bouton "PLAY" si videoUrl non vide
                  if (establishment.videoUrl.isNotEmpty)
                    Positioned(
                      bottom: UniquesControllers().data.baseSpace,
                      left: UniquesControllers().data.baseSpace,
                      child: CustomIconButton(
                        tag: 'shop-establishment-card-play-button-$index',
                        onPressed: () => _launchVideoLink(establishment.videoUrl),
                        iconData: Icons.play_arrow_outlined,
                        backgroundColor: CustomTheme.lightScheme().primary,
                      ),
                    ),

                  Positioned(
                    bottom: -UniquesControllers().data.baseSpace * 4,
                    right: UniquesControllers().data.baseSpace,
                    child: _buildLogoAvatar(),
                  ),
                ],
              ),
            ),

            // -- Nom
            Padding(
              padding: EdgeInsets.only(
                left: UniquesControllers().data.baseSpace,
                right: UniquesControllers().data.baseSpace,
                top: UniquesControllers().data.baseSpace,
              ),
              child: Text(
                establishment.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: UniquesControllers().data.baseSpace * 3,
                ),
              ),
            ),

            // -- Catégorie (via cc.getCategoryNameById)
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
                  return Text(
                    categoryName.isNotEmpty ? categoryName : 'Catégorie inconnue',
                    style: TextStyle(
                      fontSize: UniquesControllers().data.baseSpace * 1.5,
                    ),
                  );
                },
              ),
            ),

            // -- Description
            Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
              child: SizedBox(
                height: UniquesControllers().data.baseSpace * 13,
                child: AutoSizeText(
                  establishment.description,
                  minFontSize: 12,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // -- Bouton d'action + stock
            Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
              child: FutureBuilder<String>(
                future: _fetchUserTypeName(establishment.userId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('Chargement du type...');
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
                      if (walletSnap.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: const [
                            Text('Chargement...'),
                            Spacer(),
                            FilledButton(onPressed: null, child: Text('...')),
                          ],
                        );
                      }
                      if (!walletSnap.hasData || walletSnap.data!.docs.isEmpty) {
                        return const Text('Aucun wallet trouvé.');
                      }
                      final data = walletSnap.data!.docs.first.data() as Map<String, dynamic>;
                      final coupons = data['coupons'] ?? 0;

                      // Condition => si typeName == "Association", on "Donner".
                      // Sinon, on "Acheter" et on disable si coupons == 0.
                      if (typeName == 'Association') {
                        // On affiche "Donner" + nombre de bons restants
                        return Row(
                          children: [
                            AutoSizeText(
                              '$coupons Bons Restants',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: UniquesControllers().data.baseSpace * 2,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: onBuy,
                              child: const Text('Donner'),
                            ),
                          ],
                        );
                      } else {
                        // Suppose qu’autrement, c’est "Boutique" ou etc.
                        // => on "Acheter" et disable si coupons == 0
                        final bool isDisabled = (coupons == 0);
                        return Row(
                          children: [
                            AutoSizeText(
                              '$coupons Bons Restants',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: UniquesControllers().data.baseSpace * 2,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: isDisabled ? null : onBuy,
                              child: MediaQuery.of(context).size.width < 600
                                  ? const Icon(Icons.shopping_cart)
                                  : const Text('Acheter'),
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
      ),
    );
  }

  /// Récupération du user_type.name en fonction de l'userId
  Future<String> _fetchUserTypeName(String userId) async {
    // 1) Charger doc user
    final snapUser = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!snapUser.exists) return '';

    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';

    // 2) Charger doc user_types/<userTypeId>
    final snapType = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(userTypeId).get();
    if (!snapType.exists) return '';

    final typeData = snapType.data()!;
    final typeName = typeData['name'] ?? '';
    return typeName.toString(); // "Association", "Boutique", ...
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
      return Icon(
        Icons.image_not_supported,
        size: UniquesControllers().data.baseSpace * 10,
        color: Colors.grey,
      );
    }
  }

  /// Logo
  Widget _buildLogoAvatar() {
    if (establishment.logoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: UniquesControllers().data.baseSpace * 4,
        backgroundColor: CustomTheme.lightScheme().surface,
        child: CircleAvatar(
          radius: UniquesControllers().data.baseSpace * 3.8,
          backgroundImage: NetworkImage(establishment.logoUrl),
        ),
      );
    } else {
      return CircleAvatar(
        radius: UniquesControllers().data.baseSpace * 3,
        backgroundColor: CustomTheme.lightScheme().surface,
        child: CircleAvatar(
          radius: UniquesControllers().data.baseSpace * 2.8,
          child: Icon(
            Icons.store,
            size: UniquesControllers().data.baseSpace * 2.5,
          ),
        ),
      );
    }
  }

  void _launchVideoLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Pour ouvrir dans un nouvel onglet sur le Web, vous pouvez spécifier `webOnlyWindowName: '_blank'`
      // Sur mobile, ça ouvrira le navigateur externe.
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Sur mobile : ouvre le navigateur
        webOnlyWindowName: '_blank', // Sur le Web : nouvel onglet
      );
    } else {
      debugPrint("Impossible d'ouvrir l'URL : $url");
    }
  }
}
