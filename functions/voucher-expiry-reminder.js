const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialiser Admin SDK si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function programmée pour envoyer des rappels de bons cadeaux bientôt expirés
 * S'exécute tous les jours à 9h00
 */
exports.sendVoucherExpiryReminders = functions
  .region("europe-west1")
  .pubsub.schedule('0 9 * * *')
  .timeZone('Europe/Paris')
  .onRun(async (context) => {
    console.log('🔄 Début de la vérification des bons cadeaux bientôt expirés');

    try {
      const now = new Date();
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

      const threeDaysFromNow = new Date();
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

      // Récupérer les bons non utilisés qui expirent dans les 7 prochains jours
      const vouchersSnap = await admin.firestore()
        .collection('vouchers')
        .where('status', '==', 'active')
        .where('expiry_date', '>=', admin.firestore.Timestamp.fromDate(now))
        .where('expiry_date', '<=', admin.firestore.Timestamp.fromDate(sevenDaysFromNow))
        .get();

      console.log(`📊 ${vouchersSnap.size} bons cadeaux trouvés qui expirent dans les 7 prochains jours`);

      const reminders = {
        sevenDays: [],
        threeDays: [],
        oneDayOrLess: []
      };

      // Catégoriser les bons par urgence
      for (const doc of vouchersSnap.docs) {
        const voucher = doc.data();
        const expiryDate = voucher.expiry_date.toDate();
        const daysUntilExpiry = Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24));

        // Vérifier si on a déjà envoyé un rappel récemment
        const lastReminderSent = voucher.last_reminder_sent?.toDate();
        const daysSinceLastReminder = lastReminderSent
          ? Math.floor((now - lastReminderSent) / (1000 * 60 * 60 * 24))
          : null;

        // Déterminer si on doit envoyer un rappel
        let shouldSendReminder = false;
        let reminderType = '';

        if (daysUntilExpiry <= 1 && (!daysSinceLastReminder || daysSinceLastReminder >= 1)) {
          // Rappel urgent : 1 jour ou moins
          shouldSendReminder = true;
          reminderType = 'urgent';
          reminders.oneDayOrLess.push({ id: doc.id, ...voucher });
        } else if (daysUntilExpiry <= 3 && (!daysSinceLastReminder || daysSinceLastReminder >= 3)) {
          // Rappel 3 jours
          shouldSendReminder = true;
          reminderType = '3days';
          reminders.threeDays.push({ id: doc.id, ...voucher });
        } else if (daysUntilExpiry <= 7 && !lastReminderSent) {
          // Premier rappel à 7 jours
          shouldSendReminder = true;
          reminderType = '7days';
          reminders.sevenDays.push({ id: doc.id, ...voucher });
        }

        if (shouldSendReminder) {
          await sendReminderEmail(voucher, daysUntilExpiry, reminderType);

          // Mettre à jour le bon pour marquer l'envoi du rappel
          await admin.firestore()
            .collection('vouchers')
            .doc(doc.id)
            .update({
              last_reminder_sent: admin.firestore.FieldValue.serverTimestamp(),
              last_reminder_type: reminderType,
              days_until_expiry_at_reminder: daysUntilExpiry
            });
        }
      }

      // Logs de résumé
      console.log(`✅ Rappels envoyés :`);
      console.log(`   - 7 jours : ${reminders.sevenDays.length} bons`);
      console.log(`   - 3 jours : ${reminders.threeDays.length} bons`);
      console.log(`   - Urgent (≤1 jour) : ${reminders.oneDayOrLess.length} bons`);

      return null;
    } catch (error) {
      console.error('❌ Erreur lors de l\'envoi des rappels:', error);
      throw error;
    }
  });

/**
 * Envoie un email de rappel pour un bon cadeau
 */
