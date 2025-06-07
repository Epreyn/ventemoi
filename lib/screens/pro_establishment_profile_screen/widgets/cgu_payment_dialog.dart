import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';

class CGUPaymentDialog extends StatefulWidget {
  final Future<void> Function(String paymentOption) onConfirm;
  final String userType;

  const CGUPaymentDialog({
    super.key,
    required this.onConfirm,
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
      case 'Commerçant':
      case 'Entreprise':
        if (selectedPaymentOption.value == 'annual') {
          return '870'; // 450€ adhésion + 420€ cotisation annuelle
        } else {
          return '930'; // 450€ adhésion + 40€/mois x 12
        }
      default:
        return '0';
    }
  }

  String get monthlyPriceAfterFirstYear {
    switch (widget.userType) {
      case 'Boutique':
      case 'Commerçant':
      case 'Entreprise':
        return selectedPaymentOption.value == 'annual' ? '540' : '50';
      case 'Association':
        return '0';
      default:
        return '0';
    }
  }

  String get paymentSchedule {
    if (selectedPaymentOption.value == 'annual') {
      return 'Paiement annuel';
    } else {
      return 'Paiement mensuel';
    }
  }

  // CGU content
  final String cguContent = '''
CONDITIONS GÉNÉRALES D'UTILISATION - VENTEMOI

Article 1 : Objet
Les présentes Conditions Générales d'Utilisation (CGU) régissent l'utilisation de la plateforme VenteMoi par les établissements professionnels (boutiques, commerçants, entreprises, associations).

Article 2 : Inscription et Abonnement

2.1 Tarifs d'abonnement (HT) :

ENTREPRISES / COMMERÇANTS / BOUTIQUES
• 1ère année :
  - Option annuelle : 870€ HT (450€ adhésion + vidéo + 420€ cotisation annuelle)
  - Option mensuelle : 930€ HT (450€ adhésion + vidéo + 40€/mois)
  - Bon cadeau de bienvenue : 50€ TTC offert

• À partir de la 2ème année :
  - Option annuelle : 540€ HT/an (45€/mois)
  - Option mensuelle : 50€ HT/mois (600€/an)

ASSOCIATIONS
• Adhésion gratuite
• Visible sur l'application à partir de 15 filleuls
• Bon cadeau de 50€ TTC à partir de 30 filleuls

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
                                  : 'Étape 2/2 : Paiement',
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
                  // Payment Step
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(
                      UniquesControllers().data.baseSpace * 2.5,
                    ),
                    child: Column(
                      children: [
                        // Option de paiement
                        if (widget.userType != 'Association') ...[
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choisissez votre mode de paiement',
                                  style: TextStyle(
                                    fontSize:
                                        UniquesControllers().data.baseSpace *
                                            1.8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 2),
                                Obx(() => Column(
                                      children: [
                                        _buildPaymentOption(
                                          value: 'monthly',
                                          title: 'Paiement mensuel',
                                          price: '40€ HT/mois',
                                          description:
                                              'Prélèvement automatique mensuel',
                                          totalFirstYear: '930€ HT',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPaymentOption(
                                          value: 'annual',
                                          title: 'Paiement annuel',
                                          price: '870€ HT/an',
                                          description:
                                              'Économisez 60€ sur la 1ère année',
                                          totalFirstYear: '870€ HT',
                                          isRecommended: true,
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                          const CustomSpace(heightMultiplier: 3),
                        ],

                        // Pricing info
                        Container(
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                CustomTheme.lightScheme()
                                    .primary
                                    .withOpacity(0.1),
                                CustomTheme.lightScheme()
                                    .primary
                                    .withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_rounded,
                                size: 48,
                                color: CustomTheme.lightScheme().primary,
                              ),
                              const CustomSpace(heightMultiplier: 2),
                              Text(
                                'Abonnement ${widget.userType}',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const CustomSpace(heightMultiplier: 1),
                              if (widget.userType != 'Association') ...[
                                Text(
                                  'Première année',
                                  style: TextStyle(
                                    fontSize:
                                        UniquesControllers().data.baseSpace *
                                            1.4,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(() => Text(
                                      '$firstYearPrice€ HT',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            3,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                      ),
                                    )),
                                const SizedBox(height: 4),
                                Obx(() => Text(
                                      selectedPaymentOption.value == 'annual'
                                          ? '(450€ adhésion + vidéo + 420€ cotisation)'
                                          : '(450€ adhésion + vidéo + 40€/mois)',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.3,
                                        color: Colors.grey[600],
                                      ),
                                    )),
                                const CustomSpace(heightMultiplier: 2),
                                Container(
                                  padding: EdgeInsets.all(
                                    UniquesControllers().data.baseSpace * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.card_giftcard_rounded,
                                            color: Colors.blue.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Bon cadeau de 50€ TTC offert',
                                            style: TextStyle(
                                              fontSize: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  1.4,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Obx(() => Text(
                                            selectedPaymentOption.value ==
                                                    'annual'
                                                ? 'Dès la 2ème année : 540€ HT/an'
                                                : 'Dès la 2ème année : 50€ HT/mois',
                                            style: TextStyle(
                                              fontSize: UniquesControllers()
                                                      .data
                                                      .baseSpace *
                                                  1.3,
                                              color: Colors.blue.shade600,
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Gratuit',
                                  style: TextStyle(
                                    fontSize:
                                        UniquesControllers().data.baseSpace * 3,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Visible à partir de 15 filleuls',
                                  style: TextStyle(
                                    fontSize:
                                        UniquesControllers().data.baseSpace *
                                            1.4,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const CustomSpace(heightMultiplier: 2),
                              Container(
                                padding: EdgeInsets.all(
                                  UniquesControllers().data.baseSpace * 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Engagement minimum 1 an',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            1.4,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Features
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inclus dans votre abonnement :',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.6,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const CustomSpace(heightMultiplier: 2),
                              _buildFeatureItem(
                                  'Fiche établissement complète avec vidéo'),
                              _buildFeatureItem(
                                  'Visibilité immédiate dans le shop'),
                              _buildFeatureItem(
                                  'Publication d\'offres et promotions illimitées'),
                              _buildFeatureItem(
                                  'Mise en avant minimum 2 fois par an'),
                              _buildFeatureItem(
                                  'Prestations vidéo à tarifs préférentiels'),
                              _buildFeatureItem(
                                  'Accès au programme ambassadeur'),
                              if (widget.userType == 'Commerçant' ||
                                  widget.userType == 'Boutique')
                                _buildFeatureItem('16 bons cadeaux de 50€ TTC'),
                            ],
                          ),
                        ),
                        const CustomSpace(heightMultiplier: 3),

                        // Payment info
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
                                      'Paiement sécurisé par Stripe',
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
                                      'Vos informations bancaires sont protégées',
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
                                    paymentProcessing.value = true;
                                    await widget
                                        .onConfirm(selectedPaymentOption.value);
                                    paymentProcessing.value = false;
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
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
                                                : 'PAYER $firstYearPrice€ HT',
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

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String price,
    required String description,
    required String totalFirstYear,
    bool isRecommended = false,
  }) {
    final isSelected = selectedPaymentOption.value == value;

    return GestureDetector(
      onTap: () => selectedPaymentOption.value = value,
      child: Container(
        padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomTheme.lightScheme().primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? CustomTheme.lightScheme().primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedPaymentOption.value,
              onChanged: (val) => selectedPaymentOption.value = val!,
              activeColor: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 1.6,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace,
                            vertical: UniquesControllers().data.baseSpace * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Recommandé',
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
                      fontSize: UniquesControllers().data.baseSpace * 1.5,
                      fontWeight: FontWeight.w700,
                      color: CustomTheme.lightScheme().primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: UniquesControllers().data.baseSpace * 1.3,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1ère année : $totalFirstYear',
                    style: TextStyle(
                      fontSize: UniquesControllers().data.baseSpace * 1.3,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: UniquesControllers().data.baseSpace * 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: UniquesControllers().data.baseSpace * 1.4,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
