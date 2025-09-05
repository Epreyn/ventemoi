# Mise à jour des Tarifs VenteMoi - Changelog

Date : 2025-01-05

## 📋 Résumé des modifications

### 1. Fichiers créés

- `STRIPE_PRODUCTS_SETUP.md` : Guide complet pour configurer les produits Stripe
- `lib/core/constants/stripe_prices.dart` : Constantes centralisées pour tous les prix
- `lib/core/services/sponsor_video_service.dart` : Service pour gérer sponsors, vidéos et publicités

### 2. Tarifs mis à jour dans le code

#### Adhésion et Cotisations
- **Adhésion** : ~~300€~~ → **270€ HT** ✅
- **Cotisation annuelle** : ~~500€~~ → **600€ HT** ✅
- **Cotisation mensuelle** : **55€ HT** (inchangé) ✅

#### Options
- **Slot supplémentaire** : ~~5€~~ → **50€ HT** ✅

### 3. Nouveaux produits ajoutés

#### Packs Sponsors
- **Bronze (300€ HT)** : 1 bon cadeau 50€ + visibilité
- **Silver (800€ HT)** : 3 bons cadeaux 50€ + vidéo standard + visibilité premium

#### Prestations Vidéo
- **Standard** : 210€ HT (membres) / 300€ HT (public)
- **Premium** : 420€ HT (membres) / 900€ HT (public)
- **Signature** : 840€ HT (membres) / 1500€ HT (public)

#### Publicité
- **Bandeau hebdomadaire** : 50€ HT

## 🔧 Fichiers modifiés

1. `/lib/screens/pro_establishment_profile_screen/controllers/pro_establishment_profile_screen_controller.dart`
   - Ligne 80 : `additionalSlotPrice = 5000` (50€)
   - Ligne 850 : Description mise à jour

2. `/lib/screens/pro_establishment_profile_screen/widgets/entreprise_category_slot_widget.dart`
   - Ligne 87 : "50€ HT/slot"
   - Ligne 157 : "Ajouter un slot (50€ HT)"

3. `/lib/screens/pro_establishment_profile_screen/widgets/cgu_payment_dialog.dart`
   - Ligne 91 : Forfait annuel 1080€ HT
   - Ligne 92 : Forfait mensuel 1140€ HT

## 🚀 Prochaines étapes

### À faire dans Stripe Dashboard :

1. **Créer les produits** dans l'environnement de test
2. **Noter les IDs** des produits et prix
3. **Mettre à jour** `stripe_prices.dart` avec les vrais IDs
4. **Tester** chaque flux de paiement

### À implémenter côté frontend :

1. **Page Sponsors** : Interface pour choisir Bronze ou Silver
2. **Page Vidéos** : Catalogue des prestations avec comparatif
3. **Bandeau publicitaire** : Calendrier de réservation
4. **Dashboard Pro** : Afficher les commandes et statuts

### Intégrations backend :

1. **Webhook Stripe** : Activer sponsors/vidéos après paiement
2. **Cron jobs** : 
   - Expiration des sponsors après 1 an
   - Activation/désactivation des bandeaux publicitaires
3. **Notifications** :
   - Email de confirmation de commande
   - Rappels pour les vidéos à planifier

## 📊 Impact sur les revenus

### Revenus potentiels mensuels (estimation)

| Produit | Prix HT | Ventes/mois | Revenu |
|---------|---------|------------|--------|
| Adhésions | 270€ | 10 | 2700€ |
| Cotisations | 600€/an | 50 actifs | 2500€ |
| Slots | 50€ | 20 | 1000€ |
| Sponsors Bronze | 300€ | 5 | 1500€ |
| Sponsors Silver | 800€ | 2 | 1600€ |
| Vidéos | Variable | 10 | 3000€ |
| Bandeaux | 50€/sem | 4 | 800€ |
| **TOTAL** | | | **13100€ HT/mois** |

## ⚠️ Points d'attention

1. **TVA** : Tous les prix sont HT, ajouter 20% pour le TTC
2. **Vidéo incluse** : 210€ déjà inclus dans le forfait première année
3. **Commission variable** : À implémenter séparément (API dynamique)
4. **Vidéo événementielle** : Sur devis uniquement

## 📝 Notes pour le déploiement

- [ ] Migrer les anciens abonnements vers les nouveaux tarifs
- [ ] Informer les clients existants des changements
- [ ] Mettre à jour la documentation commerciale
- [ ] Former l'équipe commerciale aux nouveaux tarifs

---

*Document généré automatiquement - Ne pas modifier manuellement*