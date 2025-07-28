const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialiser Admin SDK si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialiser Stripe avec gestion d'erreur
let stripe;
try {
  const stripeKey = functions.config().stripe?.secret;
  if (!stripeKey) {
    console.error("❌ Clé Stripe non configurée!");
    console.error(
      "Utilisez: firebase functions:config:set stripe.secret='sk_live_...'",
    );
  } else {
    stripe = require("stripe")(stripeKey);
    console.log("✅ Stripe initialisé avec succès");
  }
} catch (error) {
  console.error("❌ Erreur initialisation Stripe:", error);
}

// Fonction pour créer un customer Stripe
exports.createStripeCustomer = functions
  .region("europe-west1")
  .firestore.document("customers/{userId}")
  .onCreate(async (snap, context) => {
    const customerData = snap.data();
    const userId = context.params.userId;

    console.log("🔵 Début création customer Stripe");
    console.log("   UserId:", userId);
    console.log("   Email:", customerData.email);
    console.log("   Données reçues:", JSON.stringify(customerData));

    // Vérifications préliminaires
    if (!stripe) {
      console.error("❌ Stripe non initialisé");
      await snap.ref.update({
        error: {
          message: "Stripe non configuré sur le serveur",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      return null;
    }

    // Ne pas traiter les documents de test ou sans email
    if (userId.startsWith("TEST_") || !customerData.email) {
      console.log("⏭️ Document ignoré (test ou pas d'email)");
      return null;
    }

    // Si un stripeId existe déjà, ne pas recréer
    if (customerData.stripeId) {
      console.log("⚠️ Customer a déjà un stripeId:", customerData.stripeId);
      return null;
    }

    try {
      console.log("🔄 Création du customer dans Stripe...");

      // Créer le customer dans Stripe
      const stripeCustomer = await stripe.customers.create({
        email: customerData.email,
        metadata: {
          firebaseUID: userId,
          created_via: "cloud_function",
          environment: "production",
        },
      });

      console.log("✅ Customer Stripe créé avec succès:", stripeCustomer.id);

      // Mettre à jour le document Firestore
      await snap.ref.update({
        stripeId: stripeCustomer.id,
        stripeCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        stripeCustomerData: {
          id: stripeCustomer.id,
          created: stripeCustomer.created,
          email: stripeCustomer.email,
        },
      });

      console.log("✅ Document Firestore mis à jour");

      return {
        success: true,
        customerId: stripeCustomer.id,
        email: stripeCustomer.email,
      };
    } catch (error) {
      console.error("❌ Erreur création customer Stripe:");
      console.error("   Message:", error.message);
      console.error("   Type:", error.type);
      console.error("   Code:", error.code);
      console.error("   Stack:", error.stack);

      // Enregistrer l'erreur détaillée dans Firestore
      await snap.ref.update({
        error: {
          message: error.message,
          type: error.type,
          code: error.code,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          raw: error.raw ? error.raw.message : null,
        },
        stripeError: true,
      });

      return { success: false, error: error.message };
    }
  });

// Fonction HTTP callable pour forcer la création/sync d'un customer
exports.forceCreateStripeCustomer = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Vérifier l'authentification
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Vous devez être connecté",
      );
    }

    if (!stripe) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Stripe non configuré",
      );
    }

    const uid = context.auth.uid;
    const email = context.auth.token.email;

    console.log(`🔄 Force création customer pour: ${uid}`);

    try {
      // Vérifier si le customer existe déjà dans Firestore
      const customerRef = admin.firestore().collection("customers").doc(uid);
      const customerDoc = await customerRef.get();

      if (customerDoc.exists && customerDoc.data().stripeId) {
        // Vérifier que le customer existe vraiment dans Stripe
        const stripeId = customerDoc.data().stripeId;
        try {
          const existingCustomer = await stripe.customers.retrieve(stripeId);
          console.log("✅ Customer existe déjà:", stripeId);
          return {
            success: true,
            customerId: stripeId,
            message: "Customer existe déjà",
          };
        } catch (error) {
          console.log("⚠️ Customer n'existe pas dans Stripe, création...");
        }
      }

      // Créer le customer dans Stripe
      const stripeCustomer = await stripe.customers.create({
        email: email,
        metadata: {
          firebaseUID: uid,
          created_via: "force_create_function",
        },
      });

      console.log("✅ Customer créé:", stripeCustomer.id);

      // Sauvegarder dans Firestore
      await customerRef.set(
        {
          email: email,
          stripeId: stripeCustomer.id,
          created: admin.firestore.FieldValue.serverTimestamp(),
          stripeCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        success: true,
        customerId: stripeCustomer.id,
        message: "Customer créé avec succès",
      };
    } catch (error) {
      console.error("❌ Erreur:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });

// Fonction pour débugger la configuration
exports.debugStripeConfig = functions
  .region("europe-west1")
  .https.onRequest(async (req, res) => {
    try {
      const config = functions.config();
      const hasStripeKey = !!(config.stripe && config.stripe.secret);
      const keyPrefix = hasStripeKey
        ? config.stripe.secret.substring(0, 7)
        : "NON CONFIGURÉ";

      const debugInfo = {
        hasStripeKey: hasStripeKey,
        keyPrefix: keyPrefix,
        isTestKey: keyPrefix.startsWith("sk_test"),
        isLiveKey: keyPrefix.startsWith("sk_live"),
        timestamp: new Date().toISOString(),
        region: "europe-west1",
      };

      console.log("🔍 Debug config:", debugInfo);

      res.json(debugInfo);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
