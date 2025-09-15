import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherPurchaseEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Envoie un email de confirmation après l'achat de bons
  static Future<void> sendVoucherPurchaseEmail({
    required String buyerId,
    required String establishmentId,
    required String establishmentName,
    required int voucherCount,
    required int totalPoints,
    required List<String> voucherCodes,
    required String expiryDate,
  }) async {
    try {
      // Récupérer les informations de l'acheteur
      final buyerDoc = await _firestore.collection('users').doc(buyerId).get();
      if (!buyerDoc.exists) {
        print('Buyer user not found');
        return;
      }

      final buyerData = buyerDoc.data()!;
      final buyerEmail = buyerData['email'] as String?;
      final buyerName = buyerData['name'] ?? buyerData['first_name'] ?? buyerData['display_name'] ?? 'Utilisateur';

      if (buyerEmail == null || buyerEmail.isEmpty) {
        print('No email for buyer');
        return;
      }

      // Préparer le contenu de l'email avec le template moderne
      final emailContent = _buildModernEmailHtml(
        buyerName: buyerName,
        establishmentName: establishmentName,
        voucherCount: voucherCount,
        totalPoints: totalPoints,
        voucherCodes: voucherCodes,
        expiryDate: expiryDate,
      );

      // Utiliser la collection 'mail' comme le reste du projet
      try {
        await _firestore.collection('mail').add({
          'to': buyerEmail,
          'message': {
            'subject': '🎫 Confirmation d\'achat - $voucherCount bon(s) chez $establishmentName',
            'html': emailContent,
          },
        });

        print('✅ Email de confirmation envoyé à $buyerEmail');
      } catch (e) {
        print('Erreur lors de l\'envoi de l\'email à l\'acheteur: $e');
      }

      // Envoyer aussi un email à l'établissement
      try {
        final establishmentDoc = await _firestore.collection('establishments').doc(establishmentId).get();
        if (establishmentDoc.exists) {
          final establishmentData = establishmentDoc.data()!;

          // Récupérer l'email de l'établissement depuis le document user associé
          final establishmentUserId = establishmentData['user_id'] as String?;
          if (establishmentUserId != null) {
            final establishmentUserDoc = await _firestore.collection('users').doc(establishmentUserId).get();
            if (establishmentUserDoc.exists) {
              final establishmentEmail = establishmentUserDoc.data()!['email'] as String?;

              if (establishmentEmail != null && establishmentEmail.isNotEmpty) {
                final establishmentEmailContent = _buildEstablishmentEmailHtml(
                  establishmentName: establishmentName,
                  buyerName: buyerName,
                  voucherCount: voucherCount,
                  totalPoints: totalPoints,
                  voucherCodes: voucherCodes,
                );

                await _firestore.collection('mail').add({
                  'to': establishmentEmail,
                  'message': {
                    'subject': '🛍️ Nouvel achat de bons - $voucherCount bon(s) vendus',
                    'html': establishmentEmailContent,
                  },
                });

                print('✅ Email de notification envoyé à l\'établissement: $establishmentEmail');
              }
            }
          }
        }
      } catch (e) {
        print('Erreur lors de l\'envoi de l\'email à l\'établissement: $e');
      }

    } catch (e) {
      print('Erreur générale envoi email achat: $e');
    }
  }

  static String _buildModernEmailHtml({
    required String buyerName,
    required String establishmentName,
    required int voucherCount,
    required int totalPoints,
    required List<String> voucherCodes,
    required String expiryDate,
  }) {
    // Formater les codes de bons avec le style moderne
    String voucherCodesSection = '';
    for (int i = 0; i < voucherCodes.length; i++) {
      voucherCodesSection += '''
        <div style="background: linear-gradient(135deg, #fffbf0 0%, #fff8e6 100%);
                    border: 2px solid #f8b02a;
                    border-radius: 12px;
                    padding: 20px;
                    margin: 15px 0;
                    text-align: center;">
          <p style="margin: 0 0 10px 0; color: #888888; font-size: 14px;">Bon n°${i + 1}</p>
          <div style="background: #f8b02a;
                      color: #ffffff;
                      font-size: 28px;
                      font-weight: 700;
                      letter-spacing: 4px;
                      padding: 15px 30px;
                      border-radius: 8px;
                      display: inline-block;
                      font-family: 'Courier New', monospace;">
            ${voucherCodes[i]}
          </div>
        </div>
      ''';
    }

    final content = '''
      <h2>🎫 Confirmation de votre achat</h2>
      <p>
        Bonjour <strong>$buyerName</strong>,
      </p>
      <p>
        Votre achat de bons a été confirmé avec succès ! Vous trouverez ci-dessous tous les détails de votre commande.
      </p>

      <div style="background: linear-gradient(135deg, #fffbf0 0%, #fff8e6 100%);
                  border: 2px solid #f8b02a;
                  border-radius: 12px;
                  padding: 20px;
                  margin: 25px 0;
                  text-align: center;">
        <h3 style="color: #f8b02a; font-size: 18px; margin-bottom: 20px;">Récapitulatif de votre commande</h3>

        <div style="display: table; width: 100%; margin: 20px 0; border-collapse: separate; border-spacing: 15px 0;">
          <div style="display: table-cell; background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Établissement</div>
            <div style="color: #333333; font-size: 18px; font-weight: 600;">$establishmentName</div>
          </div>
          <div style="display: table-cell; background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Nombre de bons</div>
            <div style="color: #f8b02a; font-size: 24px; font-weight: 600;">$voucherCount</div>
          </div>
        </div>

        <div style="display: table; width: 100%; margin: 20px 0; border-collapse: separate; border-spacing: 15px 0;">
          <div style="display: table-cell; background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Total en points</div>
            <div style="color: #f8b02a; font-size: 24px; font-weight: 600;">$totalPoints</div>
          </div>
          <div style="display: table-cell; background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Validité</div>
            <div style="color: #333333; font-size: 16px; font-weight: 600;">$expiryDate</div>
          </div>
        </div>
      </div>

      <h3 style="color: #f8b02a; font-size: 20px; margin: 30px 0 20px 0;">Vos codes de bons</h3>
      $voucherCodesSection

      <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin: 30px 0;">
        <p style="margin: 0; font-size: 16px;">
          <strong style="color: #f8b02a;">💡 Comment utiliser vos bons ?</strong>
        </p>
        <ol style="margin: 10px 0 0 20px; padding: 0; color: #555555; line-height: 1.8;">
          <li>Rendez-vous dans l'établissement <strong>$establishmentName</strong></li>
          <li>Présentez le code alphanumérique au commerçant</li>
          <li>Le commerçant validera votre bon</li>
          <li>Profitez de votre achat !</li>
        </ol>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/wallet"
           style="display: inline-block;
                  background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%);
                  color: #ffffff;
                  text-decoration: none;
                  padding: 14px 32px;
                  border-radius: 8px;
                  font-weight: 600;
                  font-size: 16px;
                  box-shadow: 0 4px 15px rgba(248, 176, 42, 0.3);">
          Voir mes bons dans mon portefeuille
        </a>
      </div>

      <div style="height: 1px; background: #eeeeee; margin: 30px 0;"></div>

      <p style="font-size: 14px; color: #888;">
        <strong>Important :</strong> Conservez cet email précieusement. Il contient vos codes de bons qui vous seront nécessaires lors de votre visite en boutique.
      </p>
    ''';

    return _buildEmailTemplate(content);
  }

  static String _buildEstablishmentEmailHtml({
    required String establishmentName,
    required String buyerName,
    required int voucherCount,
    required int totalPoints,
    required List<String> voucherCodes,
  }) {
    // Liste des codes pour l'établissement
    String codesListHtml = '';
    for (int i = 0; i < voucherCodes.length; i++) {
      codesListHtml += '''
        <tr>
          <td style="padding: 10px; border-bottom: 1px solid #eeeeee; color: #666666;">Bon n°${i + 1}</td>
          <td style="padding: 10px; border-bottom: 1px solid #eeeeee; font-family: 'Courier New', monospace; font-weight: bold; color: #333333;">${voucherCodes[i]}</td>
          <td style="padding: 10px; border-bottom: 1px solid #eeeeee; color: #f8b02a;">À valider</td>
        </tr>
      ''';
    }

    final content = '''
      <h2>🛍️ Nouvelle vente réalisée !</h2>
      <p>
        Bonjour <strong>$establishmentName</strong>,
      </p>
      <p>
        Félicitations ! <strong>$buyerName</strong> vient d'acheter des bons dans votre établissement.
      </p>

      <div style="background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
                  border: 2px solid #4caf50;
                  border-radius: 12px;
                  padding: 20px;
                  margin: 25px 0;
                  text-align: center;">
        <h3 style="color: #2e7d32; font-size: 18px; margin-bottom: 20px;">Détails de la vente</h3>

        <div style="display: table; width: 100%; margin: 20px 0; border-collapse: separate; border-spacing: 15px 0;">
          <div style="display: table-cell; background: #ffffff; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Client</div>
            <div style="color: #333333; font-size: 18px; font-weight: 600;">$buyerName</div>
          </div>
          <div style="display: table-cell; background: #ffffff; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Nombre de bons vendus</div>
            <div style="color: #4caf50; font-size: 24px; font-weight: 600;">$voucherCount</div>
          </div>
          <div style="display: table-cell; background: #ffffff; padding: 15px; border-radius: 8px; text-align: center; vertical-align: top;">
            <div style="color: #888888; font-size: 14px; margin-bottom: 5px;">Total</div>
            <div style="color: #4caf50; font-size: 24px; font-weight: 600;">$totalPoints points</div>
          </div>
        </div>
      </div>

      <h3 style="color: #333333; font-size: 18px; margin: 30px 0 20px 0;">Codes des bons vendus</h3>

      <div style="background: #f8f9fa; border-radius: 12px; padding: 20px; margin: 20px 0;">
        <table style="width: 100%; border-collapse: collapse;">
          <thead>
            <tr>
              <th style="padding: 10px; border-bottom: 2px solid #dee2e6; text-align: left; color: #495057;">Bon</th>
              <th style="padding: 10px; border-bottom: 2px solid #dee2e6; text-align: left; color: #495057;">Code</th>
              <th style="padding: 10px; border-bottom: 2px solid #dee2e6; text-align: left; color: #495057;">Statut</th>
            </tr>
          </thead>
          <tbody>
            $codesListHtml
          </tbody>
        </table>
      </div>

      <div style="background: #fff3e0; border-left: 4px solid #ff9800; padding: 15px; margin: 25px 0;">
        <p style="margin: 0; font-size: 14px; color: #e65100;">
          <strong>⚠️ Important :</strong> Ces codes doivent être validés lorsque le client se présente dans votre établissement. Assurez-vous de marquer chaque bon comme utilisé après validation.
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/pro-dashboard"
           style="display: inline-block;
                  background: linear-gradient(135deg, #4caf50 0%, #388e3c 100%);
                  color: #ffffff;
                  text-decoration: none;
                  padding: 14px 32px;
                  border-radius: 8px;
                  font-weight: 600;
                  font-size: 16px;
                  box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);">
          Voir dans mon tableau de bord
        </a>
      </div>

      <div style="height: 1px; background: #eeeeee; margin: 30px 0;"></div>

      <p style="font-size: 14px; color: #888;">
        Cette notification vous est envoyée automatiquement à chaque vente. Pour modifier vos préférences de notification, rendez-vous dans les paramètres de votre compte.
      </p>
    ''';

    return _buildEmailTemplate(content);
  }

  static String _buildEmailTemplate(String content) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vente Moi</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333333; background-color: #f5f5f5;">
    <div style="width: 100%; background-color: #f5f5f5; padding: 40px 20px;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);">
            <div style="background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%); padding: 40px 30px; text-align: center; position: relative;">
                <div style="display: inline-block; background: rgba(255, 255, 255, 0.95); padding: 15px 25px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);">
                    <img src="https://app.ventemoi.fr/assets/logo.png" alt="Vente Moi" style="height: 40px; width: auto; vertical-align: middle;">
                </div>
                <h1 style="color: #ffffff; font-size: 24px; font-weight: 700; margin: 0; text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);">Vente Moi</h1>
            </div>

            <div style="padding: 40px 30px; background: #ffffff;">
                $content
            </div>

            <div style="background: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #eeeeee;">
                <p style="color: #888888; font-size: 14px; margin-bottom: 10px;">© ${DateTime.now().year} Vente Moi - Tous droits réservés</p>
                <p style="color: #888888; font-size: 14px; margin-bottom: 10px;">Cet email vous a été envoyé automatiquement. Merci de ne pas y répondre.</p>
                <div style="margin-top: 15px;">
                    <a href="https://app.ventemoi.fr" style="color: #f8b02a; text-decoration: none; margin: 0 10px; font-size: 14px; font-weight: 500;">Site web</a>
                    <a href="mailto:contact@ventemoi.com" style="color: #f8b02a; text-decoration: none; margin: 0 10px; font-size: 14px; font-weight: 500;">Support</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }
}