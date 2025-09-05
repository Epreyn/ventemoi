# Configuration des Produits Stripe pour VenteMoi

## 🔧 Configuration Stripe
Date de création : 2025-01-05
Version : 2.0

---

## 📋 PRODUITS À CRÉER DANS STRIPE DASHBOARD

### 1. ADHÉSION ET ABONNEMENTS

#### 1.1 Adhésion Initiale (One-time)
```
Nom : Adhésion VenteMoi Pro
Product ID : prod_adhesion_pro
Price ID : price_adhesion_pro_270
Montant : 270.00 € HT
Type : Paiement unique
Description : Frais d'adhésion unique pour les entreprises et commerçants
```

#### 1.2 Cotisation Annuelle (Subscription)
```
Nom : Cotisation Annuelle VenteMoi Pro
Product ID : prod_cotisation_annuelle
Price ID : price_cotisation_annuelle_600
Montant : 600.00 € HT/an
Type : Abonnement récurrent annuel
Description : Cotisation annuelle incluant toutes les fonctionnalités de base
```

#### 1.3 Cotisation Mensuelle (Subscription)
```
Nom : Cotisation Mensuelle VenteMoi Pro
Product ID : prod_cotisation_mensuelle
Price ID : price_cotisation_mensuelle_55
Montant : 55.00 € HT/mois
Type : Abonnement récurrent mensuel
Description : Cotisation mensuelle incluant toutes les fonctionnalités de base
```

### 2. OPTIONS ENTREPRISES

#### 2.1 Slot Catégorie Supplémentaire
```
Nom : Slot Catégorie Supplémentaire
Product ID : prod_slot_supplementaire
Price ID : price_slot_supplementaire_50
Montant : 50.00 € HT
Type : Paiement unique
Description : Permet d'ajouter une catégorie métier supplémentaire
Metadata : 
  - type: "slot_category"
  - quantity_unit: "1"
```

#### 2.2 Commission Visibilité (Variable)
```
Nom : Commission Visibilité Augmentée
Product ID : prod_commission_visibilite
Description : Commission variable à partir de 1% pour augmenter la visibilité
Note : À implémenter via API avec montant dynamique
Metadata :
  - type: "visibility_boost"
  - commission_rate: "variable"
  - cashback_bonus: "0.5%" (50% redistribué au client)
```

### 3. OFFRES SPONSORS

#### 3.1 Sponsor Bronze
```
Nom : Sponsor Bronze VenteMoi
Product ID : prod_sponsor_bronze
Price ID : price_sponsor_bronze_300
Montant : 300.00 € HT
Type : Paiement unique
Description : 
  • 1 bon cadeau de 50€ TTC offert
  • Mise en avant réseaux sociaux
  • Logo sur l'application et le site
Metadata :
  - type: "sponsor"
  - level: "bronze"
  - vouchers_included: "1"
  - voucher_value: "50"
```

#### 3.2 Sponsor Silver
```
Nom : Sponsor Silver VenteMoi
Product ID : prod_sponsor_silver
Price ID : price_sponsor_silver_800
Montant : 800.00 € HT
Type : Paiement unique
Description :
  • 3 bons cadeaux de 50€ TTC offerts
  • 2 mises en avant réseaux sociaux
  • 1 vidéo standard incluse
  • Visibilité Prestige sur l'application
Metadata :
  - type: "sponsor"
  - level: "silver"
  - vouchers_included: "3"
  - voucher_value: "50"
  - video_included: "standard"
```

### 4. PRESTATIONS VIDÉO

#### 4.1 Vidéo Standard
```
Nom : Vidéo Standard Membre
Product ID : prod_video_standard_membre
Price ID : price_video_standard_membre_210
Montant : 210.00 € HT (INCLUS dans le forfait de base)
Type : Paiement unique
Description :
  • Tournage 1h30
  • Vidéo 30 secondes
  • Format vertical
  • Montage simple
Metadata :
  - type: "video"
  - level: "standard"
  - customer_type: "member"
```

```
Nom : Vidéo Standard Public
Product ID : prod_video_standard_public
Price ID : price_video_standard_public_300
Montant : 300.00 € HT
Type : Paiement unique
Description : Même prestation pour non-membres
Metadata :
  - type: "video"
  - level: "standard"
  - customer_type: "public"
```

