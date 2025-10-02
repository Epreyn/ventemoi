#!/bin/bash

echo "🚀 Déploiement des Cloud Functions pour l'email de vérification personnalisé"
echo "==========================================================================="

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les erreurs
error() {
    echo -e "${RED}❌ Erreur: $1${NC}"
    exit 1
}

# Fonction pour afficher les succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher les warnings
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    error "Firebase CLI n'est pas installé. Installez-le avec: npm install -g firebase-tools"
fi

# Vérifier qu'on est dans le bon dossier
if [ ! -f "package.json" ]; then
    error "Ce script doit être exécuté depuis le dossier functions/"
fi

echo ""
echo "📋 Étapes du déploiement:"
echo "1. Installation des dépendances"
echo "2. Déploiement des nouvelles fonctions"
echo "3. Configuration Firebase"
echo ""

# Étape 1: Installation des dépendances
echo "📦 Installation des dépendances..."
npm install

if [ $? -ne 0 ]; then
    error "L'installation des dépendances a échoué"
fi
success "Dépendances installées"

# Étape 2: Déployer uniquement les fonctions d'email
echo ""
echo "🔄 Déploiement des fonctions..."
echo "Fonctions à déployer:"
echo "  - sendCustomVerificationEmail (trigger auth)"
echo "  - resendVerificationEmail (callable)"
echo "  - testVerificationEmail (HTTP)"

firebase deploy --only functions:sendCustomVerificationEmail,functions:resendVerificationEmail,functions:testVerificationEmail

if [ $? -ne 0 ]; then
    error "Le déploiement a échoué"
fi

success "Fonctions déployées avec succès!"

# Étape 3: Instructions post-déploiement
echo ""
echo "=========================================="
echo "📝 ACTIONS REQUISES DANS FIREBASE CONSOLE"
echo "=========================================="
echo ""
echo "1. Désactiver l'email Firebase par défaut :"
echo "   ➡️ Authentication > Templates"
echo "   ➡️ Décochez 'Envoyer automatiquement'"
echo ""
echo "2. Vérifier l'extension Email :"
echo "   ➡️ Extensions > Trigger Email"
echo "   ➡️ Vérifiez qu'elle est bien configurée"
echo ""
echo "3. Tester le template :"
echo "   ➡️ https://us-central1-ventemoi.cloudfunctions.net/testVerificationEmail?secret=ventemoi2024"
echo ""
echo "=========================================="

# URL de test
echo ""
warning "Pour tester l'email de vérification :"
echo "curl https://europe-west1-ventemoi.cloudfunctions.net/testVerificationEmail?email=test@example.com&name=Test%20User&secret=ventemoi2024"

echo ""
success "Déploiement terminé avec succès! 🎉"
echo ""
echo "📊 Monitoring :"
echo "firebase functions:log --only sendCustomVerificationEmail,resendVerificationEmail"
echo ""