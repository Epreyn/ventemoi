import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/stripe_service.dart';
import '../../../core/services/automatic_gift_voucher_service.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';

class CGUPaymentDialog extends StatefulWidget {
  final String userType;

  const CGUPaymentDialog({
    super.key,
    required this.userType,
  });

  @override
  State<CGUPaymentDialog> createState() => _CGUPaymentDialogState();
}

class _CGUPaymentDialogState extends State<CGUPaymentDialog> {
  final RxBool acceptedCGU = false.obs;
  final RxBool paymentProcessing = false.obs;
  final RxInt currentStep = 0.obs;
  final ScrollController scrollController = ScrollController();
  final RxString selectedPaymentOption = 'monthly'.obs; // monthly or annual

  // Calcul des prix selon le type d'utilisateur et l'option de paiement
  String get firstYearPrice {
    if (widget.userType == 'Association') return '0';

    switch (widget.userType) {
      case 'Boutique':
        if (selectedPaymentOption.value == 'annual') {
          return '870'; // 270€ adhésion + 600€ cotisation annuelle
        } else {
          return '930'; // 270€ adhésion + 55€/mois x 12
        }
      case 'Commerçant':
      case 'Entreprise':
        if (selectedPaymentOption.value == 'annual') {
          return '870'; // 270€ adhésion + 600€ cotisation annuelle
        } else {
          return '930'; // 270€ adhésion + 55€/mois x 12
        }
      default:
        return '0';
    }
  }

  String get monthlyPriceAfterFirstYear {
    switch (widget.userType) {
      case 'Boutique':
        if (selectedPaymentOption.value == 'annual') {
          return '870'; // 270€ adhésion + 600€ cotisation annuelle
        } else {
          return '930'; // 270€ adhésion + 55€/mois x 12
        }
      case 'Commerçant':
      case 'Entreprise':
        return selectedPaymentOption.value == 'annual' ? '600' : '55';
      case 'Association':
        return '0';
      default:
        return '0';
    }
  }