#### 4.2 Vidéo Premium
```
Nom : Vidéo Premium Membre
Product ID : prod_video_premium_membre
Price ID : price_video_premium_membre_420
Montant : 420.00 € HT (630€ - 210€ inclus)
Type : Paiement unique
Description :
  • Tournage 1/2 journée
  • Vidéo ~1 minute
  • 1 plan drone inclus
  • Montage et colorimétrie avancés
Metadata :
  - type: "video"
  - level: "premium"
  - customer_type: "member"
  - includes_drone: "true"
```

```
Nom : Vidéo Premium Public
Product ID : prod_video_premium_public
Price ID : price_video_premium_public_900
Montant : 900.00 € HT
Type : Paiement unique
Metadata :
  - type: "video"
  - level: "premium"
  - customer_type: "public"
```

#### 4.3 Vidéo Signature
```
Nom : Vidéo Signature Membre
Product ID : prod_video_signature_membre
Price ID : price_video_signature_membre_840
Montant : 840.00 € HT (1050€ - 210€ inclus)
Type : Paiement unique
Description :
  • Tournage 6 heures
  • Vidéo ~1min30 avec storytelling
  • Plans drone multiples
  • Étalonnage complet
  • Interview intégrée
Metadata :
  - type: "video"
  - level: "signature"
  - customer_type: "member"
```

```
Nom : Vidéo Signature Public
Product ID : prod_video_signature_public
Price ID : price_video_signature_public_1500
Montant : 1500.00 € HT
Type : Paiement unique
Metadata :
  - type: "video"
  - level: "signature"
  - customer_type: "public"
```

### 5. PUBLICITÉ

#### 5.1 Bandeau Offres du Moment
```
Nom : Bandeau Publicitaire Hebdomadaire
Product ID : prod_bandeau_hebdo
Price ID : price_bandeau_hebdo_50
Montant : 50.00 € HT
Type : Paiement unique
Description : Affichage dans le bandeau "Offres du moment" pendant 1 semaine
Metadata :
  - type: "advertising"
  - duration: "7_days"
  - placement: "banner"
```

---

## 🛠️ COMMANDES STRIPE CLI

### Créer les produits via CLI :

```bash
# 1. ADHÉSION
stripe products create \
  --name="Adhésion VenteMoi Pro" \
  --description="Frais d'adhésion unique pour les entreprises et commerçants"

stripe prices create \
  --product="prod_xxx" \
  --unit-amount=27000 \
  --currency=eur \
  --tax-behavior=exclusive

# 2. COTISATION ANNUELLE
stripe products create \
  --name="Cotisation Annuelle VenteMoi Pro" \
  --description="Cotisation annuelle incluant toutes les fonctionnalités de base"

stripe prices create \
  --product="prod_xxx" \
  --unit-amount=60000 \
  --currency=eur \
  --recurring[interval]=year \
  --tax-behavior=exclusive

# 3. COTISATION MENSUELLE
stripe products create \
  --name="Cotisation Mensuelle VenteMoi Pro" \
  --description="Cotisation mensuelle incluant toutes les fonctionnalités de base"

stripe prices create \
  --product="prod_xxx" \
  --unit-amount=5500 \
  --currency=eur \
  --recurring[interval]=month \
  --tax-behavior=exclusive

# (Continuer pour chaque produit...)
```

---

## 📝 MISE À JOUR DU CODE

### 1. Fichier de configuration des prix
Créer `/lib/core/constants/stripe_prices.dart` :

