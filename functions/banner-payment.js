const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialiser Admin SDK si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Fonction pour traiter les paiements de bannières après webhook Stripe
 * Appelée automatiquement par l'extension Stripe Firebase
 */
exports.processBannerPaymentSuccess = functions
  .region("europe-west1")
  .firestore.document('customers/{userId}/checkout_sessions/{sessionId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Vérifier si le paiement vient de réussir
    if (newData.status !== 'complete' || previousData.status === 'complete') {
      return null;
    }

    // Vérifier que c'est bien un paiement de bannière
    if (newData.metadata && newData.metadata.product === 'bandeau_hebdo') {
      const establishmentId = newData.metadata.establishment_id;
      const userId = newData.metadata.user_id;
      const startDateStr = newData.metadata.start_date;

      try {
        const startDate = new Date(startDateStr);
        const endDate = new Date(startDate);
        endDate.setDate(endDate.getDate() + 7);

        // Récupérer les données de l'offre en attente si elle existe
        const pendingOffersQuery = await admin.firestore()
          .collection('pending_banner_offers')
          .where('stripe_session_id', '==', context.params.sessionId)
          .limit(1)
          .get();

        let offerData;
        if (!pendingOffersQuery.empty) {
          const pendingDoc = pendingOffersQuery.docs[0];
          offerData = pendingDoc.data();

          // Supprimer l'offre en attente
          await pendingDoc.ref.delete();
        } else {
          // Créer les données de base si pas d'offre en attente
          console.log('Aucune offre en attente trouvée, création des données de base');
          offerData = {
            user_id: userId,
            establishment_id: establishmentId,
            start_date: admin.firestore.Timestamp.fromDate(startDate),
            end_date: admin.firestore.Timestamp.fromDate(endDate),
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          };
        }

        // Créer l'offre spéciale active
        const specialOffer = {
          ...offerData,
          status: 'active',
          payment_status: 'paid',
          payment_date: admin.firestore.FieldValue.serverTimestamp(),
          payment_amount: newData.amount_total / 100, // Convertir de centimes en euros
          payment_currency: newData.currency || 'eur',
          stripe_session_id: context.params.sessionId,
          stripe_payment_intent: newData.payment_intent,
          is_active: true,
          priority: 100, // Priorité par défaut pour les offres payantes
          background_color: '#FF6B35', // Couleur par défaut
          text_color: '#FFFFFF',
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Sauvegarder dans la collection des offres spéciales
        await admin.firestore()
          .collection('special_offers')
          .add(specialOffer);

        // Envoyer un email de confirmation
        await sendConfirmationEmail(offerData, newData);

        // Log pour suivi
        await admin.firestore()
          .collection('payment_logs')
          .add({
            type: 'banner_payment_success',
            establishment_id: establishmentId,
            userId: userId,
            amount: newData.amount_total / 100,
            currency: newData.currency || 'eur',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log('✅ Bannière publicitaire activée avec succès pour l\'établissement:', establishmentId);
      } catch (error) {
        console.error('Erreur activation bannière:', error);
      }
    }

    return null;
  });

/**
 * Envoyer un email de confirmation après paiement
 */
async function sendConfirmationEmail(offerData, session) {
  try {
    const emailHtml = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f8b02a 0%, #e5a025 100%); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; border-radius: 0 0 10px 10px; }
        .success-box { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .details { background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Paiement confirmé !</h1>
        </div>
        <div class="content">
            <div class="success-box">
                <h2 style="color: #155724;">Votre bannière publicitaire est maintenant active</h2>
            </div>

            <p>Bonjour,</p>

            <p>Nous vous confirmons que votre paiement de <strong>${session.amount_total / 100}€</strong> a été reçu avec succès.</p>

            <div class="details">
                <h3>Détails de votre bannière :</h3>
                <ul>
                    <li><strong>Titre :</strong> ${offerData.title}</li>
                    <li><strong>Établissement :</strong> ${offerData.establishment_name}</li>
                    <li><strong>Période :</strong> Du ${new Date(offerData.start_date.toDate()).toLocaleDateString('fr-FR')} au ${new Date(offerData.end_date.toDate()).toLocaleDateString('fr-FR')}</li>
                    <li><strong>Durée :</strong> 7 jours</li>
                </ul>
            </div>

            <p>Votre bannière est maintenant visible dans la section "Offres du moment" de l'application VenteMoi.</p>

            <p>Si vous avez des questions, n'hésitez pas à nous contacter à <a href="mailto:support@ventemoi.com">support@ventemoi.com</a></p>

            <div class="footer">
                <p>© 2024 VenteMoi - Tous droits réservés</p>
                <p>Cet email est un reçu de paiement. Conservez-le pour vos archives.</p>
            </div>
        </div>
    </div>
</body>
</html>
    `;

    // Envoyer l'email via la collection mail
    await admin.firestore().collection('mail').add({
      to: [offerData.contact_phone], // Utiliser l'email de l'utilisateur
      message: {
        subject: '✅ Confirmation - Votre bannière publicitaire est active',
        html: emailHtml,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });
  } catch (error) {
    console.error('Erreur envoi email confirmation:', error);
  }
}

/**
 * Cloud Function programmée pour désactiver les bannières expirées
 * S'exécute tous les jours à minuit
 */
exports.deactivateExpiredBanners = functions
  .region("europe-west1")
  .pubsub.schedule('0 0 * * *')
  .timeZone('Europe/Paris')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Récupérer toutes les offres actives
      const activeOffersSnap = await admin.firestore()
        .collection('special_offers')
        .where('is_active', '==', true)
        .where('status', '==', 'active')
        .get();

      const batch = admin.firestore().batch();
      let deactivatedCount = 0;

      activeOffersSnap.forEach(doc => {
        const offer = doc.data();

        // Vérifier si l'offre a expiré
        if (offer.end_date && offer.end_date.toDate() < now.toDate()) {
          batch.update(doc.ref, {
            is_active: false,
            status: 'expired',
            deactivated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          deactivatedCount++;
        }
      });

      if (deactivatedCount > 0) {
        await batch.commit();
        console.log(`✅ ${deactivatedCount} bannières expirées ont été désactivées`);
      } else {
        console.log('ℹ️ Aucune bannière à désactiver');
      }

      return null;
    } catch (error) {
      console.error('❌ Erreur désactivation bannières expirées:', error);
      throw error;
    }
  });

module.exports = exports;