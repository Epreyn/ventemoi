// lib/core/services/automatic_gift_voucher_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../classes/unique_controllers.dart';

class AutomaticGiftVoucherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Attribue automatiquement 4 bons cadeaux de 50€ lors de l'inscription d'un commerce
  static Future<void> attributeWelcomeVouchers({
    required String commerceId, // ID du nouveau commerce
    required String commerceName,
    required String commerceEmail,
  }) async {
    try {
      print('Attribution des bons cadeaux pour le commerce: $commerceName');

      // 1. Récupérer les IDs des types d'utilisateurs
      final userTypes = await _getUserTypeIds();

      // 2. Sélectionner aléatoirement un utilisateur de chaque type
      final selectedUsers = await _selectRandomUsers(userTypes);

      if (selectedUsers.length != 4) {
        print('Impossible de trouver 4 utilisateurs différents');
        return;
      }

      // 3. Créer les 4 bons cadeaux
      final vouchers = <Map<String, dynamic>>[];

      for (final user in selectedUsers) {
        final voucherCode = _generateVoucherCode();

        // Créer le bon cadeau dans la collection purchases
        final purchaseRef = _firestore.collection('purchases').doc();

        await purchaseRef.set({
          'buyer_id': user['id'], // Le gagnant
          'seller_id': commerceId, // Le nouveau commerce
          'coupons_count': 1, // 1 bon de 50€
          'date': DateTime.now().toIso8601String(),
          'isReclaimed': false,
          'reclamationPassword': voucherCode,
          'is_gift': true,
          'gift_type': 'welcome_bonus',
          'created_at': FieldValue.serverTimestamp(),
        });

        vouchers.add({
          'user': user,
          'code': voucherCode,
          'purchaseId': purchaseRef.id,
        });
      }

      // 4. Envoyer les emails aux gagnants
      await _sendEmailsToWinners(vouchers, commerceName);

      // 5. Envoyer un email récapitulatif au commerce
      await _sendRecapEmailToCommerce(commerceEmail, commerceName, vouchers);

      // 6. Créer une notification pour le commerce
      await _createNotificationForCommerce(commerceId, vouchers);

      print('Attribution des bons cadeaux terminée avec succès');
    } catch (e) {
      print('Erreur lors de l\'attribution des bons cadeaux: $e');
      // Log l'erreur mais ne pas bloquer l'inscription
    }
  }

  /// Récupère les IDs des types d'utilisateurs
  static Future<Map<String, String>> _getUserTypeIds() async {
    final snapshot = await _firestore.collection('user_types').get();
    final types = <String, String>{};

    for (final doc in snapshot.docs) {
      final name = doc.data()['name'] as String?;
      if (name != null) {
        types[name] = doc.id;
      }
    }

    return types;
  }

  /// Sélectionne aléatoirement un utilisateur de chaque type
  static Future<List<Map<String, dynamic>>> _selectRandomUsers(
    Map<String, String> userTypes,
  ) async {
    final selectedUsers = <Map<String, dynamic>>[];
    final typesToSelect = [
      'Entreprise',
      'Boutique',
      'Association',
      'Particulier'
    ];

    for (final typeName in typesToSelect) {
      final typeId = userTypes[typeName];
      if (typeId == null) continue;

      // Récupérer tous les utilisateurs de ce type qui sont visibles
      final query = await _firestore
          .collection('users')
          .where('user_type_id', isEqualTo: typeId)
          .where('isVisible', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        // Sélectionner un utilisateur aléatoire
        final randomIndex = _random.nextInt(query.docs.length);
        final selectedDoc = query.docs[randomIndex];

        selectedUsers.add({
          'id': selectedDoc.id,
          'name': selectedDoc.data()['name'] ?? 'Utilisateur',
          'email': selectedDoc.data()['email'] ?? '',
          'type': typeName,
          'company_name': selectedDoc.data()['company_name'],
        });
      }
    }

    return selectedUsers;
  }

  /// Génère un code de bon cadeau à 6 chiffres
  static String _generateVoucherCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  /// Envoie les emails aux gagnants
  static Future<void> _sendEmailsToWinners(
    List<Map<String, dynamic>> vouchers,
    String commerceName,
  ) async {
    for (final voucher in vouchers) {
      final user = voucher['user'] as Map<String, dynamic>;
      final email = user['email'] as String;

      if (email.isEmpty) continue;

      final content = '''
        <h2>🎉 Félicitations ${user['name']} !</h2>

        <p>
          Vous avez gagné un <strong>bon cadeau de 50€</strong> valable chez
          <strong>$commerceName</strong> qui vient de rejoindre VenteMoi !
        </p>

        <div class="highlight-box">
          <h3>Votre bon cadeau</h3>
          <div class="info-value" style="font-size: 32px; color: #ff7a00; margin: 10px 0;">50 €</div>
          <p style="margin: 15px 0 5px 0; color: #666;">Code de récupération :</p>
          <div class="code-box">${voucher['code']}</div>
        </div>

        <p>
          Ce bon a été attribué automatiquement suite à l'inscription de
          <strong>$commerceName</strong> sur VenteMoi. Profitez-en pour découvrir
          ce nouveau partenaire !
        </p>

        <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h4 style="color: #1890ff; margin-top: 0;">💡 Comment utiliser votre bon ?</h4>
          <ol style="margin: 10px 0; padding-left: 20px;">
            <li>Rendez-vous chez $commerceName</li>
            <li>Effectuez vos achats</li>
            <li>Présentez votre code au moment du paiement</li>
          </ol>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://ventemoi.com/mes-achats" class="button">Voir mes bons cadeaux</a>
        </div>
      ''';

      // Envoyer directement via Firestore
      await _firestore.collection('mail').add({
        "to": email,
        "message": {
          "subject": '🎁 Vous avez gagné un bon de 50€ chez $commerceName !',
          "html": _buildModernMailHtml(content),
        },
      });
    }
  }

  /// Envoie un email récapitulatif au commerce
  static Future<void> _sendRecapEmailToCommerce(
    String commerceEmail,
    String commerceName,
    List<Map<String, dynamic>> vouchers,
  ) async {
    // Préparer la liste des gagnants
    final winnersHtml = vouchers.map((v) {
      final user = v['user'] as Map<String, dynamic>;
      final displayName = user['company_name'] != null &&
              user['company_name'].toString().isNotEmpty
          ? user['company_name']
          : user['name'];
      return '''
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eee;">$displayName</td>
          <td style="padding: 12px; border-bottom: 1px solid #eee;">${user['type']}</td>
          <td style="padding: 12px; border-bottom: 1px solid #eee; font-family: monospace;">${v['code']}</td>
        </tr>
      ''';
    }).join();

    final content = '''
      <h2>🎊 Bienvenue sur VenteMoi, $commerceName !</h2>

      <p>
        Pour célébrer votre inscription, nous avons automatiquement attribué
        <strong>4 bons cadeaux de 50€</strong> utilisables dans votre établissement
        à des membres de notre communauté.
      </p>

      <div class="highlight-box">
        <h3>Récapitulatif des bons attribués</h3>
        <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
          <thead>
            <tr style="background: #f5f5f5;">
              <th style="padding: 12px; text-align: left; font-weight: 600;">Bénéficiaire</th>
              <th style="padding: 12px; text-align: left; font-weight: 600;">Type</th>
              <th style="padding: 12px; text-align: left; font-weight: 600;">Code</th>
            </tr>
          </thead>
          <tbody>
            $winnersHtml
          </tbody>
        </table>
      </div>

      <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h4 style="color: #1890ff; margin-top: 0;">📋 Comment valider ces bons ?</h4>
        <ol style="margin: 10px 0; padding-left: 20px;">
          <li>Le client vous présente son code à 6 chiffres</li>
          <li>Connectez-vous à votre espace VenteMoi</li>
          <li>Allez dans "Ventes" > "Valider un bon"</li>
          <li>Entrez le code pour valider le bon de 50€</li>
        </ol>
      </div>

      <p>
        <strong>💡 Conseil :</strong> Ces bons sont un excellent moyen d'attirer
        de nouveaux clients dans votre établissement. N'hésitez pas à les accueillir
        chaleureusement !
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://ventemoi.com/pro/ventes" class="button">Accéder à mon espace</a>
      </div>
    ''';

    // Envoyer directement via Firestore
    await _firestore.collection('mail').add({
      "to": commerceEmail,
      "message": {
        "subject":
            '🎊 4 bons cadeaux ont été attribués pour votre établissement',
        "html": _buildModernMailHtml(content),
      },
    });
  }

  /// Crée une notification pour le commerce
  static Future<void> _createNotificationForCommerce(
    String commerceId,
    List<Map<String, dynamic>> vouchers,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': commerceId,
        'type': 'welcome_vouchers',
        'title': '4 bons cadeaux attribués !',
        'message':
            '4 bons de 50€ ont été automatiquement attribués à des membres VenteMoi',
        'data': {
          'vouchers_count': 4,
          'vouchers': vouchers
              .map((v) => {
                    'beneficiary': v['user']['name'],
                    'type': v['user']['type'],
                    'code': v['code'],
                  })
              .toList(),
        },
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la création de la notification: $e');
    }
  }

  /// Construit le HTML moderne pour les emails
  static String _buildModernMailHtml(String content) {
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
            transition: transform 0.2s;
        }

        .button:hover {
            transform: translateY(-2px);
        }

        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 20px 0;
        }

        .info-item {
            text-align: center;
            padding: 15px;
            background: #f8f8f8;
            border-radius: 8px;
        }

        .info-label {
            font-size: 14px;
            color: #888;
            margin-bottom: 5px;
        }

        .info-value {
            font-size: 20px;
            font-weight: bold;
            color: #333;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }

        th {
            background: #f5f5f5;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            border-bottom: 2px solid #e0e0e0;
        }

        td {
            padding: 12px;
            border-bottom: 1px solid #eee;
        }

        .divider {
            height: 1px;
            background: #e0e0e0;
            margin: 30px 0;
        }

        .footer {
            background: #f8f8f8;
            padding: 30px;
            text-align: center;
            color: #888;
            font-size: 14px;
        }

        .footer p {
            margin: 5px 0;
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
                grid-template-columns: 1fr;
            }

            .code-box {
                font-size: 20px;
                padding: 12px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            <div class="header">
                <div class="logo">
                    <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media" alt="VenteMoi">
                </div>
                <h1>VenteMoi</h1>
            </div>

            <div class="content">
                $content
            </div>

            <div class="footer">
                <p>© 2024 VenteMoi - Tous droits réservés</p>
                <p>Cet email vous a été envoyé automatiquement. Merci de ne pas y répondre.</p>
                <p style="margin-top: 15px;">
                    <a href="https://ventemoi.com" style="color: #ff7a00; text-decoration: none;">www.ventemoi.com</a>
                </p>
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