  // CGU content
  final String cguContent = '''
CONDITIONS GÉNÉRALES D'UTILISATION - VENTEMOI

Article 1 : Objet
Les présentes Conditions Générales d'Utilisation (CGU) régissent l'utilisation de la plateforme VenteMoi par les établissements professionnels (boutiques, commerçants, entreprises, associations).

Article 2 : Inscription et Abonnement

2.1 Tarifs d'abonnement (HT) :

ENTREPRISES / BOUTIQUES
- 1ère année :
  - Option annuelle : 870€ HT (270€ adhésion + vidéo + 600€ cotisation annuelle)
  - Option mensuelle : 930€ HT (270€ adhésion + vidéo + 55€/mois x 12)
  - Bon cadeau de bienvenue : 50€ TTC offert

- À partir de la 2ème année :
  - Option annuelle : 600€ HT/an
  - Option mensuelle : 55€ HT/mois (660€/an)

ASSOCIATIONS
- Adhésion gratuite
- Visible sur l'application à partir de 15 filleuls
- Bon cadeau de 50€ TTC à partir de 30 filleuls

2.2 Le paiement s'effectue via Stripe, par prélèvement automatique mensuel ou annuel selon l'option choisie.

2.3 L'abonnement est avec engagement d'un an minimum.

Article 3 : Services proposés
3.1 La plateforme permet aux établissements de :
- Créer et gérer leur fiche établissement avec vidéo de présentation
- Publier des offres, promotions et événements
- Recevoir des avis clients
- Accéder aux statistiques de visite
- Bénéficier de prestations vidéo à tarifs préférentiels
- Être mis en avant minimum deux fois par an

3.2 Pour les commerçants : mise à disposition de 16 bons cadeaux de 50€ TTC chacun

Article 4 : Commissions sur ventes
4.1 Une commission est prélevée sur chaque vente réalisée via VenteMoi
4.2 Le taux de commission est adapté selon le type d'activité (conditions détaillées sur demande)

Article 5 : Programme de parrainage
5.1 Les établissements peuvent participer au programme ambassadeur VenteMoi
5.2 Récompenses : 100€ en bons cadeaux pour chaque entreprise/commerce parrainé

Article 6 : Obligations de l'établissement
6.1 L'établissement s'engage à :
- Fournir des informations exactes et à jour
- Respecter la législation en vigueur
- Ne pas publier de contenu illicite ou offensant
- Honorer les offres et bons cadeaux publiés sur la plateforme

Article 7 : Propriété intellectuelle
7.1 L'établissement conserve tous les droits sur son contenu
7.2 VenteMoi dispose d'une licence d'utilisation pour l'affichage sur la plateforme

Article 8 : Protection des données
8.1 VenteMoi s'engage à protéger les données conformément au RGPD
8.2 Les données sont utilisées uniquement dans le cadre du service

Article 9 : Visibilité dans le shop
9.1 L'établissement n'est visible dans le shop qu'après acceptation des CGU et activation de l'abonnement
9.2 La visibilité est suspendue en cas de non-paiement

Article 10 : Résiliation
10.1 L'abonnement peut être résilié après la première année d'engagement
10.2 VenteMoi peut résilier en cas de non-respect des CGU
10.3 En cas de résiliation, l'établissement reste redevable des sommes dues

Article 11 : Limitation de responsabilité
11.1 VenteMoi ne peut être tenu responsable des transactions entre établissements et clients
11.2 La plateforme est fournie "en l'état" sans garantie de disponibilité continue

Article 12 : Modifications
12.1 VenteMoi se réserve le droit de modifier les CGU et les tarifs
12.2 Les établissements seront informés de toute modification avec un préavis de 30 jours

Article 13 : Droit applicable
Les présentes CGU sont régies par le droit français. Tout litige sera soumis aux tribunaux compétents.
  ''';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  EdgeInsets.all(UniquesControllers().data.baseSpace * 2.5),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: CustomTheme.lightScheme().primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activation de votre établissement',
                          style: TextStyle(
                            fontSize: UniquesControllers().data.baseSpace * 2.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                              currentStep.value == 0
                                  ? 'Étape 1/2 : Conditions Générales'
                                  : 'Étape 2/2 : Choisir votre formule',
                              style: TextStyle(
                                fontSize:
                                    UniquesControllers().data.baseSpace * 1.4,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Obx(() {
                if (currentStep.value == 0) {
                  // CGU Step
                  return Column(
                    children: [
                      Expanded(
                        child: Scrollbar(
                          controller: scrollController,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace * 2.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    UniquesControllers().data.baseSpace * 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    cguContent,
                                    style: TextStyle(
                                      fontSize:
                                          UniquesControllers().data.baseSpace *
                                              1.5,
                                      height: 1.6,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Obx(() => Checkbox(
                                  value: acceptedCGU.value,
                                  onChanged: (value) {
                                    acceptedCGU.value = value ?? false;
                                  },
                                  activeColor:
                                      CustomTheme.lightScheme().primary,
                                )),
                            Expanded(
                              child: Text(
                                'J\'ai lu et j\'accepte les Conditions Générales d\'Utilisation',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Payment Options Step
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(
                      UniquesControllers().data.baseSpace * 2.5,
                    ),
                    child: Column(
                      children: [
                        // Titre
                        Container(
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.celebration_rounded,
                                size: 48,
                                color: CustomTheme.lightScheme().primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bienvenue sur VenteMoi !',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 2.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choisissez votre formule d\'abonnement',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.6,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const CustomSpace(heightMultiplier: 3),

                        // Options de paiement
                        if (widget.userType != 'Association') ...[
                          // Option Mensuelle
                          Obx(() => _buildPaymentCard(
                                isSelected:
                                    selectedPaymentOption.value == 'monthly',
                                onTap: () =>
                                    selectedPaymentOption.value = 'monthly',
                                icon: Icons.calendar_today_rounded,
                                title: 'Formule Mensuelle',
                                price: '55€ HT/mois',
                                details: [
                                  '270€ HT de frais d\'adhésion (1ère année)',
                                  '55€ HT/mois en prélèvement automatique',
                                  'Total 1ère année : 930€ HT',
                                  'Dès la 2ème année : 55€ HT/mois',
                                ],
                                badge: null,
                              )),

                          const SizedBox(height: 16),

                          // Option Annuelle
                          Obx(() => _buildPaymentCard(
                                isSelected:
                                    selectedPaymentOption.value == 'annual',
                                onTap: () =>
                                    selectedPaymentOption.value = 'annual',
                                icon: Icons.star_rounded,
                                title: 'Formule Annuelle',
                                price: '870€ HT/an',
                                details: [
                                  '270€ HT de frais d\'adhésion inclus',
                                  '600€ HT de cotisation annuelle',
                                  'Économisez 60€ sur la 1ère année',
                                  'Dès la 2ème année : 600€ HT/an',
                                ],
                                badge: 'Recommandé',
                              )),
                        ],

                        const CustomSpace(heightMultiplier: 3),

                        // Avantages inclus
                        Container(
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Inclus dans votre abonnement',
                                    style: TextStyle(
                                      fontSize:
                                          UniquesControllers().data.baseSpace *
                                              1.6,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const CustomSpace(heightMultiplier: 2),
                              _buildIncludedItem(
                                  '✅ Bon cadeau de bienvenue de 50€ TTC'),
                              _buildIncludedItem(
                                  '✅ Vidéo de présentation professionnelle'),
                              _buildIncludedItem(
                                  '✅ Visibilité immédiate dans le shop'),
                              _buildIncludedItem(
                                  '✅ Publication d\'offres illimitées'),
                              _buildIncludedItem(
                                  '✅ Mise en avant 2 fois par an minimum'),
                              if (widget.userType == 'Commerçant' ||
                                  widget.userType == 'Boutique')
                                _buildIncludedItem(
                                    '✅ 16 bons cadeaux de 50€ TTC'),
                            ],
                          ),
                        ),

                        const CustomSpace(heightMultiplier: 3),

                        // Info paiement sécurisé
                        Container(
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Paiement 100% sécurisé',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vos données bancaires sont protégées par Stripe',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.3,
                                        color: Colors.blue.shade600,
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
              }),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Obx(() {
                    if (currentStep.value > 0) {
                      return TextButton.icon(
                        onPressed: () => currentStep.value = 0,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Retour'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const Spacer(),
                  Obx(() {
                    final bool canProceed =
                        currentStep.value == 0 ? acceptedCGU.value : true;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: canProceed
                            ? LinearGradient(
                                colors: [
                                  CustomTheme.lightScheme().primary,
                                  CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: canProceed ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canProceed
                              ? () async {
                                  if (currentStep.value == 0) {
                                    currentStep.value = 1;
                                  } else {
                                    // Lancer le paiement Stripe
                                    await _processStripePayment();
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  UniquesControllers().data.baseSpace * 3,
                              vertical:
                                  UniquesControllers().data.baseSpace * 1.5,
                            ),
                            child: paymentProcessing.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        currentStep.value == 0
                                            ? Icons.arrow_forward_rounded
                                            : Icons.payment_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentStep.value == 0
                                            ? 'CONTINUER'
                                            : widget.userType == 'Association'
                                                ? 'TERMINER'
                                                : 'PROCÉDER AU PAIEMENT',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String price,
    required List<String> details,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomTheme.lightScheme().primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? CustomTheme.lightScheme().primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize:
                                  UniquesControllers().data.baseSpace * 1.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: UniquesControllers().data.baseSpace,
                                vertical:
                                    UniquesControllers().data.baseSpace * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.2,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 2,
                          fontWeight: FontWeight.w800,
                          color: CustomTheme.lightScheme().primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: CustomTheme.lightScheme().primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detail,
                          style: TextStyle(
                            fontSize: UniquesControllers().data.baseSpace * 1.4,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: UniquesControllers().data.baseSpace * 1.2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: UniquesControllers().data.baseSpace * 1.4,
          color: Colors.green.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Nouvelle méthode pour traiter le paiement avec Stripe
  Future<void> _processStripePayment() async {
    if (!acceptedCGU.value) {
      UniquesControllers().data.snackbar(
            'CGU non acceptées',
            'Vous devez accepter les conditions générales d\'utilisation',
            true,
          );
      return;
    }

    paymentProcessing.value = true;

    try {
      final bool useTemporaryMode = false; // Mode production Stripe

      if (useTemporaryMode) {
        await _processTemporaryPayment();
      } else {
        // Fermer la dialog actuelle AVANT de créer la session
        Get.back();

        // Créer la session et récupérer l'URL et l'ID
        final result = await _createCheckoutSession();

        if (result != null &&
            result['url'] != null &&
            result['sessionId'] != null) {
          // Afficher immédiatement la dialog d'attente AVANT d'ouvrir Stripe
          _showPaymentWaitingDialog(result['sessionId']!);

          // Attendre un peu pour que la dialog s'affiche
          await Future.delayed(const Duration(milliseconds: 500));

          // Ouvrir Stripe dans un nouvel onglet
          await StripeService.to.launchCheckout(result['url']!);
        } else {
          throw 'Impossible de créer la session de paiement';
        }
      }
    } catch (e) {
      paymentProcessing.value = false;
      UniquesControllers().data.snackbar(
            'Erreur',
            'Une erreur est survenue lors du paiement: $e',
            true,
          );
    }
  }

  // Nouvelle méthode pour créer la session et retourner l'URL et l'ID
  Future<Map<String, String>?> _createCheckoutSession() async {
    try {
      String? checkoutUrl;
      String? sessionId;

      // Créer la session de checkout selon l'option choisie
      final sessionResult = selectedPaymentOption.value == 'annual'
          ? await StripeService.to.createAnnualOptionCheckoutWithId(
              userType: widget.userType,
              successUrl: 'https://app.ventemoi.fr/stripe-success.html',
              cancelUrl: 'https://app.ventemoi.fr/stripe-cancel.html',
            )
          : await StripeService.to.createMonthlyOptionCheckoutWithId(
              userType: widget.userType,
              successUrl: 'https://app.ventemoi.fr/stripe-success.html',
              cancelUrl: 'https://app.ventemoi.fr/stripe-cancel.html',
            );

      if (sessionResult != null) {
        return {
          'url': sessionResult['url']!,
          'sessionId': sessionResult['sessionId']!,
        };
      }
    } catch (e) {
      print('Erreur création session: $e');
    }

    return null;
  }

  // Nouvelle méthode pour afficher la dialog d'attente
  void _showPaymentWaitingDialog(String sessionId) {
    StreamSubscription? subscription;
    StreamSubscription? paymentIntentSubscription;
    StreamSubscription? estabSubscription;
    Timer? timeoutTimer;
    Timer? pollingTimer;
    final RxBool hasUserClosedTab = false.obs;
    final RxString debugStatus = 'Initialisation...'.obs;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Empêcher la fermeture accidentelle
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de chargement
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CustomTheme.lightScheme().primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Paiement en cours...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Complétez votre paiement dans l\'onglet Stripe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ne fermez pas cette fenêtre',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La fermeture de l\'onglet Stripe annulera le paiement',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Message d'attente animé
                Obx(() => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: hasUserClosedTab.value
                          ? Text(
                              'Vérification du paiement...',
                              key: const ValueKey('checking'),
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              'En attente de confirmation...',
                              key: const ValueKey('waiting'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    )),

                // Debug info (à retirer en production)
                Obx(() => Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Session: ${sessionId.substring(0, 8)}...\n${debugStatus.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )),

                const SizedBox(height: 24),

                // Bouton d'annulation
                TextButton(
                  onPressed: () {
                    // Afficher une confirmation avant d'annuler
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Annuler le paiement ?'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir annuler le paiement ? '
                          'Vous devrez recommencer la procédure.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Get.back(), // Fermer la confirmation
                            child: const Text('Continuer le paiement'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              subscription?.cancel();
                              paymentIntentSubscription?.cancel();
                              estabSubscription?.cancel();
                              timeoutTimer?.cancel();
                              pollingTimer?.cancel();
                              Get.back(); // Fermer la confirmation
                              Get.back(); // Fermer la dialog d'attente
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Confirmer l\'annulation'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Annuler le paiement',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Écouter les changements de la session de paiement
    final user = UniquesControllers().data.firebaseAuth.currentUser;
    if (user != null) {
      print('🔵 Début écoute session: $sessionId pour user: ${user.uid}');
      debugStatus.value = 'Écoute session...';

      // Écouter aussi la collection payments pour cette session
      paymentIntentSubscription = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('customers')
          .doc(user.uid)
          .collection('payments')
          .orderBy('created', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final paymentData = snapshot.docs.first.data();
          print('💳 Payment détecté: ${paymentData['status']}');

          if (paymentData['status'] == 'succeeded') {
            print('✅ Paiement réussi détecté via payments collection!');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            Get.back();

            // S'assurer que l'établissement est bien activé
            //await _ensureEstablishmentActivated();
            _ensureEstablishmentActivated();

            _handlePaymentSuccess();
          }
        }
      });

      subscription = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          print('📘 Session mise à jour: ${data.keys.join(', ')}');

          // Afficher TOUS les champs pour debug
          data.forEach((key, value) {
            if (value != null && value.toString().isNotEmpty) {
              print(
                  '   - $key: ${value.runtimeType == String && (value as String).length > 50 ? '${value.substring(0, 50)}...' : value}');
            }
          });

          // Debug: afficher tous les champs
          debugStatus.value = 'Champs: ${data.keys.length}\n';

          // Vérifier TOUS les champs possibles qui pourraient indiquer un succès
          final bool isPaid = data['payment_status'] == 'paid' ||
              data['payment_status'] == 'succeeded' ||
              data['status'] == 'paid' ||
              data['status'] == 'complete' ||
              data['status'] == 'success' ||
              data['payment_intent'] != null ||
              data['subscription'] != null ||
              data['invoice'] != null;

          if (isPaid) {
            print('✅ Paiement détecté comme réussi!');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            // Fermer la dialog d'attente
            Get.back();

            // S'assurer que l'établissement est bien activé
            await _ensureEstablishmentActivated();

            // Traiter le succès du paiement
            await _handlePaymentSuccess();
          } else if (data['status'] == 'expired' ||
              data['status'] == 'canceled' ||
              data['error'] != null) {
            print('❌ Paiement échoué ou annulé');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            Get.back();
            UniquesControllers().data.snackbar(
                  'Paiement échoué',
                  'Le paiement n\'a pas pu être complété',
                  true,
                );
          }
        } else {
          print('⚠️ Document de session non trouvé');
          debugStatus.value = 'Session non trouvée';
        }
      }, onError: (error) {
        print('❌ Erreur listener: $error');
        debugStatus.value = 'Erreur: $error';
      });

      // Polling supplémentaire toutes les 2 secondes pendant 30 secondes, puis toutes les 5 secondes
      int pollCount = 0;
      pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        pollCount++;

        // Après 15 tentatives (30 secondes), réduire la fréquence
        if (pollCount == 15) {
          timer.cancel();
          pollingTimer =
              Timer.periodic(const Duration(seconds: 5), (newTimer) async {
            await _performPolling(
                user,
                sessionId,
                subscription,
                paymentIntentSubscription,
                estabSubscription,
                newTimer,
                timeoutTimer);
          });
        } else {
          await _performPolling(
              user,
              sessionId,
              subscription,
              paymentIntentSubscription,
              estabSubscription,
              timer,
              timeoutTimer);
        }
      });

      // Ajouter aussi un listener sur l'établissement pour détecter les changements
      estabSubscription = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          final hasActiveSubscription =
              data['has_active_subscription'] ?? false;
          final hasAcceptedContract = data['has_accepted_contract'] ?? false;

          print(
              '🏢 Établissement mis à jour - Subscription: $hasActiveSubscription, Contract: $hasAcceptedContract');

          if (hasActiveSubscription && hasAcceptedContract) {
            print('✅ Abonnement actif détecté sur l\'établissement!');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            Get.back();

            // Appeler handlePaymentSuccess pour s'assurer que tout est bien mis à jour
            //await _handlePaymentSuccess();
            _handlePaymentSuccess();
          }
        }
      });

      // Timeout après 10 minutes
      timeoutTimer = Timer(const Duration(minutes: 10), () {
        subscription?.cancel();
        paymentIntentSubscription?.cancel();
        estabSubscription?.cancel();
        pollingTimer?.cancel();
        Get.back();
        UniquesControllers().data.snackbar(
              'Timeout',
              'Le délai de paiement a expiré. Veuillez réessayer.',
              true,
            );
      });
    }
  }

  // Méthode séparée pour effectuer le polling
  Future<void> _performPolling(
    User user,
    String sessionId,
    StreamSubscription? subscription,
    StreamSubscription? paymentIntentSubscription,
    StreamSubscription? estabSubscription,
    Timer timer,
    Timer? timeoutTimer,
  ) async {
    try {
      print('🔄 Polling session...');

      // Vérifier la session
      final sessionDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final data = sessionDoc.data()!;

        // Afficher TOUS les champs non-null pour debug
        final nonNullFields = <String>[];
        data.forEach((key, value) {
          if (value != null) {
            try {
              final valueStr = value.toString();
              if (valueStr.length > 50) {
                nonNullFields.add('$key: ${valueStr.substring(0, 50)}...');
              } else {
                nonNullFields.add('$key: $valueStr');
              }
            } catch (e) {
              nonNullFields.add('$key: [non affichable]');
            }
          }
        });
        print('🔍 Polling - Champs non-null: ${nonNullFields.join(', ')}');

        // Vérifier aussi les payments
        final payments = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('customers')
            .doc(user.uid)
            .collection('payments')
            .orderBy('created', descending: true)
            .limit(1)
            .get();

        if (payments.docs.isNotEmpty) {
          final paymentData = payments.docs.first.data();
          print('💳 Payment trouvé: ${paymentData['status']}');

          if (paymentData['status'] == 'succeeded') {
            print('✅ Paiement réussi détecté par polling!');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timer.cancel();
            timeoutTimer?.cancel();

            Get.back();

            // S'assurer que l'établissement est bien activé
            await _ensureEstablishmentActivated();

            await _handlePaymentSuccess();
            return;
          }
        }

        // Vérifier l'établissement directement
        final estabQuery = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .where('user_id', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final estabData = estabQuery.docs.first.data();
          final hasActiveSubscription =
              estabData['has_active_subscription'] ?? false;

          if (hasActiveSubscription) {
            print('✅ Abonnement actif détecté dans l\'établissement!');
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timer.cancel();
            timeoutTimer?.cancel();

            Get.back();

            // Appeler handlePaymentSuccess pour mettre à jour tout correctement
            await _handlePaymentSuccess();
            return;
          }
        }

        // Vérifier le succès via les champs de la session
        final bool isPaid = data['payment_status'] == 'paid' ||
            data['payment_status'] == 'succeeded' ||
            data['status'] == 'paid' ||
            data['status'] == 'complete' ||
            data['status'] == 'success' ||
            data['payment_intent'] != null ||
            data['subscription'] != null ||
            data['invoice'] != null;

        if (isPaid && subscription != null) {
          print('✅ Paiement détecté par polling!');
          subscription?.cancel();
          paymentIntentSubscription?.cancel();
          estabSubscription?.cancel();
          timeoutTimer?.cancel();
          timer.cancel();

          Get.back();

          // S'assurer que l'établissement est bien activé
          await _ensureEstablishmentActivated();

          await _handlePaymentSuccess();
        }
      }
    } catch (e) {
      print('❌ Erreur polling: $e');
    }
  }

  // Nouvelle méthode pour gérer le succès du paiement
  Future<void> _handlePaymentSuccess() async {
    try {
      print('🚀 Début _handlePaymentSuccess()');

      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('👤 UID utilisateur: $uid');

      // Trouver l'établissement
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final docId = estabQuery.docs.first.id;
        print('🏢 Établissement trouvé: $docId');

        // Déterminer le type d'abonnement
        // Si selectedPaymentOption n'est pas défini, essayer de le récupérer depuis l'établissement
        String paymentOption = selectedPaymentOption.value;
        if (paymentOption.isEmpty) {
          final existingData = estabQuery.docs.first.data();
          paymentOption = existingData['payment_option'] ?? 'monthly';
          print(
              '⚠️ Option de paiement récupérée depuis Firestore: $paymentOption');
        }

        print('💳 Type d\'abonnement: $paymentOption');

        // Mettre à jour les statuts
        final updateData = {
          'has_accepted_contract': true,
          'has_active_subscription': true,
          'subscription_status': paymentOption,
          'subscription_start_date': FieldValue.serverTimestamp(),
          'subscription_end_date':
              Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          'payment_option': paymentOption,
          'last_payment_update': FieldValue.serverTimestamp(),
        };

        print('📝 Mise à jour avec: $updateData');

        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(docId)
            .update(updateData);

        print('✅ Établissement mis à jour avec succès');

        // Créer le bon cadeau de bienvenue
        try {
          await _createWelcomeGiftVoucher(docId);
          print('🎁 Bon cadeau créé');
        } catch (e) {
          print('⚠️ Erreur création bon cadeau (non bloquant): $e');
        }

        // Créditer les 50 points de bienvenue dans le wallet
        try {
          await _creditWelcomePoints(uid, 50);
          print('💰 50 points de bienvenue crédités');
        } catch (e) {
          print('⚠️ Erreur crédit des points (non bloquant): $e');
        }
      } else {
        print('❌ Aucun établissement trouvé pour l\'utilisateur');
      }

      // Afficher le dialog de succès
      Get.dialog(
        Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de succès
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Paiement réussi !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Votre établissement est maintenant actif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bon cadeau de 50€ offert !',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Get.back(); // Fermer le dialog
                    Get.offAllNamed('/pro-establishment-profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print('❌ Erreur handlePaymentSuccess: $e');
      UniquesControllers().data.snackbar(
            'Erreur',
            'Une erreur est survenue lors de la finalisation: $e',
            true,
          );
    }
  }

  // Méthode pour créer le bon cadeau
  Future<void> _createWelcomeGiftVoucher(String establishmentId) async {
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('gift_vouchers')
        .add({
      'establishment_id': establishmentId,
      'amount': 50.0,
      'type': 'welcome',
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
      'expires_at':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
      'code': 'WELCOME-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  // Méthode de fallback pour vérifier et mettre à jour l'établissement
  // Méthode de fallback pour vérifier et mettre à jour l'établissement
  Future<void> _ensureEstablishmentActivated() async {
    try {
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) return;

      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final doc = estabQuery.docs.first;
        final data = doc.data();

        // Vérifier si l'activation n'est pas complète
        if (data['has_accepted_contract'] != true ||
            data['has_active_subscription'] != true) {
          print('⚠️ Établissement non activé détecté, mise à jour forcée...');

          await doc.reference.update({
            'has_accepted_contract': true,
            'has_active_subscription': true,
            'subscription_status': selectedPaymentOption.value.isNotEmpty
                ? selectedPaymentOption.value
                : 'monthly',
            'subscription_start_date': FieldValue.serverTimestamp(),
            'subscription_end_date': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 365))),
            'payment_option': selectedPaymentOption.value.isNotEmpty
                ? selectedPaymentOption.value
                : 'monthly',
            'activation_forced': true,
            'activation_forced_at': FieldValue.serverTimestamp(),
          });

          print('✅ Activation forcée réussie');

          // Créditer les 50 points si pas déjà fait
          await _creditWelcomePoints(uid, 50);
        }
      }
    } catch (e) {
      print('❌ Erreur _ensureEstablishmentActivated: $e');
    }
  }

  // Méthode temporaire en attendant la configuration Stripe
  Future<void> _processTemporaryPayment() async {
    // Simuler un délai de traitement
    await Future.delayed(const Duration(seconds: 2));

    // Récupérer l'utilisateur actuel
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('Utilisateur non connecté');

    // Trouver l'établissement
    final estabQuery = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (estabQuery.docs.isEmpty) {
      throw Exception('Aucun établissement trouvé');
    }

    final docId = estabQuery.docs.first.id;

    // Mettre à jour les statuts d'abonnement
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .doc(docId)
        .update({
      'has_accepted_contract': true,
      'has_active_subscription': true,
      'subscription_status': selectedPaymentOption.value,
      'subscription_start_date': FieldValue.serverTimestamp(),
      'subscription_end_date':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
      'payment_option': selectedPaymentOption.value,
      'temporary_mode': true, // Marquer comme temporaire
    });

    // Créer le bon cadeau de bienvenue si le service existe
    try {
      if (Get.isRegistered<AutomaticGiftVoucherService>()) {
        // await AutomaticGiftVoucherService.to.createWelcomeGiftVoucher(
        //   establishmentId: docId,
        //   amount: 50.0,
        // );
      }
    } catch (e) {
      print('Impossible de créer le bon cadeau: $e');
    }

    // Fermer la dialog
    Get.back();

    // Message de succès
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Mode Temporaire'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre établissement est maintenant actif en mode temporaire.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Important : Le paiement Stripe n\'est pas encore configuré. '
              'Vous devrez finaliser votre abonnement ultérieurement.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un email vous sera envoyé pour finaliser le paiement.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back(); // Fermer la dialog
              Get.offAllNamed('/pro-establishment-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Méthode pour créditer les points de bienvenue dans le wallet
  Future<void> _creditWelcomePoints(String userId, int points) async {
    try {
      // Vérifier si le wallet existe déjà
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (walletQuery.docs.isEmpty) {
        // Créer un nouveau wallet
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .add({
          'user_id': userId,
          'points': points,
          'coupons': 0,
          'created_at': FieldValue.serverTimestamp(),
        });

        print('💰 Nouveau wallet créé avec $points points de bienvenue');
      } else {
        // Mettre à jour le wallet existant
        final walletDoc = walletQuery.docs.first;
        await walletDoc.reference.update({
          'points': FieldValue.increment(points),
        });

        print('💰 $points points de bienvenue ajoutés au wallet existant');
      }
    } catch (e) {
      print('❌ Erreur lors du crédit des points de bienvenue: $e');
    }
  }
}