async function sendReminderEmail(voucher, daysUntilExpiry, reminderType) {
  try {
    // Récupérer les informations de l'acheteur
    const buyerDoc = await admin.firestore()
      .collection('users')
      .doc(voucher.buyer_id)
      .get();

    if (!buyerDoc.exists) {
      console.log(`⚠️ Acheteur introuvable pour le bon ${voucher.code}`);
      return;
    }

    const buyerData = buyerDoc.data();
    const buyerEmail = buyerData.email;
    const buyerName = buyerData.name || 'Cher client';

    // Récupérer les informations de la boutique
    let shopName = 'la boutique';
    let usageConditions = '';
    if (voucher.boutique_id) {
      const shopDoc = await admin.firestore()
        .collection('establishments')
        .doc(voucher.boutique_id)
        .get();

      if (shopDoc.exists) {
        const shopData = shopDoc.data();
        shopName = shopData.name || 'la boutique';
        usageConditions = shopData.voucher_usage_conditions || '';
      }
    } else if (voucher.shop_id) {
      // Ancien système avec shop_id
      const shopQuery = await admin.firestore()
        .collection('establishments')
        .where('user_id', '==', voucher.shop_id)
        .limit(1)
        .get();

      if (!shopQuery.empty) {
        const shopData = shopQuery.docs[0].data();
        shopName = shopData.name || 'la boutique';
        usageConditions = shopData.voucher_usage_conditions || '';
      }
    }

    // Déterminer le sujet et l'urgence du message
    let subject = '';
    let urgencyColor = '#ff9500';
    let urgencyMessage = '';

    if (reminderType === 'urgent') {
      subject = `⚠️ URGENT : Votre bon cadeau expire ${daysUntilExpiry === 0 ? 'aujourd\'hui' : 'demain'} !`;
      urgencyColor = '#ff0000';
      urgencyMessage = daysUntilExpiry === 0
        ? '🔴 Ce bon expire AUJOURD\'HUI !'
        : '🟠 Ce bon expire DEMAIN !';
    } else if (reminderType === '3days') {
      subject = `⏰ Rappel : Votre bon cadeau expire dans ${daysUntilExpiry} jours`;
      urgencyColor = '#ff6b35';
      urgencyMessage = `⏰ Plus que ${daysUntilExpiry} jours pour utiliser votre bon !`;
    } else {
      subject = `📅 Information : Votre bon cadeau expire dans ${daysUntilExpiry} jours`;
      urgencyColor = '#ff9500';
      urgencyMessage = `📅 Il vous reste ${daysUntilExpiry} jours pour profiter de votre bon cadeau.`;
    }

    const emailHtml = buildReminderEmailHtml({
      buyerName,
      voucherCode: voucher.code,
      voucherValue: voucher.value || 50,
      shopName,
      expiryDate: voucher.expiry_date.toDate().toLocaleDateString('fr-FR'),
      daysUntilExpiry,
      urgencyColor,
      urgencyMessage,
      reminderType,
      usageConditions
    });

    // Envoyer l'email via la collection mail
    await admin.firestore().collection('mail').add({
      to: buyerEmail,
      message: {
        subject: subject,
        html: emailHtml,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    console.log(`📧 Rappel envoyé à ${buyerEmail} pour le bon ${voucher.code} (expire dans ${daysUntilExpiry} jours)`);
  } catch (error) {
    console.error(`❌ Erreur envoi email pour bon ${voucher.code}:`, error);
  }
}

/**
 * Construit le HTML de l'email de rappel
 */
function buildReminderEmailHtml(params) {
  const {
    buyerName,
    voucherCode,
    voucherValue,
    shopName,
    expiryDate,
    daysUntilExpiry,
    urgencyColor,
    urgencyMessage,
    reminderType,
    usageConditions
  } = params;

  return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rappel - Bon cadeau VenteMoi</title>
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
        .urgency-banner {
            background-color: ${urgencyColor};
            color: white;
            padding: 15px;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
        }
        .content {
            padding: 40px 30px;
            background: #ffffff;
        }
        .voucher-box {
            background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
            border: 2px dashed #ff9500;
            border-radius: 12px;
            padding: 25px;
            margin: 25px 0;
            text-align: center;
        }
        .voucher-code {
            font-size: 28px;
            font-weight: bold;
            color: #ff7a00;
            letter-spacing: 3px;
            margin: 10px 0;
        }
        .voucher-value {
            font-size: 36px;
            color: #ff7a00;
            font-weight: bold;
            margin: 15px 0;
        }
        .expiry-warning {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #ff9500 0%, #ff7a00 100%);
            color: white;
            padding: 15px 40px;
            text-decoration: none;
            border-radius: 25px;
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0;
            box-shadow: 0 4px 15px rgba(255, 122, 0, 0.3);
        }
        .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
            color: #888888;
            font-size: 14px;
        }
        .tips {
            background: #e8f4fd;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            ${reminderType === 'urgent' ? `<div class="urgency-banner">${urgencyMessage}</div>` : ''}

            <div class="header">
                <h1 style="color: white; margin: 0;">Vente Moi</h1>
                <p style="color: white; font-size: 18px; margin: 10px 0;">
                    Rappel - Bon cadeau bientôt expiré
                </p>
            </div>

            <div class="content">
                <h2 style="color: #ff7a00;">Bonjour ${buyerName},</h2>

                <p style="font-size: 16px;">
                    ${urgencyMessage}
                </p>

                <div class="voucher-box">
                    <p style="margin: 0; color: #666;">Votre bon cadeau chez</p>
                    <h3 style="margin: 10px 0; color: #333;">${shopName}</h3>
                    <div class="voucher-code">${voucherCode}</div>
                    <div class="voucher-value">${voucherValue}€</div>
                    <p style="color: #666; margin: 10px 0;">
                        <strong>Expire le : ${expiryDate}</strong>
                    </p>
                </div>

                ${reminderType === 'urgent' ? `
                <div class="expiry-warning">
                    <strong>⚠️ Attention :</strong> Ce bon cadeau ${daysUntilExpiry === 0 ? 'expire aujourd\'hui' : 'expire demain'}.
                    Après cette date, il ne sera plus utilisable et la valeur sera perdue.
                </div>
                ` : ''}

                <div class="tips">
                    <h3 style="color: #ff7a00; margin-top: 0;">💡 Comment utiliser votre bon ?</h3>
                    <ol style="margin: 10px 0; padding-left: 20px;">
                        <li>Rendez-vous chez <strong>${shopName}</strong></li>
                        <li>Présentez le code <strong>${voucherCode}</strong> au moment du paiement</li>
                        <li>Le montant sera déduit de votre achat</li>
                    </ol>
                </div>

                ${usageConditions ? `
                <div style="background: #fff9e6; border: 1px solid #ffca28; border-radius: 8px; padding: 15px; margin: 20px 0;">
                    <h3 style="color: #f57c00; margin-top: 0; margin-bottom: 10px;">
                        ⚠️ Conditions d'utilisation
                    </h3>
                    <p style="color: #666; margin: 0; white-space: pre-line;">
                        ${usageConditions}
                    </p>
                </div>
                ` : ''}

                <div style="text-align: center;">
                    <a href="https://app.ventemoi.fr" class="cta-button">
                        Voir mes bons cadeaux
                    </a>
                </div>

                <p style="color: #666; font-size: 14px; margin-top: 30px;">
                    <em>Astuce : Planifiez votre visite chez ${shopName} dans les prochains jours pour ne pas oublier d'utiliser votre bon !</em>
                </p>
            </div>

            <div class="footer">
                <p>© 2024 Vente Moi - Tous droits réservés</p>
                <p>
                    Vous recevez cet email car vous avez un bon cadeau qui arrive bientôt à expiration.<br>
                    Pour toute question, contactez <a href="mailto:support@ventemoi.com">support@ventemoi.com</a>
                </p>
            </div>
        </div>
    </div>
</body>
</html>
  `;
}

/**
 * Fonction manuelle pour tester l'envoi de rappels
 */
exports.testVoucherReminders = functions
  .region("europe-west1")
  .https.onRequest(async (req, res) => {
    try {
      console.log('🔧 Test manuel des rappels de bons cadeaux');

      // Exécuter la fonction de rappels
      await exports.sendVoucherExpiryReminders({ data: null });

      res.json({
        success: true,
        message: 'Test des rappels exécuté avec succès'
      });
    } catch (error) {
      console.error('❌ Erreur test rappels:', error);
      res.status(500).json({ error: error.message });
    }
  });

module.exports = exports;