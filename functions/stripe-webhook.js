const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);

// Initialiser Firebase Admin si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Endpoint webhook pour Stripe
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    // Vérifier la signature du webhook
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error("⚠️  Webhook signature verification failed:", err);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Gérer l'événement
  switch (event.type) {
    case "checkout.session.completed":
      const session = event.data.object;
      console.log("✅ Checkout session completed:", session.id);

      try {
        await handleCheckoutSessionCompleted(session);
      } catch (error) {
        console.error("❌ Error handling checkout session:", error);
      }
      break;

    case "payment_intent.succeeded":
      const paymentIntent = event.data.object;
      console.log("💳 Payment intent succeeded:", paymentIntent.id);
      break;

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  // Retourner une réponse 200 pour confirmer la réception
  res.json({ received: true });
});

// Fonction pour traiter une session de checkout complétée
async function handleCheckoutSessionCompleted(session) {
  const metadata = session.metadata || {};
  const userId = metadata.user_id;
  const purchaseType = metadata.purchase_type;
  const userType = metadata.user_type;

  console.log("📋 Metadata:", metadata);

  if (!userId) {
    console.error("❌ No user_id in metadata");
    return;
  }

  // Trouver l'établissement de l'utilisateur
  const establishmentQuery = await db
    .collection("establishments")
    .where("user_id", "==", userId)
    .limit(1)
    .get();

  if (establishmentQuery.empty) {
    console.error("❌ No establishment found for user:", userId);
    return;
  }

  const establishmentDoc = establishmentQuery.docs[0];
  const establishmentRef = establishmentDoc.ref;

  // Mettre à jour l'établissement selon le type d'achat
  if (
    purchaseType === "first_year_annual" ||
    purchaseType === "first_year_monthly"
  ) {
    const subscriptionType =
      purchaseType === "first_year_annual" ? "annual" : "monthly";

    await establishmentRef.update({
      has_accepted_contract: true,
      has_active_subscription: true,
      subscription_status: subscriptionType,
      subscription_start_date: admin.firestore.FieldValue.serverTimestamp(),
      subscription_end_date: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // +1 an
      ),
      payment_option: subscriptionType,
      stripe_session_id: session.id,
      stripe_customer_id: session.customer,
      temporary_mode: false,
    });

    console.log("✅ Establishment updated with subscription");

    // Créer le bon cadeau de bienvenue
    await createWelcomeGiftVoucher(establishmentDoc.id);

    // Si nécessaire, créer une subscription récurrente
    if (
      metadata.needs_subscription === "true" &&
      metadata.subscription_price_id
    ) {
      await createRecurringSubscription(
        session.customer,
        metadata.subscription_price_id,
        establishmentDoc.id,
      );
    }
  } else if (metadata.type === "additional_category_slot") {
    // Ajouter un slot de catégorie
    const currentSlots = establishmentDoc.data().enterprise_category_slots || 2;

    await establishmentRef.update({
      enterprise_category_slots: currentSlots + 1,
    });

    console.log("✅ Added category slot. New total:", currentSlots + 1);
  }

  // Marquer la session comme traitée dans Firestore
  const sessionRef = db
    .collection("customers")
    .doc(userId)
    .collection("checkout_sessions")
    .doc(session.id.replace("cs_", ""));

  // Vérifier si le document existe
  const sessionDoc = await sessionRef.get();
  if (sessionDoc.exists) {
    await sessionRef.update({
      payment_status: "paid",
      status: "complete",
      processed: true,
      processed_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

// Créer un bon cadeau de bienvenue
async function createWelcomeGiftVoucher(establishmentId) {
  const code = `WELCOME-${Date.now()}`;

  await db.collection("gift_vouchers").add({
    establishment_id: establishmentId,
    amount: 50.0,
    type: "welcome",
    status: "active",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    expires_at: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // +1 an
    ),
    code: code,
  });

  console.log("🎁 Welcome gift voucher created:", code);
}

// Créer une subscription récurrente
async function createRecurringSubscription(
  customerId,
  priceId,
  establishmentId,
) {
  try {
    // Créer la subscription avec un délai d'un an
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [
        {
          price: priceId,
        },
      ],
      trial_end: Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60, // Trial d'un an
      metadata: {
        establishment_id: establishmentId,
      },
    });

    console.log("🔄 Recurring subscription created:", subscription.id);

    // Sauvegarder l'ID de la subscription
    await db.collection("establishments").doc(establishmentId).update({
      stripe_subscription_id: subscription.id,
    });
  } catch (error) {
    console.error("❌ Error creating subscription:", error);
  }
}

// Alternative : Fonction callable pour marquer manuellement un paiement comme réussi
exports.confirmPaymentSuccess = functions.https.onCall(
  async (data, context) => {
    // Vérifier l'authentification
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
      );
    }

    const userId = context.auth.uid;

    try {
      // Trouver l'établissement
      const establishmentQuery = await db
        .collection("establishments")
        .where("user_id", "==", userId)
        .limit(1)
        .get();

      if (establishmentQuery.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "No establishment found",
        );
      }

      const establishmentDoc = establishmentQuery.docs[0];
      const establishmentRef = establishmentDoc.ref;

      // Mettre à jour l'établissement
      await establishmentRef.update({
        has_accepted_contract: true,
        has_active_subscription: true,
        subscription_status: data.subscriptionType || "monthly",
        subscription_start_date: admin.firestore.FieldValue.serverTimestamp(),
        subscription_end_date: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        ),
        payment_option: data.subscriptionType || "monthly",
        manual_activation: true,
      });

      // Créer le bon cadeau
      await createWelcomeGiftVoucher(establishmentDoc.id);

      return { success: true, message: "Payment confirmed successfully" };
    } catch (error) {
      console.error("Error confirming payment:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Error processing payment confirmation",
      );
    }
  },
);
