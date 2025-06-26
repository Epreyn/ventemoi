// Extension du ControllerMixin avec des templates d'emails modernes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/classes/controller_mixin.dart';

extension EmailTemplates on ControllerMixin {
  String buildModernMailHtml(String content) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vente Moi</title>
    <!--[if mso]>
    <noscript>
        <xml>
            <o:OfficeDocumentSettings>
                <o:PixelsPerInch>96</o:PixelsPerInch>
            </o:OfficeDocumentSettings>
        </xml>
    </noscript>
    <![endif]-->
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
            background: linear-gradient(135deg, #ff9500 0%, #ff7a00 100%);
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
            color: #ff7a00;
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 20px;
            line-height: 1.3;
        }

        .content p {
            color: #555555;
            font-size: 16px;
            line-height: 1.8;
            margin-bottom: 16px;
        }

        .highlight-box {
            background: linear-gradient(135deg, #fff8f0 0%, #fff5e6 100%);
            border: 2px solid #ff9500;
            border-radius: 12px;
            padding: 20px;
            margin: 25px 0;
            text-align: center;
        }

        .highlight-box h3 {
            color: #ff7a00;
            font-size: 18px;
            margin-bottom: 10px;
        }

        .code-box {
            background: #ff7a00;
            color: #ffffff;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: 4px;
            padding: 15px 30px;
            border-radius: 8px;
            display: inline-block;
            margin: 10px 0;
            font-family: 'Courier New', monospace;
        }

        .button {
            display: inline-block;
            background: linear-gradient(135deg, #ff9500 0%, #ff7a00 100%);
            color: #ffffff;
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            margin: 20px 0;
            box-shadow: 0 4px 15px rgba(255, 122, 0, 0.3);
            transition: all 0.3s ease;
        }

        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 122, 0, 0.4);
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

        .social-links {
            margin: 20px 0;
        }

        .social-links a {
            display: inline-block;
            margin: 0 10px;
            opacity: 0.7;
            transition: opacity 0.3s ease;
        }

        .social-links a:hover {
            opacity: 1;
        }

        .footer-links {
            margin-top: 15px;
        }

        .footer-links a {
            color: #ff7a00;
            text-decoration: none;
            margin: 0 10px;
            font-size: 14px;
            font-weight: 500;
        }

        .footer-links a:hover {
            text-decoration: underline;
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
                    <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media" alt="Vente Moi">
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
                    <a href="mailto:app@ventemoi.fr">Support</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
''';
  }

  // Email pour la réception d'un bon cadeau
  Future<void> sendGiftReceivedEmail({
    required String toEmail,
    required String recipientName,
    required String senderName,
    required int amount,
    required String reclamationCode,
  }) async {
    final content = '''
      <h2>🎁 Bonne nouvelle $recipientName !</h2>
      <p>
        <strong>$senderName</strong> vient de vous offrir un bon cadeau sur Vente Moi !
      </p>

      <div class="highlight-box">
        <h3>Votre bon cadeau</h3>
        <div class="info-value" style="font-size: 32px; color: #ff7a00; margin: 10px 0;">$amount €</div>
        <p style="margin: 15px 0 5px 0; color: #666;">Code de récupération :</p>
        <div class="code-box">$reclamationCode</div>
      </div>

      <p>
        Ce code est personnel et sécurisé. Présentez-le chez nos partenaires pour utiliser votre bon cadeau.
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://ventemoi.com/mes-achats" class="button">Voir mes bons cadeaux</a>
      </div>

      <div class="divider"></div>

      <p style="font-size: 14px; color: #888;">
        💡 <strong>Astuce :</strong> Vous pouvez retrouver tous vos bons cadeaux dans votre espace personnel,
        section "Mes achats".
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🎁 Vous avez reçu un bon cadeau de $amount € !',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Email de confirmation d'achat moderne
  Future<void> sendModernPurchaseEmailToBuyer({
    required String buyerEmail,
    required String buyerName,
    required String sellerName,
    required bool isDonation,
    required int couponsCountOrPoints,
    required String? reclamationPassword,
    required DateTime purchaseDate,
  }) async {
    if (buyerEmail.trim().isEmpty) return;

    late String subject;
    late String content;

    if (isDonation) {
      subject = '❤️ Confirmation de votre don - Vente Moi';
      content = '''
        <h2>Merci pour votre générosité, $buyerName !</h2>
        <p>
          Votre don a bien été enregistré et nous vous en remercions chaleureusement.
        </p>

        <div class="highlight-box">
          <h3>Détails de votre don</h3>
          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Montant du don</div>
              <div class="info-value">$couponsCountOrPoints points</div>
            </div>
            <div class="info-item">
              <div class="info-label">Bénéficiaire</div>
              <div class="info-value">$sellerName</div>
            </div>
          </div>
        </div>

        <p>
          Votre soutien fait une réelle différence. Grâce à vous, <strong>$sellerName</strong>
          peut continuer ses actions solidaires.
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://ventemoi.com/mes-dons" class="button">Voir mes dons</a>
        </div>
      ''';
    } else {
      final codeSection = (reclamationPassword?.isNotEmpty == true)
          ? '''
            <p style="margin: 15px 0 5px 0; color: #666;">Votre code de réclamation :</p>
            <div class="code-box">$reclamationPassword</div>
            <p style="font-size: 14px; color: #888; margin-top: 10px;">
              Conservez précieusement ce code pour récupérer vos bons
            </p>
          '''
          : '<p style="color: #888;">Aucun code généré</p>';

      subject = '✅ Confirmation de votre achat - Vente Moi';
      content = '''
        <h2>Merci pour votre achat, $buyerName !</h2>
        <p>
          Votre commande a bien été enregistrée. Vous trouverez ci-dessous tous les détails.
        </p>

        <div class="highlight-box">
          <h3>Récapitulatif de votre commande</h3>
          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Nombre de bons</div>
              <div class="info-value">$couponsCountOrPoints</div>
            </div>
            <div class="info-item">
              <div class="info-label">Valeur totale</div>
              <div class="info-value">${couponsCountOrPoints * 50} €</div>
            </div>
          </div>
          $codeSection
        </div>

        <p>
          <strong>Établissement :</strong> $sellerName<br>
          <strong>Date d'achat :</strong> ${_formatDate(purchaseDate)}
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://ventemoi.com/mes-achats" class="button">Voir mes achats</a>
        </div>

        <div class="divider"></div>

        <p style="font-size: 14px; color: #888;">
          💡 <strong>Comment utiliser vos bons ?</strong><br>
          Présentez votre code chez nos partenaires participants pour profiter de vos avantages.
        </p>
      ''';
    }

    await sendMailSimple(
      toEmail: buyerEmail,
      subject: subject,
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Email de bienvenue moderne
  Future<void> sendModernWelcomeEmail(String toEmail, String userName) async {
    final content = '''
      <h2>Bienvenue dans la communauté Vente Moi, $userName ! 🎉</h2>
      <p>
        Nous sommes ravis de vous compter parmi nous. Votre compte a été créé avec succès
        et vous pouvez dès maintenant profiter de tous nos services.
      </p>

      <div class="highlight-box" style="background: linear-gradient(135deg, #f0f9ff 0%, #e6f7ff 100%); border-color: #40a9ff;">
        <h3 style="color: #1890ff;">🚀 Pour bien démarrer</h3>
        <p style="text-align: left; margin: 10px 0;">
          ✓ Explorez notre boutique et découvrez nos offres<br>
          ✓ Gagnez des points en participant à nos actions<br>
          ✓ Soutenez des associations locales<br>
          ✓ Profitez de bons d'achat chez nos partenaires
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://ventemoi.com/boutique" class="button">Découvrir la boutique</a>
      </div>

      <div class="divider"></div>

      <h3 style="color: #333; font-size: 18px; margin-bottom: 15px;">💰 Bonus de bienvenue</h3>
      <p>
        En tant que nouveau membre, vous bénéficiez automatiquement de <strong>50 points offerts</strong> !
        Utilisez-les dès maintenant dans notre boutique.
      </p>

      <p style="margin-top: 30px;">
        Des questions ? Notre équipe support est là pour vous aider à
        <a href="mailto:support@ventemoi.com" style="color: #ff7a00;">support@ventemoi.com</a>
      </p>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: '🎉 Bienvenue sur Vente Moi !',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Helper pour formater les dates
  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }
}
