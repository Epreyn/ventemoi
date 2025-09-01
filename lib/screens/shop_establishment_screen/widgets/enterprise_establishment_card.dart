import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class EnterpriseEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;
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
          final widthScale = cardWidth / 300.0;

          return Card(
            elevation: UniquesControllers().data.baseSpace,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                UniquesControllers().data.baseSpace * 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER identique à ShopEstablishmentCard
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      _buildCompactLogo(),
                      SizedBox(width: UniquesControllers().data.baseSpace * 2),
                      // Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom
                            Text(
                              establishment.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18 * widthScale,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bouton vidéo si disponible
                      if (establishment.videoUrl.isNotEmpty)
                        IconButton(
                          onPressed: () => _launchVideo(establishment.videoUrl),
                          icon: Icon(
                            Icons.play_circle_filled,
                            color: CustomTheme.lightScheme().primary,
                            size: 32 * widthScale,
                          ),
                        ),
                    ],
                  ),
                ),

                // Catégories Enterprise
                if (establishment.enterpriseCategoryIds != null &&
                    establishment.enterpriseCategoryIds!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          establishment.enterpriseCategoryIds!.map((catId) {
                        final catName = enterpriseCategoriesMap[catId] ?? catId;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace,
                            vertical: UniquesControllers().data.baseSpace / 2,
                          ),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              UniquesControllers().data.baseSpace,
                            ),
                          ),
                          child: Text(
                            catName,
                            style: TextStyle(
                              fontSize: 12 * widthScale,
                              color: CustomTheme.lightScheme().primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: UniquesControllers().data.baseSpace * 2),

                // BANNIÈRE AVEC DESCRIPTION
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        UniquesControllers().data.baseSpace,
                      ),
                      color: establishment.bannerUrl.isEmpty
                          ? Colors.grey[100]
                          : null,
                      image: establishment.bannerUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(establishment.bannerUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          UniquesControllers().data.baseSpace,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            establishment.description,
                            style: TextStyle(
                              fontSize: 14 * widthScale,
                              color: Colors.white,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.justify,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // CONTACT RAPIDE
                if (_hasContactInfo())
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                      vertical: UniquesControllers().data.baseSpace,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (establishment.telephone.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.phone,
                            label: 'Appeler',
                            onTap: () => _launchTel(establishment.telephone),
                            scale: widthScale,
                          ),
                        if (establishment.email.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () => _launchEmail(establishment.email),
                            scale: widthScale,
                          ),
                        if (establishment.address.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.directions,
                            label: 'Itinéraire',
                            onTap: () => _launchMaps(establishment.address),
                            scale: widthScale,
                          ),
                      ],
                    ),
                  ),

                // FOOTER avec bouton simulateur
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        UniquesControllers().data.baseSpace * 2,
                      ),
                      bottomRight: Radius.circular(
                        UniquesControllers().data.baseSpace * 2,
                      ),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showQuoteForm(context),
                    icon: const Icon(Icons.description),
                    label: const Text('Demander un devis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomTheme.lightScheme().primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Méthodes helper identiques à ShopEstablishmentCard
  Widget _buildCompactLogo() {
    final size = UniquesControllers().data.baseSpace * 7;
    if (establishment.logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(establishment.logoUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomTheme.lightScheme().primary.withOpacity(0.1),
          border: Border.all(
            color: CustomTheme.lightScheme().primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.business,
          size: size * 0.5,
          color: CustomTheme.lightScheme().primary,
        ),
      );
    }
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace),
      child: Padding(
        padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24 * scale,
              color: CustomTheme.lightScheme().primary,
            ),
            SizedBox(height: UniquesControllers().data.baseSpace / 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * scale,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContactInfo() {
    return establishment.telephone.isNotEmpty ||
        establishment.email.isNotEmpty ||
        establishment.address.isNotEmpty;
  }

  // Méthodes de lancement
  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // MÉTHODE POUR AFFICHER LE FORMULAIRE DE DEVIS
  void _showQuoteForm(BuildContext context) {
    final controller = Get.put(QuotesScreenController());
    // Réinitialiser le formulaire avant d'ouvrir le dialog
    controller.resetForm();
    
    Get.dialog(
      QuoteFormDialog(enterprise: establishment),
      barrierDismissible: false,
    );
  }

  // MÉTHODE DU SIMULATEUR DE POINTS
  void _showPointsSimulator(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final RxString calculatedPoints = '0'.obs;
    final RxDouble enteredAmount = 0.0.obs;

    // Taux de conversion : 2% de cashback (100€ = 2 points)
    // TODO: Récupérer le taux réel depuis Firestore si disponible
    const double cashbackRate = 0.02; // 2%

    // Suggestions de montants
    final List<double> suggestedAmounts = [10, 25, 50, 100, 200];

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.calculate,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulateur de points',
                style: TextStyle(
                  color: CustomTheme.lightScheme().primary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo et nom de l'entreprise
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (establishment.logoUrl.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(establishment.logoUrl),
                          radius: 30,
                        )
                      else
                        CircleAvatar(
                          backgroundColor: CustomTheme.lightScheme()
                              .primary
                              .withOpacity(0.1),
                          radius: 30,
                          child: Icon(
                            Icons.business,
                            color: CustomTheme.lightScheme().primary,
                            size: 30,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              establishment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Entreprise partenaire',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Titre de la section
                Text(
                  'Combien souhaitez-vous dépenser ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),

                // Champ de saisie du montant
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '€',
                    suffixStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: CustomTheme.lightScheme().primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    final amount =
                        double.tryParse(value.replaceAll(',', '.')) ?? 0;
                    enteredAmount.value = amount;
                    final points = (amount * cashbackRate).round();
                    calculatedPoints.value = points.toString();
                  },
                ),
                const SizedBox(height: 24),

                // Résultat du calcul avec animation
                Obx(() => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: enteredAmount.value > 0
                          ? Container(
                              key: ValueKey(calculatedPoints.value),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    CustomTheme.lightScheme().primary,
                                    CustomTheme.lightScheme()
                                        .primary
                                        .withBlue(200),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: CustomTheme.lightScheme()
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.celebration,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Vous gagnerez',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            '${calculatedPoints.value} points',
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Pour ${enteredAmount.value.toStringAsFixed(2)}€ dépensés',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Entrez un montant',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
