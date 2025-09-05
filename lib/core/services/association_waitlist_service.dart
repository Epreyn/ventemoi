import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AssociationWaitlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Vérifie si une nouvelle association peut être visible
  /// Retourne true si elle peut être visible, false sinon
  static Future<bool> canAssociationBeVisible() async {
    try {
      // Compter le nombre de boutiques actives
      final boutiqueTypeDoc = await _firestore
          .collection('user_types')
          .where('name', isEqualTo: 'Boutique')
          .limit(1)
          .get();
      
      if (boutiqueTypeDoc.docs.isEmpty) return false;
      
      final boutiqueTypeId = boutiqueTypeDoc.docs.first.id;
      
      // Compter les établissements de type boutique qui sont visibles
      final boutiquesCount = await _firestore
          .collection('establishments')
          .where('user_type_id', isEqualTo: boutiqueTypeId)
          .where('is_visible', isEqualTo: true)
          .count()
          .get();
      
      final totalBoutiques = boutiquesCount.count ?? 0;
      
      // Compter le nombre d'associations visibles
      final associationTypeDoc = await _firestore
          .collection('user_types')
          .where('name', isEqualTo: 'Association')
          .limit(1)
          .get();
      
      if (associationTypeDoc.docs.isEmpty) return true; // Pas d'associations encore
      
      final associationTypeId = associationTypeDoc.docs.first.id;
      
      final associationsCount = await _firestore
          .collection('establishments')
          .where('user_type_id', isEqualTo: associationTypeId)
          .where('is_visible', isEqualTo: true)
          .where('force_visible_override', isEqualTo: false) // Ne pas compter les overrides admin
          .count()
          .get();
      
      final visibleAssociations = associationsCount.count ?? 0;
      
      // Une association peut être visible seulement si le nombre d'associations
      // visibles est strictement inférieur au nombre de boutiques
      return visibleAssociations < totalBoutiques;
    } catch (e) {
      print('Erreur dans canAssociationBeVisible: $e');
      return false;
    }
  }
  
  /// Ajoute une association à la liste d'attente
  static Future<void> addToWaitlist(String establishmentId) async {
    try {
      await _firestore.collection('association_waitlist').add({
        'establishment_id': establishmentId,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'processed': false,
      });
    } catch (e) {
      print('Erreur lors de l\'ajout à la liste d\'attente: $e');
    }
  }
  
  /// Traite la liste d'attente quand une nouvelle boutique s'inscrit
  static Future<void> processWaitlistOnNewBoutique() async {
    try {
      // Vérifier s'il y a des associations en attente
      final waitlistSnapshot = await _firestore
          .collection('association_waitlist')
          .where('status', isEqualTo: 'waiting')
          .where('processed', isEqualTo: false)
          .orderBy('created_at')
          .limit(1)
          .get();
      
      if (waitlistSnapshot.docs.isEmpty) return;
      
      // Vérifier si on peut rendre une association visible
      final canBeVisible = await canAssociationBeVisible();
      if (!canBeVisible) return;
      
      // Traiter la première association en attente
      final waitlistDoc = waitlistSnapshot.docs.first;
      final establishmentId = waitlistDoc.data()['establishment_id'];
      
      // Vérifier que l'association a bien 15+ affiliés
      final establishmentDoc = await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .get();
      
      if (!establishmentDoc.exists) {
        // Marquer comme traité si l'établissement n'existe plus
        await waitlistDoc.reference.update({
          'processed': true,
          'status': 'invalid',
          'processed_at': FieldValue.serverTimestamp(),
        });
        return;
      }
      
      final affiliatesCount = establishmentDoc.data()?['affiliates_count'] ?? 0;
      
      if (affiliatesCount >= 15) {
        // Rendre l'association visible
        await establishmentDoc.reference.update({
          'is_visible': true,
          'became_visible_at': FieldValue.serverTimestamp(),
        });
        
        // Marquer comme traité dans la liste d'attente
        await waitlistDoc.reference.update({
          'processed': true,
          'status': 'activated',
          'processed_at': FieldValue.serverTimestamp(),
        });
        
        // Notifier l'association par email
        await _notifyAssociationActivation(establishmentDoc.id);
      }
    } catch (e) {
      print('Erreur lors du traitement de la liste d\'attente: $e');
    }
  }
  
  /// Sélectionne une association visible aléatoirement pour recevoir un bon
  static Future<Map<String, dynamic>?> getRandomVisibleAssociation() async {
    try {
      // Obtenir l'ID du type Association
      final associationTypeDoc = await _firestore
          .collection('user_types')
          .where('name', isEqualTo: 'Association')
          .limit(1)
          .get();
      
      if (associationTypeDoc.docs.isEmpty) return null;
      
      final associationTypeId = associationTypeDoc.docs.first.id;
      
      // Récupérer toutes les associations visibles
      final visibleAssociations = await _firestore
          .collection('establishments')
          .where('user_type_id', isEqualTo: associationTypeId)
          .where('is_visible', isEqualTo: true)
          .get();
      
      if (visibleAssociations.docs.isEmpty) return null;
      
      // Sélectionner une association aléatoirement
      final random = Random();
      final selectedDoc = visibleAssociations.docs[random.nextInt(visibleAssociations.docs.length)];
      
      return {
        'id': selectedDoc.id,
        'user_id': selectedDoc.data()['user_id'],
        'name': selectedDoc.data()['name'],
        ...selectedDoc.data(),
      };
    } catch (e) {
      print('Erreur lors de la sélection d\'une association aléatoire: $e');
      return null;
    }
  }
  
  /// Crée un bon en attente si aucune association n'est disponible
  static Future<void> createPendingVoucher(Map<String, dynamic> voucherData) async {
    try {
      await _firestore.collection('pending_vouchers').add({
        ...voucherData,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'assigned': false,
      });
    } catch (e) {
      print('Erreur lors de la création d\'un bon en attente: $e');
    }
  }
  
  /// Traite les bons en attente quand une association devient visible
  static Future<void> processPendingVouchers(String associationId) async {
    try {
      // Récupérer le plus ancien bon en attente
      final pendingVoucherSnapshot = await _firestore
          .collection('pending_vouchers')
          .where('status', isEqualTo: 'pending')
          .where('assigned', isEqualTo: false)
          .orderBy('created_at')
          .limit(1)
          .get();
      
      if (pendingVoucherSnapshot.docs.isEmpty) return;
      
      final voucherDoc = pendingVoucherSnapshot.docs.first;
      final voucherData = voucherDoc.data();
      
      // Attribuer le bon à l'association
      await _firestore.collection('vouchers').add({
        ...voucherData,
        'association_id': associationId,
        'assigned_at': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      
      // Marquer le bon en attente comme traité
      await voucherDoc.reference.update({
        'assigned': true,
        'assigned_to': associationId,
        'assigned_at': FieldValue.serverTimestamp(),
        'status': 'assigned',
      });
    } catch (e) {
      print('Erreur lors du traitement des bons en attente: $e');
    }
  }
  
  /// Notifie une association qu'elle est devenue visible
  static Future<void> _notifyAssociationActivation(String establishmentId) async {
    try {
      // Récupérer les infos de l'établissement
      final establishmentDoc = await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .get();
      
      if (!establishmentDoc.exists) return;
      
      final userId = establishmentDoc.data()?['user_id'];
      if (userId == null) return;
      
      // Récupérer les infos de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userEmail = userDoc.data()?['email'];
      final userName = userDoc.data()?['name'];
      
      if (userEmail == null) return;
      
      // Créer l'email de notification
      await _firestore.collection('mail').add({
        'to': userEmail,
        'template': {
          'name': 'association-activated',
          'data': {
            'userName': userName ?? '',
            'establishmentName': establishmentDoc.data()?['name'] ?? '',
          },
        },
      });
    } catch (e) {
      print('Erreur lors de la notification d\'activation: $e');
    }
  }
  
  /// Obtient la position dans la liste d'attente
  static Future<int> getWaitlistPosition(String establishmentId) async {
    try {
      final waitlistSnapshot = await _firestore
          .collection('association_waitlist')
          .where('status', isEqualTo: 'waiting')
          .where('processed', isEqualTo: false)
          .orderBy('created_at')
          .get();
      
      int position = 0;
      for (final doc in waitlistSnapshot.docs) {
        position++;
        if (doc.data()['establishment_id'] == establishmentId) {
          return position;
        }
      }
      
      return 0; // Pas dans la liste d'attente
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      return 0;
    }
  }
}