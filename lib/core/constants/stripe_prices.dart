// lib/core/constants/stripe_prices.dart

class StripePrices {
  // ==================== PRODUITS ET PRIX IDS ====================
  // Note: Remplacer ces IDs par les vrais IDs Stripe après création
  
  // Adhésion et Abonnements
  static const String adhesionProPriceId = 'price_adhesion_pro_270';
  static const String cotisationAnnuellePriceId = 'price_cotisation_annuelle_600';
  static const String cotisationMensuellePriceId = 'price_cotisation_mensuelle_55';
  
  // Options
  static const String slotSupplementairePriceId = 'price_slot_supplementaire_50';
  
  // Sponsors
  static const String sponsorBronzePriceId = 'price_sponsor_bronze_300';
  static const String sponsorSilverPriceId = 'price_sponsor_silver_800';
  
  // Vidéos Membres
  static const String videoStandardMembrePriceId = 'price_video_standard_membre_210';
  static const String videoPremiumMembrePriceId = 'price_video_premium_membre_420';
  static const String videoSignatureMembrePriceId = 'price_video_signature_membre_840';
  
  // Vidéos Public
  static const String videoStandardPublicPriceId = 'price_video_standard_public_300';
  static const String videoPremiumPublicPriceId = 'price_video_premium_public_900';
  static const String videoSignaturePublicPriceId = 'price_video_signature_public_1500';
  
  // Publicité
  static const String bandeauHebdoPriceId = 'price_bandeau_hebdo_50';
  
  // ==================== MONTANTS EN CENTIMES (HT) ====================
  
  // Adhésion et Abonnements
  static const int adhesionAmount = 27000; // 270€ HT
  static const int cotisationAnnuelleAmount = 60000; // 600€ HT
  static const int cotisationMensuelleAmount = 5500; // 55€ HT
  
  // Options
  static const int slotSupplementaireAmount = 5000; // 50€ HT
  
  // Sponsors
  static const int sponsorBronzeAmount = 30000; // 300€ HT
  static const int sponsorSilverAmount = 80000; // 800€ HT
  
  // Vidéos Membres (avec réduction de 210€)
  static const int videoStandardMembreAmount = 21000; // 210€ HT (inclus dans forfait)
  static const int videoPremiumMembreAmount = 42000; // 420€ HT (630€ - 210€ inclus)
  static const int videoSignatureMembreAmount = 84000; // 840€ HT (1050€ - 210€ inclus)
  
  // Vidéos Public
  static const int videoStandardPublicAmount = 30000; // 300€ HT
  static const int videoPremiumPublicAmount = 90000; // 900€ HT
  static const int videoSignaturePublicAmount = 150000; // 1500€ HT
  
  // Publicité
  static const int bandeauHebdoAmount = 5000; // 50€ HT
  
  // ==================== MONTANTS TTC (avec TVA 20%) ====================
  
  static int getTTCAmount(int htAmount) => (htAmount * 1.2).round();
  
  static const int adhesionAmountTTC = 32400; // 324€ TTC
  static const int cotisationAnnuelleAmountTTC = 72000; // 720€ TTC
  static const int cotisationMensuelleAmountTTC = 6600; // 66€ TTC
  static const int slotSupplementaireAmountTTC = 6000; // 60€ TTC
  
  // ==================== CALCULS FORFAITS ====================
  
  // Forfait première année (adhésion + vidéo standard + cotisation)
  static const int forfaitPremierAnneeHT = adhesionAmount + videoStandardMembreAmount + cotisationAnnuelleAmount; // 1080€ HT
  static const int forfaitPremierAnnuelleTTC = 129600; // 1296€ TTC
  
  // Forfait mensuel première année
  static const int forfaitPremierMensuelHT = adhesionAmount + videoStandardMembreAmount + (cotisationMensuelleAmount * 12); // 1140€ HT
  static const int forfaitPremierMensuelTTC = 136800; // 1368€ TTC
  
  // ==================== DESCRIPTIONS ====================
  
  static const Map<String, String> productDescriptions = {
    'adhesion': 'Frais d\'adhésion unique pour les entreprises et commerçants',
    'cotisation_annuelle': 'Cotisation annuelle incluant toutes les fonctionnalités de base',
    'cotisation_mensuelle': 'Cotisation mensuelle incluant toutes les fonctionnalités de base',
    'slot_supplementaire': 'Permet d\'ajouter une catégorie métier supplémentaire',
    'sponsor_bronze': '1 bon cadeau 50€ + Mise en avant réseaux sociaux + Logo sur l\'application',
    'sponsor_silver': '3 bons cadeaux 50€ + 2 mises en avant + Vidéo standard incluse + Visibilité Prestige',
    'video_standard': 'Vidéo 30s - Tournage 1h30 - Format vertical - Montage simple',
    'video_premium': 'Vidéo 1min - Tournage 1/2 journée - Plan drone - Montage avancé',
    'video_signature': 'Vidéo 1min30 - Tournage 6h - Plans drone multiples - Storytelling soigné',
    'bandeau_hebdo': 'Affichage dans le bandeau "Offres du moment" pendant 7 jours',
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