```dart
class StripePrices {
  // Adhésion et Abonnements
  static const String adhesionProPrice = 'price_adhesion_pro_270';
  static const String cotisationAnnuellePrice = 'price_cotisation_annuelle_600';
  static const String cotisationMensuellePrice = 'price_cotisation_mensuelle_55';
  
  // Options
  static const String slotSupplementairePrice = 'price_slot_supplementaire_50';
  
  // Sponsors
  static const String sponsorBronzePrice = 'price_sponsor_bronze_300';
  static const String sponsorSilverPrice = 'price_sponsor_silver_800';
  
  // Vidéos Membres
  static const String videoStandardMembrePrice = 'price_video_standard_membre_210';
  static const String videoPremiumMembrePrice = 'price_video_premium_membre_420';
  static const String videoSignatureMembrePrice = 'price_video_signature_membre_840';
  
  // Vidéos Public
  static const String videoStandardPublicPrice = 'price_video_standard_public_300';
  static const String videoPremiumPublicPrice = 'price_video_premium_public_900';
  static const String videoSignaturePublicPrice = 'price_video_signature_public_1500';
  
  // Publicité
  static const String bandeauHebdoPrice = 'price_bandeau_hebdo_50';
  
  // Montants en centimes
  static const int adhesionAmount = 27000; // 270€
  static const int cotisationAnnuelleAmount = 60000; // 600€
  static const int cotisationMensuelleAmount = 5500; // 55€
  static const int slotSupplementaireAmount = 5000; // 50€
  static const int sponsorBronzeAmount = 30000; // 300€
  static const int sponsorSilverAmount = 80000; // 800€
  static const int bandeauHebdoAmount = 5000; // 50€
}
```

### 2. Mise à jour du StripePaymentManager

Localisation : `/lib/core/services/stripe_payment_manager.dart`

Remplacer les anciens prix par les nouveaux :
- Adhésion : 270€ au lieu de 300€
- Cotisation annuelle : 600€ au lieu de 500€
- Slot supplémentaire : 50€ au lieu de 5€

### 3. Nouvelles fonctionnalités à implémenter

#### A. Gestion des Sponsors
```dart
Future<bool> purchaseSponsorPackage(String userId, String level) async {
  final priceId = level == 'bronze' 
    ? StripePrices.sponsorBronzePrice 
    : StripePrices.sponsorSilverPrice;
    
  // Créer le paiement
  // Si succès, ajouter les bons cadeaux et activer la visibilité sponsor
}
```

#### B. Gestion des Vidéos
```dart
Future<bool> purchaseVideoPackage(String userId, String level, bool isMember) async {
  // Déterminer le prix selon le niveau et le statut membre
  // Créer le paiement
  // Enregistrer la commande vidéo
}
```

#### C. Bandeau publicitaire
```dart
Future<bool> purchaseBannerAd(String establishmentId, DateTime startDate) async {
  // Paiement du bandeau
  // Programmer l'affichage pour 7 jours
}
```

---

## ⚠️ NOTES IMPORTANTES

1. **TVA** : Tous les prix sont HT, Stripe appliquera la TVA automatiquement avec `tax_behavior=exclusive`

2. **Bons cadeaux** : Les montants des bons cadeaux (50€) sont en TTC

3. **Vidéo Standard incluse** : Pour les membres, 210€ sont déjà inclus dans leur forfait

4. **Commission variable** : Nécessite une implémentation personnalisée avec montant dynamique

5. **Vidéo Événementielle** : Sur devis, nécessite un système de devis personnalisé

---

## 🚀 ÉTAPES DE DÉPLOIEMENT

1. [ ] Créer tous les produits dans Stripe Dashboard (Test puis Live)
2. [ ] Noter tous les Product IDs et Price IDs
3. [ ] Mettre à jour le fichier `stripe_prices.dart` avec les vrais IDs
4. [ ] Tester chaque flux de paiement en mode Test
5. [ ] Implémenter les nouvelles fonctionnalités (sponsors, vidéos, bandeau)
6. [ ] Migrer les anciens abonnements si nécessaire
7. [ ] Déployer en production

---

## 📊 TABLEAU RÉCAPITULATIF

| Produit | Prix HT | Type | Pour qui |
|---------|---------|------|----------|
| Adhésion | 270€ | Unique | Entreprises |
| Cotisation annuelle | 600€/an | Abonnement | Entreprises |
| Cotisation mensuelle | 55€/mois | Abonnement | Entreprises |
| Slot supplémentaire | 50€ | Unique | Entreprises |
| Sponsor Bronze | 300€ | Unique | Entreprises |
| Sponsor Silver | 800€ | Unique | Entreprises |
| Vidéo Standard | 210€/300€ | Unique | Membre/Public |
| Vidéo Premium | 420€/900€ | Unique | Membre/Public |
| Vidéo Signature | 840€/1500€ | Unique | Membre/Public |
| Bandeau hebdo | 50€ | Unique | Entreprises |

---

Dernière mise à jour : 2025-01-05