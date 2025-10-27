# Configuration de l'authentification Google

## Étapes pour activer l'authentification Google

### 1. Console Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet VenteMoi
3. Dans le menu latéral, cliquez sur **Authentication**
4. Cliquez sur l'onglet **Sign-in method**
5. Cliquez sur **Google** dans la liste des fournisseurs
6. Activez le bouton **Enable**
7. Sélectionnez un email de support
8. Cliquez sur **Save**

### 2. Récupérer le Client ID Web

1. Dans la même page (Sign-in method > Google)
2. Développez la section **Web SDK configuration**
3. Copiez le **Web client ID** (il ressemble à : `123456789-abcdefg.apps.googleusercontent.com`)

### 3. Configurer le Client ID dans l'application

1. Ouvrez le fichier `web/index.html`
2. Trouvez la ligne avec `google-signin-client_id`
3. Remplacez `YOUR_CLIENT_ID_HERE.apps.googleusercontent.com` par votre vrai Client ID

```html
<meta name="google-signin-client_id" content="VOTRE_CLIENT_ID_ICI.apps.googleusercontent.com" />
```

### 4. Ajouter les domaines autorisés

1. Dans Firebase Console > Authentication > Settings
2. Onglet **Authorized domains**
3. Ajoutez vos domaines :
   - `app.ventemoi.fr` (production)
   - `localhost` (développement - déjà présent)

### 5. Configuration Google Cloud Console (optionnel)

Si vous avez besoin de personnaliser l'écran de consentement :

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet
3. Menu latéral > **APIs & Services** > **OAuth consent screen**
4. Configurez :
   - App name: **VenteMoi**
   - User support email: votre email
   - Developer contact information: votre email
   - Logo (optionnel)

### 6. Tester l'authentification

1. Lancez l'application : `flutter run -d chrome`
2. Sur l'écran de connexion, cliquez sur **Continuer avec Google**
3. Sélectionnez votre compte Google
4. Pour un nouveau compte : complétez les informations obligatoires (type d'utilisateur)
5. Pour un compte existant : connexion automatique

## Flux d'authentification

### Connexion avec compte existant
1. Utilisateur clique sur "Continuer avec Google"
2. Popup Google apparaît
3. Utilisateur sélectionne son compte
4. Vérification dans Firestore
5. → Compte trouvé : Connexion directe

### Inscription avec Google
1. Utilisateur clique sur "Continuer avec Google" (depuis login ou register)
2. Popup Google apparaît
3. Utilisateur sélectionne son compte
4. Vérification dans Firestore
5. → Compte non trouvé : Redirection vers formulaire d'inscription
6. Champs email et nom pré-remplis
7. **Utilisateur doit choisir "Je suis un(e)..." (obligatoire)**
8. Peut compléter : photo, code parrainage, association
9. Clic sur "S'INSCRIRE" → Création complète du compte

## Fonctionnalités supportées

✅ Connexion Google
✅ Inscription Google
✅ Pré-remplissage email/nom
✅ Informations obligatoires (type utilisateur)
✅ Code de parrainage
✅ Sélection d'associations
✅ Création wallet et sponsorship
✅ Emails de bienvenue
✅ Notifications admins

## Dépannage

### Erreur "ClientID not set"
→ Vérifiez que le Client ID est bien configuré dans `web/index.html`

### Popup Google ne s'ouvre pas
→ Vérifiez que le domaine est autorisé dans Firebase Console

### "Access blocked: This app's request is invalid"
→ Configurez l'écran de consentement dans Google Cloud Console

### Compte créé mais pas visible dans Firestore
→ Vérifiez les logs de la console pour voir les erreurs

## Support

Pour toute question, contactez l'équipe de développement.
