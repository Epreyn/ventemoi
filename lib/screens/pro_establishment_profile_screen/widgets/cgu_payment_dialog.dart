import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/stripe_service.dart';
import '../../../core/services/automatic_gift_voucher_service.dart';
import '../../../core/services/stripe_payment_manager.dart';
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

  // Dans cgu_payment_dialog.dart, remplacer _processStripePayment par :

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
      final bool useTemporaryMode = false;

      if (useTemporaryMode) {
        await _processTemporaryPayment();
      } else {
        // Fermer la dialog CGU
        Get.back();

        // Utiliser le manager centralisé
        await StripePaymentManager.to.processSubscriptionPayment(
          userType: widget.userType,
          paymentOption: selectedPaymentOption.value,
          onSuccess: () async {
            await _ensureEstablishmentActivated();
            _handlePaymentSuccess();
          },
        );
      }
    } catch (e) {
      paymentProcessing.value = false;
      UniquesControllers().data.snackbar(
            'Erreur',
            'Une erreur est survenue: $e',
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

  void _showPaymentWaitingDialog(String sessionId) {
    // Variables pour gérer les subscriptions
    StreamSubscription? subscription;
    StreamSubscription? paymentIntentSubscription;
    StreamSubscription? estabSubscription;
    Timer? timeoutTimer;
    Timer? pollingTimer;

    // Contrôles pour éviter les déclenchements multiples
    bool paymentProcessed = false;
    bool dialogClosed = false;

    // États de debug
    final RxString debugStatus = 'Initialisation...'.obs;
    final RxBool isCheckingPayment = false.obs;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de chargement
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Traitement du paiement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Veuillez finaliser votre paiement dans l\'onglet Stripe qui s\'est ouvert.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fenêtre se fermera automatiquement une fois le paiement confirmé.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Obx(() => Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debugStatus.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    subscription?.cancel();
                    paymentIntentSubscription?.cancel();
                    estabSubscription?.cancel();
                    timeoutTimer?.cancel();
                    pollingTimer?.cancel();
                    dialogClosed = true;
                    Get.back();
                    UniquesControllers().data.snackbar(
                          'Paiement annulé',
                          'Vous pourrez réessayer plus tard',
                          true,
                        );
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Fonction pour vérifier que le paiement est vraiment réussi
    Future<bool> verifyPaymentSuccess(DocumentSnapshot sessionDoc) async {
      if (!sessionDoc.exists) return false;

      final data = sessionDoc.data() as Map<String, dynamic>;

      // Vérifier plusieurs champs pour s'assurer du succès
      final paymentStatus = data['payment_status'] as String?;
      final status = data['status'] as String?;
      final amountTotal = data['amount_total'] as int?;
      final paymentIntent = data['payment_intent'] as String?;
      final subscription = data['subscription'] as String?;

      // Le paiement est réussi si :
      // 1. payment_status est 'paid' ou 'succeeded'
      // 2. OU status est 'complete' ou 'paid'
      // 3. ET il y a un montant
      // 4. ET il y a soit un payment_intent soit une subscription

      final isPaid =
          (paymentStatus == 'paid' || paymentStatus == 'succeeded') ||
              (status == 'complete' || status == 'paid');
      final hasAmount = amountTotal != null && amountTotal > 0;
      final hasPaymentProof = paymentIntent != null || subscription != null;

      return isPaid && hasAmount && hasPaymentProof;
    }

    // Écouter les changements de la session
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugStatus.value = 'Connexion à Stripe...';

      // Timeout de 5 minutes
      timeoutTimer = Timer(Duration(minutes: 5), () {
        if (!paymentProcessed && !dialogClosed) {
          subscription?.cancel();
          paymentIntentSubscription?.cancel();
          estabSubscription?.cancel();
          pollingTimer?.cancel();
          Get.back();
          UniquesControllers().data.snackbar(
                'Temps écoulé',
                'Le délai de paiement a expiré. Veuillez réessayer.',
                true,
              );
        }
      });

      // Écouter spécifiquement les changements de la session
      subscription = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && !paymentProcessed && !dialogClosed) {
          final data = snapshot.data()!;

          // Debug
          print('📘 Session mise à jour:');
          print('   - payment_status: ${data['payment_status']}');
          print('   - status: ${data['status']}');
          print('   - amount_total: ${data['amount_total']}');

          debugStatus.value =
              'Statut: ${data['payment_status'] ?? data['status'] ?? 'en attente'}';

          // Vérifier si c'est vraiment un succès
          if (await verifyPaymentSuccess(snapshot)) {
            paymentProcessed = true;
            debugStatus.value = '✅ Paiement confirmé!';

            print('✅ Paiement réussi confirmé!');

            // Attendre un peu pour l'affichage
            await Future.delayed(Duration(seconds: 1));

            // Nettoyer et fermer
            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              await _ensureEstablishmentActivated();
              _handlePaymentSuccess();
            }
          }

          // Vérifier si c'est une annulation
          if (data['status'] == 'expired' || data['status'] == 'canceled') {
            debugStatus.value = '❌ Paiement annulé';
            print('❌ Paiement annulé ou expiré');

            subscription?.cancel();
            paymentIntentSubscription?.cancel();
            estabSubscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              UniquesControllers().data.snackbar(
                    'Paiement annulé',
                    'Le paiement a été annulé ou a expiré',
                    true,
                  );
            }
          }
        }
      });

      // Vérification périodique toutes les 3 secondes
      pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        if (!isCheckingPayment.value && !paymentProcessed && !dialogClosed) {
          isCheckingPayment.value = true;

          try {
            final sessionDoc = await UniquesControllers()
                .data
                .firebaseFirestore
                .collection('customers')
                .doc(user.uid)
                .collection('checkout_sessions')
                .doc(sessionId)
                .get();

            if (await verifyPaymentSuccess(sessionDoc)) {
              paymentProcessed = true;
              timer.cancel();

              subscription?.cancel();
              paymentIntentSubscription?.cancel();
              estabSubscription?.cancel();
              timeoutTimer?.cancel();

              if (!dialogClosed) {
                Get.back();
                await _ensureEstablishmentActivated();
                _handlePaymentSuccess();
              }
            }
          } catch (e) {
            print('Erreur vérification: $e');
          } finally {
            isCheckingPayment.value = false;
          }
        }
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
                      color: Colors.white,
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
