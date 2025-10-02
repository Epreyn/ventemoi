import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class OfferEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Envoie un email lors de l'approbation d'une offre
  static Future<void> sendOfferApprovedEmail({
    required Map<String, dynamic> request,
  }) async {
    try {
      // Récupérer l'email de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(request['user_id'])
          .get();
      
      if (!userDoc.exists) {
        return;
      }
      
      final userEmail = userDoc.data()?['email'] ?? '';
      final userName = userDoc.data()?['first_name'] ?? 'Client';
      
      if (userEmail.isEmpty) {
        return;
      }

      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">✅</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Offre approuvée !</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$userName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Excellente nouvelle ! Votre demande d'offre publicitaire a été <strong style="color: #4CAF50;">approuvée</strong>.
            </p>
            
            <div style="background: #f0f9ff; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #4CAF50;">
              <h3 style="color: #4CAF50; margin-top: 0;">📢 Votre offre :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Titre :</strong> ${request['title'] ?? ''}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Description :</strong> ${request['description'] ?? ''}
              </p>
              ${request['start_date'] != null ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Date de début :</strong> ${_formatDate(request['start_date'])}
              </p>''' : ''}
              ${request['end_date'] != null ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Date de fin :</strong> ${_formatDate(request['end_date'])}
              </p>''' : ''}
            </div>
            
            <div style="background: #e8f5e9; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #2e7d32; margin: 0;">
                <strong>✨ Prochaine étape :</strong> Votre offre est maintenant visible sur VenteMoi et sera diffusée selon les dates programmées.
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com" style="display: inline-block; background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir mon offre
              </a>
            </div>
            
            <p style="font-size: 14px; color: #666; margin-top: 20px; text-align: center;">
              Si vous avez des questions, n'hésitez pas à nous contacter.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      // Envoyer l'email
      await _sendEmail(
        to: userEmail,
        subject: '✅ Votre offre publicitaire a été approuvée',
        html: emailContent,
      );

    } catch (e) {
    }
  }

  /// Envoie un email lors du rejet d'une offre
  static Future<void> sendOfferRejectedEmail({
    required String requestId,
    required String userId,
    required Map<String, dynamic> requestData,
    required String rejectionReason,
  }) async {
    try {
      // Récupérer l'email de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return;
      }
      
      final userEmail = userDoc.data()?['email'] ?? '';
      final userName = userDoc.data()?['first_name'] ?? 'Client';
      
      if (userEmail.isEmpty) {
        return;
      }

      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">❌</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Offre refusée</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$userName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Nous avons le regret de vous informer que votre demande d'offre publicitaire n'a pas pu être approuvée.
            </p>
            
            <div style="background: #fff3e0; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #ff9800;">
              <h3 style="color: #f44336; margin-top: 0;">📋 Détails de votre demande :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Titre :</strong> ${requestData['title'] ?? ''}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>Description :</strong> ${requestData['description'] ?? ''}
              </p>
            </div>
            
            <div style="background: #ffebee; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #f44336;">
              <h3 style="color: #d32f2f; margin-top: 0;">💬 Raison du refus :</h3>
              <p style="font-size: 15px; color: #555; line-height: 1.6; margin: 0;">
                $rejectionReason
              </p>
            </div>
            
            <div style="background: #e3f2fd; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #1976d2; margin: 0;">
                <strong>💡 Que faire maintenant ?</strong><br>
                Vous pouvez modifier votre demande en tenant compte des remarques ci-dessus et soumettre une nouvelle demande.
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/pro-request-offer" style="display: inline-block; background: linear-gradient(135deg, #2196F3 0%, #1976d2 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Soumettre une nouvelle demande
              </a>
            </div>
            
            <p style="font-size: 14px; color: #666; margin-top: 20px; text-align: center;">
              Si vous avez des questions concernant cette décision, n'hésitez pas à nous contacter.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      // Envoyer l'email
      await _sendEmail(
        to: userEmail,
        subject: '❌ Votre demande d\'offre publicitaire n\'a pas été approuvée',
        html: emailContent,
      );

    } catch (e) {
    }
  }

  /// Méthode privée pour formater les dates
  static String _formatDate(dynamic date) {
    if (date == null) return 'Non définie';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Date invalide';
    }
    
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                   'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// Envoie un email aux admins lors d'une nouvelle demande d'offre
  static Future<void> sendNewOfferRequestToAdmins({
    required Map<String, dynamic> requestData,
  }) async {
    try {
      // Récupérer tous les admins
      final adminsQuery = await _firestore
          .collection('users')
          .where('user_type_id', isEqualTo: '3YxzCA7BewiMswi8FDSt') // ID du type Admin
          .get();
      
      if (adminsQuery.docs.isEmpty) {
        return;
      }

      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">📢</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Nouvelle demande d'offre publicitaire</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour Administrateur,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Une nouvelle demande d'offre publicitaire vient d'être soumise et nécessite votre validation.
            </p>
            
            <div style="background: #f5f5f5; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #667eea;">
              <h3 style="color: #667eea; margin-top: 0;">📋 Détails de la demande :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>🏢 Établissement :</strong> ${requestData['establishment_name'] ?? 'Non spécifié'}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📱 Contact :</strong> ${requestData['contact_phone'] ?? 'Non fourni'}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📝 Titre :</strong> ${requestData['title'] ?? ''}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📄 Description :</strong> ${requestData['description'] ?? ''}
              </p>
              ${requestData['start_date'] != null ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📅 Date de début souhaitée :</strong> ${_formatDate(requestData['start_date'])}
              </p>''' : ''}
              ${requestData['end_date'] != null ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📅 Date de fin souhaitée :</strong> ${_formatDate(requestData['end_date'])}
              </p>''' : ''}
            </div>
            
            <div style="background: #fff3e0; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #f57c00; margin: 0;">
                <strong>⏰ Action requise :</strong> Cette demande est en attente de votre validation. Veuillez la consulter et l'approuver ou la rejeter dans les plus brefs délais.
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/admin-offers" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir les demandes en attente
              </a>
            </div>
            
            <div style="margin-top: 30px; padding: 20px; background: #e8f5e9; border-radius: 10px;">
              <h4 style="color: #2e7d32; margin-top: 0;">📊 Statistiques rapides :</h4>
              <p style="font-size: 14px; color: #555; margin: 5px 0;">
                Cette demande sera visible sur la page d'accueil une fois approuvée.
              </p>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Panneau d'administration</p>
            <p style="font-size: 12px;">Cet email a été envoyé automatiquement suite à une nouvelle demande d'offre publicitaire.</p>
          </div>
        </div>
      ''';

      // Envoyer l'email à chaque admin
      for (var adminDoc in adminsQuery.docs) {
        final adminEmail = adminDoc.data()['email'];
        if (adminEmail != null && adminEmail.toString().isNotEmpty) {
          await _sendEmail(
            to: adminEmail,
            subject: '📢 Nouvelle demande d\'offre publicitaire en attente de validation',
            html: emailContent,
          );
        }
      }
    } catch (e) {
    }
  }

  /// Méthode privée pour envoyer l'email
  static Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      // Essayer d'abord avec la fonction Cloud
      final callable = _functions.httpsCallable('sendEmail');
      await callable.call({
        'to': to,
        'subject': subject,
        'html': html,
      });
    } catch (e) {
      // Fallback : ajouter à la queue Firestore pour traitement ultérieur
      
      await _firestore.collection('mail').add({
        'to': [to],
        'message': {
          'subject': subject,
          'html': html,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'attempts': 0,
        'error': null,
      });
      
    }
  }
}