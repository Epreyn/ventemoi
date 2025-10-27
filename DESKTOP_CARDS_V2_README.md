# 🎨 Cartes Desktop/Tablet V2 - Documentation

## 📋 Vue d'ensemble

Nouvelle version des cartes d'établissement optimisée pour les écrans **tablet** et **desktop**, basée sur les meilleures pratiques UX/UI 2025.

## ✨ Fonctionnalités

### Design Moderne (2025)
- ✅ **Layout vertical compact** : Image → Contenu → Actions
- ✅ **Effet hover** : Animation smooth avec élévation au survol
- ✅ **Cartes entièrement cliquables** : Meilleure accessibilité
- ✅ **Hiérarchie visuelle claire** : Badges, catégories, actions bien séparées
- ✅ **Responsive** : S'adapte à différentes tailles d'écran

### Grille Responsive
```
📱 Mobile (< 600px)     : 1 colonne  (carte verticale mobile v1)
📱 Tablet (600-1024px)  : 2 colonnes (carte desktop v2)
💻 Desktop (1024-1440px): 3 colonnes (carte desktop v2)
🖥️ Large (> 1440px)     : 4 colonnes (carte desktop v2)
```

### Espacement (basé sur design system)
- **Gap entre cartes** : 24px (1.5rem)
- **Padding grille** : 48px (3rem)
- **Padding interne carte** : 16px (1rem)

## 📁 Fichiers créés/modifiés

### Nouveau fichier
- `lib/screens/shop_establishment_screen/widgets/desktop_establishment_card_v2.dart`
  - Widget de carte optimisé desktop/tablet
  - ~700 lignes de code bien structuré
  - Commenté et documenté

### Fichiers modifiés
- `lib/screens/shop_establishment_screen/view/shop_establishment_screen.dart`
  - Import de la nouvelle carte v2
  - Mise à jour de la grille responsive (lignes 684-738)
  - Configuration des breakpoints et colonnes
  - ⚠️ NOTE : Ce fichier n'est PAS utilisé actuellement

- **`lib/screens/shop_establishment_screen/view/shop_establishment_screen_v2.dart`** ✅ FICHIER ACTIF
  - Import de la nouvelle carte v2 (ligne 14)
  - Remplacement de `UnifiedEstablishmentCard` par `DesktopEstablishmentCardV2` (ligne 544)
  - Mise à jour de la grille responsive (lignes 495-530)
  - Configuration des breakpoints et espacements optimaux

## 🎨 Caractéristiques de Design

### 1. Image Banner (160px hauteur)
- Image de fond avec gradient overlay
- Badge type en haut à gauche (SERVICE, COMMERCE, ASSO, SPONSOR)
- Logo en haut à droite (60x60px)
- Badge "bons disponibles" en bas à gauche

### 2. Header
- Nom de l'établissement (2 lignes max, bold 18px)
- Adresse avec icône location (1 ligne, 12px)

### 3. Description
- 2 lignes maximum
- Texte 13px, couleur grise
- Ellipsis overflow

### 4. Catégories
- Chips horizontaux avec wrap
- Maximum 2 catégories affichées
- Style : fond orange clair avec bordure

### 5. Footer
- Divider pour séparation claire
- Boutons contact (Appeler, Email)
- Bouton d'action principal (Acheter / Devis)

### 6. Effet Hover
- Translation -4px vers le haut
- Shadow augmentée (20px blur)
- Transition smooth 200ms
- Couleur shadow orange

## 🎯 Avantages UX/UI 2025

### Basé sur les recherches
1. **Grille modulaire** : Permet flexibilité et cohérence
2. **Espacement cohérent** : 16px base unit (1rem)
3. **Cards entièrement cliquables** : Meilleure accessibilité
4. **Hiérarchie visuelle** : Information importante en haut
5. **Hover states** : Feedback visuel immédiat
6. **Responsive breakpoints** : Standard 600px, 1024px, 1440px

### Sources de référence
- Card UI Design Best Practices 2025
- Bento Grid Layout System
- Material Design 3.0 Guidelines
- Desktop Product Card Patterns

## 🔧 Configuration Technique

### Breakpoints utilisés
```dart
isTablet       : 600px - 1024px
isSmallDesktop : 1024px - 1440px
isLargeDesktop : > 1440px
```

### Aspect Ratios
```dart
Tablet        : 0.85  (cartes plus carrées)
Small Desktop : 0.8   (légèrement plus hautes)
Large Desktop : 0.8   (idem)
```

### MaxCrossAxisExtent
```dart
Tablet        : 380px
Small Desktop : 400px
Large Desktop : 420px
```

## 🚀 Utilisation

### Hot Reload
Le code est prêt pour le hot reload. Il suffit de :
1. Sauvegarder les fichiers
2. Lancer `r` dans le terminal Flutter
3. La nouvelle grille s'affichera automatiquement sur desktop/tablet

### Basculer entre v1 et v2
La v1 (`UnifiedEstablishmentCard`) est conservée mais commentée.
Pour revenir à la v1 :
1. Décommenter l'import ligne 12
2. Remplacer `DesktopEstablishmentCardV2` par `UnifiedEstablishmentCard`

## 📊 Comparaison v1 vs v2

| Aspect | V1 | V2 |
|--------|----|----|
| Layout | Horizontal/Vertical mixte | Vertical compact |
| Hover | Basique | Animation élévation |
| Badges | Simples | Avec gradient et shadow |
| Image | Variable | Fixe 160px |
| Catégories | Liste | Chips wrappés |
| Espacement | Variable | Cohérent (24px) |
| Responsive | Bon | Excellent |
| Performance | Bonne | Optimisée |

## 🎨 Palette de Couleurs

### Badges par type
- **Service (Entreprise)** : Bleu (#2196F3)
- **Commerce** : Orange (theme.primary)
- **Association** : Vert (#4CAF50)
- **Sponsor Bronze** : #CD7F32
- **Sponsor Silver** : #C0C0C0
- **Sponsor Gold** : #FFD700

### Shadows
- **Normal** : black 0.06 opacity, 12px blur
- **Hover** : primary 0.15 opacity, 20px blur

## 🐛 Notes Importantes

### Conservé de v1
- Logique de chargement des données (user type, sponsor level, coupons)
- Gestion des callbacks (onBuy, onTap)
- Filtres et maps de catégories
- Stateful widget pour hover et data loading

### Nouveau en v2
- `MouseRegion` pour effet hover desktop
- Transform Matrix4 pour animation
- Layout vertical structuré
- Gradient overlays sur images
- Chips de catégories wrappés
- Footer avec divider

## 📈 Performance

### Optimisations
- Lazy loading des images réseau
- Caching avec ValueKey
- Minimal rebuilds (stateful widget ciblé)
- ErrorBuilder pour images manquantes

### Métriques attendues
- 60 FPS stable sur desktop
- Smooth scrolling avec 100+ cartes
- Temps de chargement < 300ms par carte

## 🔮 Évolutions Futures

### Possibles améliorations
- [ ] Animation d'apparition staggered
- [ ] Skeleton loader pendant chargement
- [ ] Filtres visuels avancés
- [ ] Mode liste/grille toggle
- [ ] Favoris avec animation
- [ ] Partage social

## 👨‍💻 Développeur

Créé par **Claude** (Assistant IA)
Date : 25 Octobre 2025
Version : 2.0.0

---

**Note** : Ce fichier sert de documentation technique. Il peut être supprimé en production.
