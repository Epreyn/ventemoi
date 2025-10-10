// lib/core/constants/stripe_prices.dart

class StripePrices {
  // ==================== PRODUITS ET PRIX IDS ====================
  // Note: Remplacer ces IDs par les vrais IDs Stripe après création

  // Adhésion et Abonnements
  static const String adhesionProPriceId = 'price_1S54TmAOsm6ulZWobthhVJaZ';
  static const String cotisationAnnuellePriceId =
      'price_1S54VZAOsm6ulZWoQYlK7eQB';
  static const String cotisationMensuellePriceId =
      'price_1S54WcAOsm6ulZWomfZU3J0I';

  // Options
  static const String slotSupplementairePriceId =
      'price_1S54aeAOsm6ulZWoG5ABnBwQ';

  // Sponsors
  static const String sponsorBronzePriceId = 'price_1SFFYbAOsm6ulZWoJ3gvtYWP';
  static const String sponsorSilverPriceId = 'price_1SFFdWAOsm6ulZWobgzTpU4V';

  // Vidéos Membres
  static const String videoStandardMembrePriceId =
      'price_1S54hcAOsm6ulZWoe1XMgObI';
  static const String videoPremiumMembrePriceId =
      'price_1S54jpAOsm6ulZWoKst6Zgdg';
  static const String videoSignatureMembrePriceId =
      'price_1S54m0AOsm6ulZWoFoajrBrv';

  // Vidéos Public
  static const String videoStandardPublicPriceId =
      'price_1S54ilAOsm6ulZWo5zE0XgLr';
  static const String videoPremiumPublicPriceId =
      'price_1S54kwAOsm6ulZWobX2JHTMF';
  static const String videoSignaturePublicPriceId =
      'price_1S54n5AOsm6ulZWobYpG0zz7';

  // Publicité
  static const String bandeauHebdoPriceId = 'price_1SFFeOAOsm6ulZWoL96l8tpm';

  // ==================== MONTANTS EN CENTIMES (HT) ====================

  // Adhésion et Abonnements
  static const int adhesionAmount = 27000; // 270€ HT
  static const int cotisationAnnuelleAmount = 60000; // 600€ HT
  static const int cotisationMensuelleAmount = 5500; // 55€ HT

  // Options
  static const int slotSupplementaireAmount = 5000; // 50€ HT

  // Sponsors
  static const int sponsorBronzeAmount = 36000;
  static const int sponsorSilverAmount = 96000;

  // Vidéos Membres (avec réduction de 210€)
  static const int videoStandardMembreAmount =
      21000; // 210€ HT (inclus dans forfait)
  static const int videoPremiumMembreAmount =
      42000; // 420€ HT (630€ - 210€ inclus)
  static const int videoSignatureMembreAmount =
      84000; // 840€ HT (1050€ - 210€ inclus)

  // Vidéos Public
  static const int videoStandardPublicAmount = 30000; // 300€ HT
  static const int videoPremiumPublicAmount = 90000; // 900€ HT
  static const int videoSignaturePublicAmount = 150000; // 1500€ HT

  // Publicité
  static const int bandeauHebdoAmount = 6000;

  // ==================== MONTANTS TTC (avec TVA 20%) ====================

  static int getTTCAmount(int htAmount) => (htAmount * 1.2).round();

  static const int adhesionAmountTTC = 32400; // 324€ TTC
  static const int cotisationAnnuelleAmountTTC = 72000; // 720€ TTC
  static const int cotisationMensuelleAmountTTC = 6600; // 66€ TTC
  static const int slotSupplementaireAmountTTC = 6000; // 60€ TTC

  // ==================== CALCULS FORFAITS ====================

  // Forfait première année (adhésion + vidéo standard + cotisation)
  static const int forfaitPremierAnneeHT = adhesionAmount +
      videoStandardMembreAmount +
      cotisationAnnuelleAmount; // 1080€ HT
  static const int forfaitPremierAnnuelleTTC = 129600; // 1296€ TTC

  // Forfait mensuel première année
  static const int forfaitPremierMensuelHT = adhesionAmount +
      videoStandardMembreAmount +
      (cotisationMensuelleAmount * 12); // 1140€ HT
  static const int forfaitPremierMensuelTTC = 136800; // 1368€ TTC

  // ==================== DESCRIPTIONS ====================

  static const Map<String, String> productDescriptions = {
    'adhesion': 'Frais d\'adhésion unique pour les entreprises et commerçants',
    'cotisation_annuelle':
        'Cotisation annuelle incluant toutes les fonctionnalités de base',
    'cotisation_mensuelle':
        'Cotisation mensuelle incluant toutes les fonctionnalités de base',
    'slot_supplementaire':
        'Permet d\'ajouter une catégorie métier supplémentaire',
    'sponsor_bronze':
        '1 bon cadeau 50€ + Mise en avant réseaux sociaux + Logo sur l\'application',
    'sponsor_silver':
        '3 bons cadeaux 50€ + 2 mises en avant + Vidéo standard incluse + Visibilité Prestige',
    'video_standard':
        'Vidéo 30s - Tournage 1h30 - Format vertical - Montage simple',
    'video_premium':
        'Vidéo 1min - Tournage 1/2 journée - Plan drone - Montage avancé',
    'video_signature':
        'Vidéo 1min30 - Tournage 6h - Plans drone multiples - Storytelling soigné',
    'bandeau_hebdo':
        'Affichage dans le bandeau "Offres du moment" pendant 7 jours',
  };

  // ==================== MÉTADONNÉES SPONSORS ====================

  static const Map<String, dynamic> sponsorBronzeMetadata = {
    'type': 'sponsor',
    'level': 'bronze',
    'vouchers_included': 1,
    'voucher_value': 50,
    'social_media_boost': true,
    'logo_display': true,
  };

  static const Map<String, dynamic> sponsorSilverMetadata = {
    'type': 'sponsor',
    'level': 'silver',
    'vouchers_included': 3,
    'voucher_value': 50,
    'social_media_boost': 2,
    'video_included': 'standard',
    'prestige_visibility': true,
  };
}
