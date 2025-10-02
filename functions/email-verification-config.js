/**
 * Configuration pour les emails de vérification
 */

// URL de base de l'application
// IMPORTANT: Cette URL doit être ajoutée dans Firebase Console > Authentication > Authorized domains
const APP_BASE_URL = 'https://app.ventemoi.fr';

// Configuration des liens d'action email
const EMAIL_ACTION_SETTINGS = {
  // URL où rediriger après la vérification
  // Si vous utilisez une URL personnalisée, elle DOIT être dans les domaines autorisés
  url: `${APP_BASE_URL}/#/login`,

  // false = redirection vers l'URL après vérification
  // true = ouverture dans l'app mobile (dynamic links)
  handleCodeInApp: false,

  // Pour iOS (optionnel)
  iOS: {
    bundleId: 'com.ventemoi.app'
  },

  // Pour Android (optionnel)
  android: {
    packageName: 'com.ventemoi.app',
    installApp: false,
    minimumVersion: '12'
  }
};

// Configuration simplifiée sans URL de redirection
// Utilise les paramètres par défaut de Firebase
const SIMPLE_EMAIL_SETTINGS = null;

module.exports = {
  APP_BASE_URL,
  EMAIL_ACTION_SETTINGS,
  SIMPLE_EMAIL_SETTINGS,

  // Utiliser cette fonction pour obtenir les settings appropriés
  getEmailSettings: () => {
    // Pour éviter l'erreur "Domain not whitelisted", on utilise les settings simples
    // Changez en EMAIL_ACTION_SETTINGS une fois les domaines configurés
    return SIMPLE_EMAIL_SETTINGS;
  }
};