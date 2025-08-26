import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sponsorship.dart';
import '../classes/unique_controllers.dart';

class SponsorshipService {
  static final FirebaseFirestore _firestore =
      UniquesControllers().data.firebaseFirestore;

  /// Vérifie si un utilisateur a un parrain et retourne ses infos
  static Future<Map<String, dynamic>?> checkForSponsor(String userEmail) async {
    try {
      final sponsorshipQuery = await _firestore
          .collection('sponsorships')
          .where('sponsored_emails', arrayContains: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (sponsorshipQuery.docs.isEmpty) return null;

      final sponsorshipDoc = sponsorshipQuery.docs.first;
      final sponsorId = sponsorshipDoc.data()['user_id'];

      // Récupérer les infos du parrain
      final sponsorDoc =
          await _firestore.collection('users').doc(sponsorId).get();
      if (!sponsorDoc.exists) return null;

      return {
        'sponsor_id': sponsorId,
        'sponsor_data': sponsorDoc.data(),
        'sponsorship_doc_id': sponsorshipDoc.id,
      };
    } catch (e) {
      return null;
    }
  }

  /// Attribue les points de parrainage pour un particulier (40% des points reçus)
  static Future<void> attributeParticulierSponsorshipPoints({
    required String sponsorId,
    required String filleulId,
    required String filleulEmail,
    required int basePoints,
    required String sponsorshipDocId,
  }) async {
    try {
      final batch = _firestore.batch();
      final pointsForSponsor = (basePoints * 0.4).floor(); // 40%

      if (pointsForSponsor <= 0) return;

      // 1. Mettre à jour les points du parrain
      final sponsorWalletQuery = await _firestore
          .collection('wallets')
          .where('user_id', isEqualTo: sponsorId)
          .limit(1)
          .get();

      if (sponsorWalletQuery.docs.isNotEmpty) {
        final walletDoc = sponsorWalletQuery.docs.first;
        final currentPoints = walletDoc.data()['points'] ?? 0;

        batch.update(walletDoc.reference, {
          'points': currentPoints + pointsForSponsor,
        });
      }

      // 2. Mettre à jour le document sponsorship avec l'historique
      final sponsorshipRef =
          _firestore.collection('sponsorships').doc(sponsorshipDocId);
      final sponsorshipSnap = await sponsorshipRef.get();

      if (sponsorshipSnap.exists) {
        final sponsorship = Sponsorship.fromDocument(sponsorshipSnap);
        final details = sponsorship.sponsorshipDetails;

        // Créer ou mettre à jour les détails du filleul
        final detail = details[filleulEmail.toLowerCase()] ??
            SponsorshipDetail(
              userId: filleulId,
              userType: 'Particulier',
              isActive: true,
              joinDate: DateTime.now(),
            );

        // Ajouter l'historique
        final newHistory = EarningHistory(
          date: DateTime.now(),
          points: pointsForSponsor,
          reason: 'attribution_40_percent',
          sourceUserId: filleulId,
        );

        final updatedDetail = SponsorshipDetail(
          userId: detail.userId,
          userType: detail.userType,
          isActive: true,
          totalEarnings: detail.totalEarnings + pointsForSponsor,
          joinDate: detail.joinDate,
          earningsHistory: [...detail.earningsHistory, newHistory],
        );

        details[filleulEmail.toLowerCase()] = updatedDetail;

        // Calculer le total des gains
        int totalEarnings = 0;
        details.forEach((_, detail) {
          totalEarnings += detail.totalEarnings;
        });

        batch.update(sponsorshipRef, {
          'sponsorship_details':
              details.map((key, value) => MapEntry(key, value.toMap())),
          'total_earnings': totalEarnings,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 3. Créer une notification dans sponsorship_rewards pour tracer
      final notificationRef =
          _firestore.collection('sponsorship_rewards').doc();
      batch.set(notificationRef, {
        'sponsor_id': sponsorId,
        'filleul_id': filleulId,
        'filleul_email': filleulEmail,
        'points_earned': pointsForSponsor,
        'base_points': basePoints,
        'percentage': 40,
        'reward_type': 'attribution_percentage',
        'created_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 4. Envoyer un email de notification
      await _sendSponsorshipRewardEmail(
        sponsorId: sponsorId,
        filleulEmail: filleulEmail,
        pointsWon: pointsForSponsor,
        reason: 'attribution',
      );
    } catch (e) {
    }
  }

  /// Attribue les 50 points pour un non-particulier (Boutique, Entreprise)
  static Future<void> attributeNonParticulierSponsorshipPoints({
    required String sponsorId,
    required String filleulId,
    required String filleulEmail,
    required String filleulType,
    required String sponsorshipDocId,
  }) async {
    try {
      final batch = _firestore.batch();
      const pointsForSponsor = 50;

      // 1. Vérifier si le bonus a déjà été attribué
      final sponsorshipRef =
          _firestore.collection('sponsorships').doc(sponsorshipDocId);
      final sponsorshipSnap = await sponsorshipRef.get();

      if (!sponsorshipSnap.exists) return;

      final sponsorship = Sponsorship.fromDocument(sponsorshipSnap);
      final existingDetail =
          sponsorship.sponsorshipDetails[filleulEmail.toLowerCase()];

      // Si le bonus a déjà été donné, on ne le redonne pas
      if (existingDetail != null && existingDetail.totalEarnings > 0) {
        return;
      }

      // 2. Mettre à jour les points du parrain
      final sponsorWalletQuery = await _firestore
          .collection('wallets')
          .where('user_id', isEqualTo: sponsorId)
          .limit(1)
          .get();

      if (sponsorWalletQuery.docs.isNotEmpty) {
        final walletDoc = sponsorWalletQuery.docs.first;
        final currentPoints = walletDoc.data()['points'] ?? 0;

        batch.update(walletDoc.reference, {
          'points': currentPoints + pointsForSponsor,
        });
      }

      // 3. Mettre à jour le document sponsorship
      final details = sponsorship.sponsorshipDetails;

      final newHistory = EarningHistory(
        date: DateTime.now(),
        points: pointsForSponsor,
        reason: 'signup_bonus',
        sourceUserId: filleulId,
      );

      final updatedDetail = SponsorshipDetail(
        userId: filleulId,
        userType: filleulType,
        isActive: true,
        totalEarnings: pointsForSponsor,
        joinDate: DateTime.now(),
        hasPaid: true,
        hasAcceptedCGU: true,
        earningsHistory: [newHistory],
      );

      details[filleulEmail.toLowerCase()] = updatedDetail;

      // Calculer le total des gains
      int totalEarnings = 0;
      details.forEach((_, detail) {
        totalEarnings += detail.totalEarnings;
      });

      batch.update(sponsorshipRef, {
        'sponsorship_details':
            details.map((key, value) => MapEntry(key, value.toMap())),
        'total_earnings': totalEarnings,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Créer une notification
      final notificationRef =
          _firestore.collection('sponsorship_rewards').doc();
      batch.set(notificationRef, {
        'sponsor_id': sponsorId,
        'filleul_id': filleulId,
        'filleul_email': filleulEmail,
        'filleul_type': filleulType,
        'points_earned': pointsForSponsor,
        'reward_type': 'signup_bonus',
        'created_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 5. Envoyer un email de notification
      await _sendSponsorshipRewardEmail(
        sponsorId: sponsorId,
        filleulEmail: filleulEmail,
        pointsWon: pointsForSponsor,
        reason: 'signup',
      );
    } catch (e) {
    }
  }

  /// Envoie un email de notification pour les gains de parrainage
  static Future<void> _sendSponsorshipRewardEmail({
    required String sponsorId,
    required String filleulEmail,
    required int pointsWon,
    required String reason,
  }) async {
    try {
      // Récupérer les infos du parrain
      final sponsorDoc =
          await _firestore.collection('users').doc(sponsorId).get();
      if (!sponsorDoc.exists) return;

      final sponsorData = sponsorDoc.data()!;
      final sponsorEmail = sponsorData['email'] ?? '';
      final sponsorName = sponsorData['name'] ?? 'Cher parrain';

      // Créer et envoyer l'email directement
      final subject = 'Parrainage : +$pointsWon points';

      final reasonText = reason == 'attribution'
          ? 'Votre filleul vient de recevoir des points et vous bénéficiez de 40% de ses gains !'
          : 'Votre filleul entreprise/boutique vient de valider son inscription et vous recevez 50 points de bonus !';

      final content = '''
        <h2>Félicitations $sponsorName ! 🎉</h2>
        <p>
          Vous venez de gagner <strong style="color: #ff7a00; font-size: 20px;">$pointsWon points</strong>
          grâce au parrainage de <strong>$filleulEmail</strong>.
        </p>

        <div class="highlight-box">
          <p style="font-size: 14px; color: #555; margin: 0;">
            $reasonText
          </p>
        </div>

        <p>
          Continuez à parrainer vos proches pour gagner encore plus de points !
        </p>

        <p style="margin-top: 30px;">
          À très bientôt,<br>
          L'équipe Vente Moi
        </p>
      ''';

      final mailDoc = {
        "to": sponsorEmail.trim(),
        "message": {
          "subject": subject,
          "html": _buildMailHtml(content),
        },
      };

      await _firestore.collection('mail').add(mailDoc);
    } catch (e) {
    }
  }

  /// Construit le HTML de l'email avec le template
  static String _buildMailHtml(String content) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vente Moi</title>
    <style>
        body {
            font-family: Arial, sans-serif;
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
            background: linear-gradient(135deg, #ff9500 0%, #ff7a00 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .logo {
            display: inline-block;
            background: rgba(255, 255, 255, 0.95);
            padding: 15px 25px;
            border-radius: 12px;
            margin-bottom: 20px;
        }
        .content {
            padding: 40px 30px;
            background: #ffffff;
        }
        .content h1 {
            color: #ff7a00;
            font-size: 24px;
            margin-bottom: 20px;
        }
        .content h2 {
            color: #ff7a00;
            font-size: 22px;
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
            background: #e8f4fd;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
            color: #888888;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            <div class="header">
                <div class="logo">
                    <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media"
                         alt="Vente Moi" height="40">
                </div>
                <h1 style="color: white; margin: 0;">Vente Moi</h1>
            </div>
            <div class="content">
                $content
            </div>
            <div class="footer">
                <p>© 2024 Vente Moi - Tous droits réservés</p>
                <p>Cet email vous a été envoyé automatiquement. Merci de ne pas y répondre.</p>
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
