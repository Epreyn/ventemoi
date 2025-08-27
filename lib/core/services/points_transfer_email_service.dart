import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PointsTransferEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Envoie un email de notification lors d'un transfert de points
  static Future<void> sendPointsTransferEmail({
    required String recipientId,
    required String senderId,
    required int points,
    required String transferId,
  }) async {
    try {
      // Récupérer les informations du destinataire
      final recipientDoc = await _firestore.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) {
        print('Recipient user not found');
        return;
      }
      
      final recipientData = recipientDoc.data()!;
      final recipientEmail = recipientData['email'] as String?;
      final recipientName = recipientData['name'] ?? recipientData['firstName'] ?? 'Utilisateur';
      
      if (recipientEmail == null || recipientEmail.isEmpty) {
        print('No email for recipient');
        return;
      }

      // Récupérer les informations de l'expéditeur
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      String senderName = 'Un utilisateur';
      String senderEmail = '';
      
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        senderName = senderData['name'] ?? senderData['firstName'] ?? 'Un utilisateur';
        senderEmail = senderData['email'] ?? '';
      }

      // Préparer le contenu de l'email
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #FFB800 0%, #FFA000 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">🎉</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Vous avez reçu des points !</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$recipientName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Bonne nouvelle ! <strong>$senderName</strong> vient de vous transférer :
            </p>
            
            <div style="background: linear-gradient(135deg, #FFB800 0%, #FFA000 100%); border-radius: 15px; padding: 25px; margin: 30px 0; text-align: center;">
              <p style="font-size: 48px; font-weight: bold; color: white; margin: 0;">
                $points
              </p>
              <p style="font-size: 18px; color: white; margin: 5px 0; text-transform: uppercase; letter-spacing: 2px;">
                Points
              </p>
            </div>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Ces points ont été ajoutés à votre compte VenteMoi et sont disponibles immédiatement.
            </p>
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin-top: 25px;">
              <p style="font-size: 14px; color: #666; margin: 0;">
                <strong>💡 Astuce :</strong> Vous pouvez utiliser vos points pour acheter des bons cadeaux chez nos commerçants partenaires !
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com" style="display: inline-block; background: linear-gradient(135deg, #FFB800 0%, #FFA000 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir mon solde de points
              </a>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      // Appeler la fonction Cloud pour envoyer l'email
      try {
        final callable = _functions.httpsCallable('sendEmail');
        await callable.call({
          'to': recipientEmail,
          'subject': '🎉 Vous avez reçu $points points de $senderName !',
          'html': emailContent,
        });
        
        print('✅ Email sent successfully to $recipientEmail');
      } catch (e) {
        print('Error calling sendEmail function: $e');
        
        // Alternative : créer un document dans une collection email_queue
        // qui sera traité par une fonction Cloud
        await _firestore.collection('email_queue').add({
          'to': recipientEmail,
          'subject': '🎉 Vous avez reçu $points points de $senderName !',
          'html': emailContent,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'type': 'points_transfer',
          'metadata': {
            'transferId': transferId,
            'senderId': senderId,
            'recipientId': recipientId,
            'points': points,
          }
        });
        
        print('📧 Email queued for sending');
      }

      // Optionnel : Envoyer aussi une copie à l'expéditeur
      if (senderEmail.isNotEmpty) {
        await _sendConfirmationToSender(
          senderEmail: senderEmail,
          senderName: senderName,
          recipientName: recipientName,
          points: points,
        );
      }

    } catch (e) {
      print('Error in sendPointsTransferEmail: $e');
      // Ne pas bloquer le transfert si l'email échoue
    }
  }

  /// Envoie un email de confirmation à l'expéditeur
  static Future<void> _sendConfirmationToSender({
    required String senderEmail,
    required String senderName,
    required String recipientName,
    required int points,
  }) async {
    try {
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">✅</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Transfert réussi !</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$senderName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Votre transfert de points a été effectué avec succès !
            </p>
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin: 20px 0;">
              <p style="font-size: 16px; color: #333; margin: 5px 0;">
                <strong>📤 Points transférés :</strong> $points points
              </p>
              <p style="font-size: 16px; color: #333; margin: 5px 0;">
                <strong>👤 Destinataire :</strong> $recipientName
              </p>
              <p style="font-size: 16px; color: #333; margin: 5px 0;">
                <strong>📅 Date :</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
              </p>
            </div>
            
            <p style="font-size: 14px; color: #666; line-height: 1.6; margin-top: 20px;">
              Les points ont été immédiatement crédités sur le compte du destinataire.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      try {
        final callable = FirebaseFunctions.instance.httpsCallable('sendEmail');
        await callable.call({
          'to': senderEmail,
          'subject': '✅ Transfert de $points points vers $recipientName confirmé',
          'html': emailContent,
        });
      } catch (e) {
        // Fallback : ajouter à la queue
        await _firestore.collection('email_queue').add({
          'to': senderEmail,
          'subject': '✅ Transfert de $points points vers $recipientName confirmé',
          'html': emailContent,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'type': 'points_transfer_confirmation',
        });
      }
    } catch (e) {
      print('Error sending confirmation to sender: $e');
    }
  }

  /// Méthode à appeler lors de la création d'un transfert de points
  static Future<void> handlePointsTransfer({
    required String fromUserId,
    required String toUserId,
    required int amount,
  }) async {
    try {
      // Créer le document de transfert
      final transferRef = await _firestore.collection('pointsTransfers').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'status': 'completed',
        'hasBeenShown': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envoyer l'email de notification
      await sendPointsTransferEmail(
        recipientId: toUserId,
        senderId: fromUserId,
        points: amount,
        transferId: transferRef.id,
      );

      print('✅ Points transfer created with email notification');
    } catch (e) {
      print('Error in handlePointsTransfer: $e');
      rethrow;
    }
  }
}