import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseEmailService {
  static final FirebaseEmailService _instance = FirebaseEmailService._internal();
  factory FirebaseEmailService() => _instance;
  FirebaseEmailService._internal();

  // Template personnalisé pour l'email de vérification
  Future<void> sendCustomVerificationEmail(User user) async {
    try {
      // Envoyer l'email de vérification Firebase standard d'abord
      await user.sendEmailVerification();

      // Ensuite envoyer notre email personnalisé en complément
      final content = '''
        <h2>Vérifiez votre adresse email 📧</h2>
        <p>
          Bonjour ${user.displayName ?? 'cher utilisateur'},
        </p>
        <p>
          Merci de vous être inscrit sur VenteMoi ! Pour activer votre compte et accéder à tous nos services,
          veuillez vérifier votre adresse email en cliquant sur le bouton ci-dessous.
        </p>

        <div class="highlight-box">
          <h3>📌 Important</h3>
          <p>
            Un email de vérification vous a été envoyé par Firebase.
            Cliquez sur le lien dans cet email pour vérifier votre adresse.
          </p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <p style="color: #666; margin-bottom: 10px;">
            Si vous n'avez pas reçu l'email, vérifiez vos spams ou reconnectez-vous pour en recevoir un nouveau.
          </p>
        </div>

        <div class="divider"></div>

        <h3 style="color: #333; font-size: 18px; margin-bottom: 15px;">✨ Après la vérification</h3>
        <p>
          Une fois votre email vérifié, vous pourrez :
        </p>
        <ul style="color: #555; line-height: 1.8;">
          <li>Accéder à votre compte personnel</li>
          <li>Effectuer des achats et recevoir des bons</li>
          <li>Parrainer vos amis et gagner des points</li>
          <li>Soutenir des associations locales</li>
        </ul>

        <p style="margin-top: 30px;">
          Si vous rencontrez des difficultés, n'hésitez pas à nous contacter à
          <a href="mailto:contact@ventemoi.com" style="color: #f8b02a;">contact@ventemoi.com</a>
        </p>
      ''';

      // Envoyer notre email personnalisé via la collection mail de Firebase
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [user.email],
        'message': {
          'subject': '✉️ Vérifiez votre email - VenteMoi',
          'html': _buildModernMailHtml(content),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Erreur envoi email vérification personnalisé: $e');
    }
  }

  // Template personnalisé pour la réinitialisation de mot de passe
  Future<void> sendCustomPasswordResetEmail(String email, String userName) async {
    try {
      // Envoyer l'email Firebase standard de réinitialisation
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Ensuite envoyer notre email personnalisé
      final content = '''
        <h2>Réinitialisation de votre mot de passe 🔐</h2>
        <p>
          Bonjour${userName.isNotEmpty ? ' $userName' : ''},
        </p>
        <p>
          Nous avons reçu une demande de réinitialisation de mot de passe pour votre compte VenteMoi.
        </p>

        <div class="highlight-box" style="background: linear-gradient(135deg, #fff5f5 0%, #ffe3e3 100%); border-color: #ff4757;">
          <h3 style="color: #ff4757;">🔑 Instructions</h3>
          <p>
            Un email de réinitialisation vous a été envoyé par Firebase.
            Cliquez sur le lien dans cet email pour créer un nouveau mot de passe.
          </p>
          <p style="margin-top: 10px; font-size: 14px; color: #666;">
            Ce lien expirera dans 1 heure pour des raisons de sécurité.
          </p>
        </div>

        <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin: 20px 0;">
          <p style="margin: 0; color: #666;">
            <strong>⚠️ Vous n'avez pas demandé cette réinitialisation ?</strong><br>
            Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet email.
            Votre mot de passe ne sera pas modifié.
          </p>
        </div>

        <div class="divider"></div>

        <h3 style="color: #333; font-size: 18px; margin-bottom: 15px;">💡 Conseils de sécurité</h3>
        <ul style="color: #555; line-height: 1.8;">
          <li>Choisissez un mot de passe d'au moins 8 caractères</li>
          <li>Utilisez une combinaison de lettres, chiffres et symboles</li>
          <li>Ne partagez jamais votre mot de passe</li>
          <li>Utilisez un mot de passe unique pour VenteMoi</li>
        </ul>

        <p style="margin-top: 30px;">
          Besoin d'aide ? Contactez notre support à
          <a href="mailto:contact@ventemoi.com" style="color: #f8b02a;">contact@ventemoi.com</a>
        </p>
      ''';

      // Envoyer notre email personnalisé
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email],
        'message': {
          'subject': '🔐 Réinitialisation de votre mot de passe - VenteMoi',
          'html': _buildModernMailHtml(content),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Erreur envoi email réinitialisation personnalisé: $e');
    }
  }

  // Template pour notification de suppression de compte
  Future<void> sendAccountDeletionNotification(String email, String userName) async {
    try {
      final content = '''
        <h2>Confirmation de suppression de compte 🗑️</h2>
        <p>
          Bonjour${userName.isNotEmpty ? ' $userName' : ''},
        </p>
        <p>
          Votre compte VenteMoi a été supprimé conformément à votre demande.
        </p>

        <div class="highlight-box">
          <h3>Ce qui a été supprimé</h3>
          <ul style="text-align: left; color: #666;">
            <li>Vos informations personnelles</li>
            <li>Votre historique d'achats</li>
            <li>Vos points et bons cadeaux</li>
            <li>Vos parrainages</li>
          </ul>
        </div>

        <p>
          Vos transactions passées ont été anonymisées pour préserver l'historique des autres utilisateurs.
        </p>

        <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin: 20px 0;">
          <p style="margin: 0; color: #666;">
            💡 <strong>Note :</strong> Certaines données peuvent être conservées pour des raisons légales
            ou de conformité pendant une durée limitée conformément au RGPD.
          </p>
        </div>

        <p>
          Nous sommes tristes de vous voir partir. Si vous changez d'avis,
          vous pourrez toujours créer un nouveau compte avec la même adresse email.
        </p>

        <p style="margin-top: 30px;">
          Merci d'avoir fait partie de la communauté VenteMoi.
        </p>

        <p>
          L'équipe VenteMoi
        </p>
      ''';

      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email],
        'message': {
          'subject': '👋 Confirmation de suppression de compte - VenteMoi',
          'html': _buildModernMailHtml(content),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Erreur envoi notification suppression compte: $e');
    }
  }

  // Méthode privée pour construire le template HTML
  String _buildModernMailHtml(String content) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vente Moi</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333333;
            background-color: #f5f5f5;
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
            vertical-align: middle;
        }

        .header h1 {
            color: #ffffff;
            font-size: 24px;
            font-weight: 700;
            margin: 0;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .content {
            padding: 40px 30px;
            background: #ffffff;
        }

        .content h2 {
            color: #f8b02a;
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 20px;
            line-height: 1.3;
        }

        .content h3 {
            color: #333;
            font-size: 18px;
            margin-bottom: 15px;
        }

        .content p {
            color: #555555;
            font-size: 16px;
            line-height: 1.8;
            margin-bottom: 16px;
        }

        .content ul {
            color: #555;
            line-height: 1.8;
        }

        .highlight-box {
            background: linear-gradient(135deg, #fffbf0 0%, #fff8e6 100%);
            border: 2px solid #f8b02a;
            border-radius: 12px;
            padding: 20px;
            margin: 25px 0;
            text-align: center;
        }

        .highlight-box h3 {
            color: #f8b02a;
            font-size: 18px;
            margin-bottom: 10px;
        }

        .button {
            display: inline-block;
            background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%);
            color: #ffffff;
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            margin: 20px 0;
            box-shadow: 0 4px 15px rgba(248, 176, 42, 0.3);
        }

        .info-grid {
            display: table;
            width: 100%;
            margin: 20px 0;
            border-collapse: separate;
            border-spacing: 15px 0;
        }

        .info-item {
            display: table-cell;
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            vertical-align: top;
        }

        .info-label {
            color: #888888;
            font-size: 14px;
            margin-bottom: 5px;
        }

        .info-value {
            color: #333333;
            font-size: 18px;
            font-weight: 600;
        }

        .divider {
            height: 1px;
            background: #eeeeee;
            margin: 30px 0;
        }

        .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
        }

        .footer p {
            color: #888888;
            font-size: 14px;
            margin-bottom: 10px;
        }

        .footer-links {
            margin-top: 15px;
        }

        .footer-links a {
            color: #f8b02a;
            text-decoration: none;
            margin: 0 10px;
            font-size: 14px;
            font-weight: 500;
        }

        @media only screen and (max-width: 600px) {
            .email-wrapper {
                padding: 20px 10px;
            }

            .header {
                padding: 30px 20px;
            }

            .content {
                padding: 30px 20px;
            }

            .header h1 {
                font-size: 20px;
            }

            .content h2 {
                font-size: 18px;
            }

            .info-grid {
                display: block;
            }

            .info-item {
                display: block;
                margin-bottom: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            <div class="header">
                <div class="logo">
                    <img src="https://app.ventemoi.fr/assets/logo.png" alt="Vente Moi">
                </div>
                <h1>Vente Moi</h1>
            </div>

            <div class="content">
                $content
            </div>

            <div class="footer">
                <p>© 2024 Vente Moi - Tous droits réservés</p>
                <p>Cet email vous a été envoyé automatiquement. Merci de ne pas y répondre.</p>

                <div class="footer-links">
                    <a href="https://app.ventemoi.fr">Site web</a>
                    <a href="mailto:contact@ventemoi.com">Support</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
''';
  }
}