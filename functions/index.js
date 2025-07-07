const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialiser Stripe avec la clé de configuration
const stripe = require("stripe")(functions.config().stripe.secret);

admin.initializeApp();

// Fonction pour créer un customer Stripe
exports.createStripeCustomer = functions
  .region("europe-west1") // Changez selon votre région
  .firestore.document("customers/{userId}")
  .onCreate(async (snap, context) => {
    const customerData = snap.data();
    const userId = context.params.userId;

    console.log("🔵 Création customer Stripe pour:", userId);

    // Ne pas traiter les documents de test
    if (userId.startsWith("TEST_")) {
      console.log("⏭️ Document de test ignoré");
      return null;
    }

    try {
      // Créer le customer dans Stripe
      const stripeCustomer = await stripe.customers.create({
        email: customerData.email,
        metadata: {
          firebaseUID: userId,
        },
      });

      console.log("✅ Customer Stripe créé:", stripeCustomer.id);

      // Mettre à jour le document Firestore avec le stripeId
      await snap.ref.update({
        stripeId: stripeCustomer.id,
      });

      return { success: true, customerId: stripeCustomer.id };
    } catch (error) {
      console.error("❌ Erreur création customer:", error);

      // Enregistrer l'erreur dans Firestore
      await snap.ref.update({
        error: {
          message: error.message,
          code: error.code,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        },
      });

      return { success: false, error: error.message };
    }
  });
