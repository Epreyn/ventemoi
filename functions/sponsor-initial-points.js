const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialiser Admin SDK si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Fonction pour attribuer les 100 points initiaux aux sponsors existants
 * Cette fonction peut être appelée manuellement ou programmée
 */
exports.fixSponsorInitialPoints = functions
  .region("europe-west1")
  .https.onRequest(async (req, res) => {
    try {
      console.log("🔄 Début de la correction des points sponsors");

      // Récupérer tous les sponsors
      const userTypesSnap = await admin.firestore()
        .collection('user_types')
        .where('name', '==', 'Sponsor')
        .limit(1)
        .get();

      if (userTypesSnap.empty) {
        res.status(404).json({ error: "Type 'Sponsor' non trouvé" });
        return;
      }

      const sponsorTypeId = userTypesSnap.docs[0].id;

      // Récupérer tous les utilisateurs de type Sponsor
      const sponsorsSnap = await admin.firestore()
        .collection('users')
        .where('user_type_id', '==', sponsorTypeId)
        .get();

      console.log(`📊 ${sponsorsSnap.size} sponsors trouvés`);

      const batch = admin.firestore().batch();
      let updatedCount = 0;

      // Pour chaque sponsor
      for (const sponsorDoc of sponsorsSnap.docs) {
        const sponsorId = sponsorDoc.id;

        // Récupérer le wallet du sponsor
        const walletSnap = await admin.firestore()
          .collection('wallets')
          .where('user_id', '==', sponsorId)
          .limit(1)
          .get();

        if (!walletSnap.empty) {
          const walletDoc = walletSnap.docs[0];
          const walletData = walletDoc.data();
          const currentPoints = walletData.points || 0;

          // Si le sponsor a 0 points, lui donner les 100 points initiaux
          if (currentPoints === 0) {
            batch.update(walletDoc.ref, {
              points: 100,
              initial_points_granted: true,
              initial_points_granted_at: admin.firestore.FieldValue.serverTimestamp()
            });
            updatedCount++;
            console.log(`✅ Sponsor ${sponsorDoc.data().email} : 100 points ajoutés`);
          } else {
            console.log(`ℹ️ Sponsor ${sponsorDoc.data().email} a déjà ${currentPoints} points`);
          }
        } else {
          // Créer un wallet s'il n'existe pas
          const newWalletRef = admin.firestore().collection('wallets').doc();
          batch.set(newWalletRef, {
            user_id: sponsorId,
            points: 100,
            coupons: 0,
            bank_details: {
              iban: '',
              bic: '',
              holder: ''
            },
            initial_points_granted: true,
            initial_points_granted_at: admin.firestore.FieldValue.serverTimestamp(),
            created_at: admin.firestore.FieldValue.serverTimestamp()
          });
          updatedCount++;
          console.log(`✅ Wallet créé pour sponsor ${sponsorDoc.data().email} avec 100 points`);
        }
      }

      // Appliquer toutes les modifications
      if (updatedCount > 0) {
        await batch.commit();
        console.log(`✅ ${updatedCount} wallets de sponsors mis à jour`);
      }

      res.json({
        success: true,
        message: `${updatedCount} sponsors mis à jour sur ${sponsorsSnap.size} trouvés`,
        totalSponsors: sponsorsSnap.size,
        updatedSponsors: updatedCount
      });

    } catch (error) {
      console.error("❌ Erreur correction points sponsors:", error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Fonction automatique pour attribuer les 100 points aux nouveaux sponsors
 * Se déclenche lors de la création d'un establishment de type Sponsor
 */
exports.grantInitialSponsorPoints = functions
  .region("europe-west1")
  .firestore.document('establishments/{establishmentId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const userId = data.user_id;

      if (!userId) return null;

      // Vérifier si c'est un sponsor
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) return null;

      const userData = userDoc.data();
      const userTypeId = userData.user_type_id;

      // Récupérer le type d'utilisateur
      const userTypeDoc = await admin.firestore()
        .collection('user_types')
        .doc(userTypeId)
        .get();

      if (!userTypeDoc.exists) return null;

      const userTypeName = userTypeDoc.data().name;

      // Si c'est un sponsor
      if (userTypeName === 'Sponsor') {
        // Vérifier le wallet
        const walletSnap = await admin.firestore()
          .collection('wallets')
          .where('user_id', '==', userId)
          .limit(1)
          .get();

        if (!walletSnap.empty) {
          const walletDoc = walletSnap.docs[0];
          const walletData = walletDoc.data();

          // Si le sponsor n'a pas encore reçu ses points initiaux
          if (!walletData.initial_points_granted && walletData.points === 0) {
            await walletDoc.ref.update({
              points: 100,
              initial_points_granted: true,
              initial_points_granted_at: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`✅ 100 points initiaux attribués au sponsor ${userData.email}`);
          }
        }
      }

      return null;
    } catch (error) {
      console.error("❌ Erreur attribution points sponsor:", error);
      return null;
    }
  });

module.exports = exports;