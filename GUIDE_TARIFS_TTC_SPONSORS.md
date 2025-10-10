# Guide : Afficher les tarifs sponsors en TTC sur Stripe

## Problème identifié

Les tarifs des sponsors s'affichent en HT (Hors Taxes) sur la page de paiement Stripe au lieu de TTC (Toutes Taxes Comprises).

**Localisation du problème :**
- Fichier : `lib/core/constants/stripe_prices.dart` (lignes 52-53)
- Les montants utilisés sont en HT : 300€ et 800€ au lieu de 360€ et 960€ TTC

## Solution 1 : Modifier le code Flutter (Recommandé)

### Étape 1 : Modifier les montants dans le code

Dans le fichier `lib/core/constants/stripe_prices.dart`, remplacer :

```dart
// AVANT (HT)
static const int sponsorBronzeAmount = 30000; // 300€ HT
static const int sponsorSilverAmount = 80000; // 800€ HT
```

Par :

```dart
// APRÈS (TTC)
static const int sponsorBronzeAmount = 36000; // 360€ TTC (300€ HT + 20% TVA)
static const int sponsorSilverAmount = 96000; // 960€ TTC (800€ HT + 20% TVA)
```

### Étape 2 : Mettre à jour les commentaires

Modifier également les commentaires pour refléter le changement :

```dart
// Sponsors TTC (TVA 20% incluse)
static const int sponsorBronzeAmount = 36000; // 360€ TTC
static const int sponsorSilverAmount = 96000; // 960€ TTC
```

## Solution 2 : Modifier la configuration Stripe

Si vous préférez modifier directement dans Stripe :

### Étape 1 : Accéder au Dashboard Stripe
1. Connectez-vous à votre compte Stripe
2. Allez dans **Produits** → **Catalogue de produits**

### Étape 2 : Modifier les prix des sponsors
1. Trouvez le produit "Sponsor Bronze" (ID: `price_1S54f2AOsm6ulZWodQHT28kk`)
   - Changer le prix de **300€** à **360€**

2. Trouvez le produit "Sponsor Silver" (ID: `price_1S54gCAOsm6ulZWoPGzGEfnB`)
   - Changer le prix de **800€** à **960€**

### Étape 3 : Créer de nouveaux Price IDs
Stripe ne permet pas de modifier les prix existants. Vous devrez :

1. **Créer de nouveaux prix** avec les montants TTC
2. **Récupérer les nouveaux Price IDs**
3. **Mettre à jour le code** avec les nouveaux IDs :

```dart
// Dans stripe_prices.dart
static const String sponsorBronzePriceId = 'NOUVEAU_PRICE_ID_BRONZE_TTC';
static const String sponsorSilverPriceId = 'NOUVEAU_PRICE_ID_SILVER_TTC';
```

## Calculs de conversion HT → TTC

Pour référence, voici les conversions avec une TVA de 20% :

| Produit | Prix HT | TVA (20%) | Prix TTC |
|---------|---------|-----------|----------|
| Sponsor Bronze | 300€ | 60€ | **360€** |
| Sponsor Silver | 800€ | 160€ | **960€** |

## Recommandation

**Utilisez la Solution 1** (modification du code) car :
- ✅ Plus simple à implémenter
- ✅ Pas besoin de créer de nouveaux produits Stripe
- ✅ Changement immédiat
- ✅ Conserve la cohérence avec les autres tarifs du système

## Après modification

Une fois les changements effectués :
1. **Testez** le processus de paiement sponsor
2. **Vérifiez** que les montants affichés sur Stripe correspondent aux prix TTC
3. **Documentez** le changement dans vos notes de version

## Note importante

Cette modification affectera uniquement l'affichage des prix sur Stripe. Assurez-vous que :
- Vos factures et comptabilité sont à jour
- Les métadonnées et descriptions des produits mentionnent "TTC"
- Les utilisateurs sont informés du changement si nécessaire