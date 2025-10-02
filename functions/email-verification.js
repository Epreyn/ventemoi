const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { getEmailSettings } = require("./email-verification-config");

// Initialiser Admin SDK si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Génère le template HTML pour l'email de vérification
 */
function generateVerificationEmailHtml(userName, link) {
  return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vérifiez votre email - VenteMoi</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333333;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }

        .email-wrapper {
            width: 100%;
            background-color: #f5f5f5;
            padding: 40px 20px;
        }

        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
        }

        .header {
            background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%);
            padding: 40px 30px;
            text-align: center;
            position: relative;
        }

        .header::after {
            content: '';
            position: absolute;
            bottom: -20px;
            left: 0;
            right: 0;
            height: 40px;
            background: #ffffff;
            border-radius: 50% 50% 0 0 / 100% 100% 0 0;
        }

        .logo {
            display: inline-block;
            background: rgba(255, 255, 255, 0.95);
            padding: 15px 25px;
            border-radius: 12px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }

        .logo img {
            height: 40px;
            width: auto;
        }

        .content {
            padding: 40px 30px;
        }

        .button {
            display: inline-block;
            background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%);
            color: #ffffff !important;
            text-decoration: none;
            padding: 16px 40px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            margin: 25px 0;
            box-shadow: 0 4px 15px rgba(248, 176, 42, 0.3);
        }

        .highlight-box {
            background: linear-gradient(135deg, #fffbf0 0%, #fff8e6 100%);
            border: 2px solid #f8b02a;
            border-radius: 12px;
            padding: 20px;
            margin: 25px 0;
            text-align: center;
        }

        .info-box {
            background: #f0f9ff;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #1890ff;
        }

        .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
            color: #888888;
            font-size: 14px;
        }

        .footer a {
            color: #f8b02a;
            text-decoration: none;
        }

        h1 {
            color: #ffffff;
            margin: 0;
            font-size: 24px;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        h2 {
            color: #f8b02a;
            font-size: 22px;
            margin-bottom: 20px;
        }

        h3 {
            color: #f8b02a;
            margin-bottom: 10px;
        }

        ul {
            text-align: left;
            color: #555;
            line-height: 1.8;
        }

        .link-fallback {
            font-size: 12px;
            color: #666;
            word-break: break-all;
            background: #f5f5f5;
            padding: 10px;
            border-radius: 4px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            <div class="header">
                <div class="logo">
                    <img src="https://app.ventemoi.fr/assets/logo.png" alt="VenteMoi">
                </div>
                <h1>Bienvenue sur VenteMoi !</h1>
            </div>

            <div class="content">
                <h2>Vérifiez votre adresse email 📧</h2>

                <p>Bonjour ${userName},</p>

                <p>
                    Merci de vous être inscrit sur VenteMoi ! Pour activer votre compte et accéder
                    à tous nos services, veuillez confirmer votre adresse email en cliquant sur
                    le bouton ci-dessous :
                </p>

                <div style="text-align: center;">
                    <a href="${link}" class="button">
                        ✉️ Vérifier mon email
                    </a>
                </div>

                <div class="highlight-box">
                    <h3>⏱️ Ce lien expire dans 24 heures</h3>
                    <p style="margin: 5px 0; color: #666; font-size: 14px;">
                        Pour votre sécurité, ce lien de vérification n'est valide que pendant 24 heures.
                    </p>
                </div>

                <h3 style="color: #333; font-size: 18px; margin-top: 30px;">✨ Après la vérification</h3>
                <p>Une fois votre email vérifié, vous pourrez :</p>
                <ul>
                    <li>Accéder à votre compte personnel</li>
                    <li>Effectuer des achats et recevoir des bons</li>
                    <li>Parrainer vos amis et gagner des points</li>
                    <li>Soutenir des associations locales</li>
                </ul>

                <div class="info-box">
                    <p style="margin: 0; color: #1890ff;">
                        <strong>💡 Astuce :</strong> Si le bouton ne fonctionne pas, copiez et collez
                        ce lien dans votre navigateur :
                    </p>
                    <div class="link-fallback">${link}</div>
                </div>

                <p style="margin-top: 30px;">
                    <strong>Vous n'avez pas créé de compte ?</strong><br>
                    Si vous n'êtes pas à l'origine de cette inscription, ignorez simplement cet email.
                </p>
            </div>

            <div class="footer">
                <p>© 2024 VenteMoi - Tous droits réservés</p>
                <p>
                    Cet email vous a été envoyé automatiquement suite à votre inscription.<br>
                    Besoin d'aide ? Contactez-nous à
                    <a href="mailto:contact@ventemoi.com">contact@ventemoi.com</a>
                </p>
            </div>
        </div>
    </div>
</body>
</html>
  `;
}

/**
 * Fonction déclenchée lors de la création d'un nouvel utilisateur
 * Envoie un email de vérification personnalisé
 */
exports.sendCustomVerificationEmail = functions
  .region("europe-west1")
  .auth.user()
  .onCreate(async (user) => {
    console.log("🔵 Nouvel utilisateur créé:", user.email);

    try {
      // Attendre un peu pour que le document users soit créé dans Firestore
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Générer le lien de vérification officiel Firebase
      const emailSettings = getEmailSettings();
      const link = emailSettings
        ? await admin.auth().generateEmailVerificationLink(user.email, emailSettings)
        : await admin.auth().generateEmailVerificationLink(user.email);

      console.log("✅ Lien de vérification généré");

      // Récupérer les infos utilisateur depuis Firestore
      let userName = 'cher utilisateur';
      try {
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(user.uid)
          .get();

        if (userDoc.exists && userDoc.data().name) {
          userName = userDoc.data().name;
        }
      } catch (error) {
        console.log("⚠️ Impossible de récupérer le nom de l'utilisateur:", error.message);
      }

      // Générer le HTML de l'email
      const emailHtml = generateVerificationEmailHtml(userName, link);

      // Envoyer l'email via la collection 'mail' (extension Email)
      const emailDoc = await admin.firestore().collection('mail').add({
        to: [user.email],
        message: {
          subject: '✉️ Vérifiez votre email - VenteMoi',
          html: emailHtml,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });

      console.log("✅ Email de vérification personnalisé envoyé:", emailDoc.id);

      // Log pour suivi
      await admin.firestore().collection('email_logs').add({
        type: 'verification',
        userId: user.uid,
        email: user.email,
        emailDocId: emailDoc.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, emailId: emailDoc.id };

    } catch (error) {
      console.error("❌ Erreur envoi email personnalisé:", error);
      console.error("   Message:", error.message);
      console.error("   Stack:", error.stack);

      // Log l'erreur
      await admin.firestore().collection('email_errors').add({
        type: 'verification_email',
        userId: user.uid,
        email: user.email,
        error: error.message,
        stack: error.stack,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: false, error: error.message };
    }
  });

/**
 * Fonction callable pour renvoyer l'email de vérification
 * Peut être appelée depuis l'app Flutter
 */
exports.resendVerificationEmail = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Vérifier que l'utilisateur est authentifié
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Vous devez être connecté pour effectuer cette action'
      );
    }

    const uid = context.auth.uid;
    const email = context.auth.token.email;

    console.log("🔄 Demande de renvoi d'email pour:", email);

    try {
      // Vérifier si l'utilisateur est déjà vérifié
      const userRecord = await admin.auth().getUser(uid);
      if (userRecord.emailVerified) {
        return {
          success: false,
          message: 'Votre email est déjà vérifié'
        };
      }

      // Générer un nouveau lien de vérification
      const emailSettings = getEmailSettings();
      const link = emailSettings
        ? await admin.auth().generateEmailVerificationLink(email, emailSettings)
        : await admin.auth().generateEmailVerificationLink(email);

      // Récupérer le nom de l'utilisateur
      let userName = 'cher utilisateur';
      try {
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(uid)
          .get();

        if (userDoc.exists && userDoc.data().name) {
          userName = userDoc.data().name;
        }
      } catch (error) {
        console.log("⚠️ Impossible de récupérer le nom:", error.message);
      }

      // Générer et envoyer l'email
      const emailHtml = generateVerificationEmailHtml(userName, link);

      const emailDoc = await admin.firestore().collection('mail').add({
        to: [email],
        message: {
          subject: '✉️ Nouveau lien de vérification - VenteMoi',
          html: emailHtml,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });

      console.log("✅ Email de vérification renvoyé:", emailDoc.id);

      // Log pour suivi
      await admin.firestore().collection('email_logs').add({
        type: 'verification_resend',
        userId: uid,
        email: email,
        emailDocId: emailDoc.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Email envoyé avec succès',
        emailId: emailDoc.id
      };

    } catch (error) {
      console.error("❌ Erreur renvoi email:", error);

      // Log l'erreur
      await admin.firestore().collection('email_errors').add({
        type: 'resend_verification_email',
        userId: uid,
        email: email,
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw new functions.https.HttpsError(
        'internal',
        'Erreur lors de l\'envoi de l\'email: ' + error.message
      );
    }
  });

/**
 * Fonction HTTP pour tester l'envoi d'email (développement uniquement)
 */
exports.testVerificationEmail = functions
  .region("europe-west1")
  .https.onRequest(async (req, res) => {
    // Sécurité : uniquement en mode développement
    const isDev = process.env.FUNCTIONS_EMULATOR === 'true';

    if (!isDev && !req.query.secret || req.query.secret !== 'ventemoi2024') {
      return res.status(403).json({ error: 'Accès interdit' });
    }

    const testEmail = req.query.email || 'test@example.com';
    const testName = req.query.name || 'Test User';

    try {
      // Créer un faux lien pour le test
      const testLink = 'https://app.ventemoi.fr/#/verify?token=TEST_TOKEN_12345';

      // Générer l'email
      const emailHtml = generateVerificationEmailHtml(testName, testLink);

      // Retourner le HTML pour visualisation
      res.set('Content-Type', 'text/html');
      res.send(emailHtml);

    } catch (error) {
      res.status(500).json({
        error: error.message,
        stack: error.stack
      });
    }
  });

module.exports = exports;