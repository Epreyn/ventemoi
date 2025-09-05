# Patch Notes - Version 1.9.7

## 🎉 Nouvelles fonctionnalités

### Système de devis complet
- **Nouveau bouton "Demander un devis"** sur les fiches entreprises partenaires (remplace le bouton Simulateur)
- **Page Devis dédiée** accessible depuis le menu sous "Explorer"
  - Onglet "Mes demandes" : visualisation des devis envoyés
  - Onglet "Demandes reçues" : pour les entreprises recevant des devis
  - Onglet "Nouveau devis" : formulaire général pour demandes à l'admin
- **Simulateur de points intégré** dans le formulaire de devis
- **Bouton "Recevez vos points"** avec guide explicatif
- **Système de réclamation de points** après signature du devis (1% du montant)
- **Compteur de demandes par entreprise** pour statistiques et suivi

### Améliorations du shop
- **Slider pour l'achat de bons** : sélection visuelle de 1 à 4 bons maximum
- **Calcul automatique du total** avec affichage du solde en temps réel
- **Indicateur coloré** : vert si solde suffisant, rouge sinon
- **Taille maximale des cartes** : amélioration du responsive
  - Tablette (600-900px) : max 350px par carte
  - Petit desktop (900-1400px) : max 380px par carte
  - Grand desktop (1400px+) : max 420px par carte

## 🐛 Corrections de bugs

### Connexion et authentification
- **Correction du bug "Type utilisateur inconnu"** pour les Sponsors et Associations
- **Routing correct** après connexion pour tous les types d'utilisateurs
- **Interface responsive améliorée** sur l'écran de connexion :
  - "Se souvenir de moi" et "Mot de passe oublié" s'adaptent sur mobile
  - Disposition en colonne sur petits écrans (<400px)
  - Aucun chevauchement de texte

### Système de parrainage
- **Affichage correct des filleuls** : les parrains inscrits apparaissent maintenant
- **Compteur de parrains fonctionnel** : distinction claire entre actifs et en attente
- **Attribution automatique des points** :
  - 100 points à l'inscription d'une entreprise/boutique parrainée
  - 50 points sur chaque achat effectué par un filleul
- **Historique complet** des gains de parrainage

### Interface et affichage
- **Menu fonctionnel** sur la page Devis
- **Suppression du bouton FAB vide** sur la page des devis
- **Formulaire de devis réinitialisé** à chaque ouverture
- **Écran de chargement restauré** avec le logo correct

### Affichage des prix
- **Prix affichés en TTC** en priorité (HT entre parenthèses)
- **Clarification TVA** : tous les montants incluent la TVA de 20%
- **Montants Stripe corrigés** : 
  - Adhésion : 324€ TTC (270€ HT)
  - Mensuel : 66€ TTC/mois (55€ HT)
  - Annuel : 1044€ TTC/an (870€ HT)

### Panel administrateur
- **Offres visibles** dans le panel admin (correction du bug d'affichage vide)
- **Système d'approbation/rejet** des demandes de bannières publicitaires
- **Gestion des demandes en attente** avec workflow complet

## 💡 Améliorations UX

### Achats et paiements
- **Interface d'achat améliorée** avec slider visuel pour sélectionner le nombre de bons
- **Feedback visuel immédiat** sur la disponibilité des points
- **Processus d'achat simplifié** avec actionBottomSheet fonctionnel

### Navigation
- **Menu Devis ajouté** dans la navigation latérale pour tous les utilisateurs
- **Transitions fluides** entre les différentes sections
- **Responsive optimisé** pour toutes les tailles d'écran

## 🔧 Optimisations techniques

- Amélioration des performances de chargement
- Réduction des requêtes Firestore inutiles
- Meilleure gestion des états avec GetX
- Code refactorisé pour une meilleure maintenabilité

## 📝 Notes pour les développeurs

- Les price IDs Stripe doivent être mis à jour dans le dashboard pour refléter les prix TTC
- Le système de devis utilise une nouvelle collection `quote_requests` dans Firestore
- Les statistiques de parrainage sont maintenant stockées dans `sponsorship_details`

---

*Version déployée le : [Date du déploiement]*
*Build : 1.9.7*