import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/establishement.dart';
import '../models/quote_request.dart';

class QuoteEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Envoie un email lors d'une nouvelle demande de devis
  static Future<void> sendNewQuoteRequestEmail({
    required Map<String, dynamic> quoteData,
    required Establishment? enterprise,
  }) async {
    try {
      // Toujours notifier les admins pour TOUS les devis
      await _sendQuoteRequestToAdmin(quoteData, enterprise);
      
      if (enterprise == null) {
        // Si demande générale, c'est déjà envoyé aux admins
        return;
      }

      // Envoyer à l'entreprise
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">📋</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Nouvelle demande de devis !</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>${enterprise.name}</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Vous avez reçu une nouvelle demande de devis !
            </p>
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin: 20px 0;">
              <h3 style="color: #4A90E2; margin-top: 0;">Détails de la demande :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📌 Type de projet :</strong> ${quoteData['project_type']}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>👤 Client :</strong> ${quoteData['user_name']}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📧 Email :</strong> ${quoteData['user_email']}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📱 Téléphone :</strong> ${quoteData['user_phone']}
              </p>
              ${quoteData['estimated_budget'] != null ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>💰 Budget estimé :</strong> ${quoteData['estimated_budget']} €
              </p>''' : ''}
            </div>
            
            <div style="background: #e3f2fd; border-left: 4px solid #4A90E2; padding: 15px; margin: 20px 0;">
              <h4 style="color: #4A90E2; margin-top: 0;">Description du projet :</h4>
              <p style="font-size: 14px; color: #555; line-height: 1.6;">
                ${quoteData['project_description']}
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/quotes" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Répondre au devis
              </a>
            </div>
            
            <p style="font-size: 14px; color: #666; margin-top: 20px; font-style: italic;">
              💡 Conseil : Répondez rapidement pour augmenter vos chances de décrocher le projet !
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      // Envoyer l'email
      await _sendEmail(
        to: enterprise.email,
        subject: '📋 Nouvelle demande de devis : ${quoteData['project_type']}',
        html: emailContent,
        metadata: {
          'type': 'new_quote_request',
          'enterpriseId': enterprise.id,
          'quoteData': quoteData,
        }
      );

      print('✅ Email de nouvelle demande de devis envoyé à ${enterprise.email}');
    } catch (e) {
      print('Erreur envoi email nouvelle demande de devis: $e');
    }
  }

  /// Envoie un email lors de la réponse à un devis
  static Future<void> sendQuoteResponseEmail({
    required String userEmail,
    required String userName,
    required String enterpriseName,
    required String projectType,
    required String response,
    required double? quotedAmount,
  }) async {
    try {
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">✉️</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Réponse à votre demande de devis</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$userName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              <strong>$enterpriseName</strong> a répondu à votre demande de devis pour : <strong>$projectType</strong>
            </p>
            
            ${quotedAmount != null ? '''
            <div style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); border-radius: 15px; padding: 25px; margin: 30px 0; text-align: center;">
              <p style="font-size: 20px; color: white; margin: 0;">Montant du devis</p>
              <p style="font-size: 42px; font-weight: bold; color: white; margin: 10px 0;">
                ${quotedAmount.toStringAsFixed(2)} €
              </p>
            </div>
            ''' : ''}
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin: 20px 0;">
              <h3 style="color: #4CAF50; margin-top: 0;">Réponse de l'entreprise :</h3>
              <p style="font-size: 15px; color: #555; line-height: 1.6;">
                $response
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/quotes" style="display: inline-block; background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir le devis complet
              </a>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #856404; margin: 0;">
                <strong>💰 Rappel :</strong> Si vous acceptez ce devis et réalisez le projet, vous gagnerez 2% du montant en points de fidélité !
              </p>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      await _sendEmail(
        to: userEmail,
        subject: '✉️ $enterpriseName a répondu à votre demande de devis',
        html: emailContent,
        metadata: {
          'type': 'quote_response',
          'enterpriseName': enterpriseName,
          'projectType': projectType,
        }
      );

      print('✅ Email de réponse au devis envoyé à $userEmail');
    } catch (e) {
      print('Erreur envoi email réponse devis: $e');
    }
  }

  /// Envoie un email lors de l'acceptation d'un devis
  static Future<void> sendQuoteAcceptedEmail({
    required String enterpriseEmail,
    required String enterpriseName,
    required String userName,
    required String projectType,
    required double quotedAmount,
  }) async {
    try {
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">🎉</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Devis accepté !</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$enterpriseName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Excellente nouvelle ! <strong>$userName</strong> a accepté votre devis !
            </p>
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin: 20px 0;">
              <h3 style="color: #4CAF50; margin-top: 0;">Détails du devis accepté :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📌 Projet :</strong> $projectType
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>👤 Client :</strong> $userName
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>💰 Montant :</strong> ${quotedAmount.toStringAsFixed(2)} €
              </p>
            </div>
            
            <div style="background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #155724; margin: 0;">
                <strong>✅ Prochaines étapes :</strong> Contactez rapidement votre client pour démarrer le projet et finaliser les détails.
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/quotes" style="display: inline-block; background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir les détails
              </a>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      await _sendEmail(
        to: enterpriseEmail,
        subject: '🎉 Devis accepté : $projectType par $userName',
        html: emailContent,
        metadata: {
          'type': 'quote_accepted',
          'userName': userName,
          'projectType': projectType,
          'amount': quotedAmount,
        }
      );

      print('✅ Email de devis accepté envoyé à $enterpriseEmail');
    } catch (e) {
      print('Erreur envoi email devis accepté: $e');
    }
  }

  /// Envoie un email lors du refus d'un devis
  static Future<void> sendQuoteRejectedEmail({
    required String enterpriseEmail,
    required String enterpriseName,
    required String userName,
    required String projectType,
  }) async {
    try {
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #FF6B6B 0%, #EE5A24 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">📝</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Devis refusé</h2>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour <strong>$enterpriseName</strong>,
            </p>
            
            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              <strong>$userName</strong> a décidé de ne pas donner suite à votre devis pour : <strong>$projectType</strong>
            </p>
            
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px; margin: 20px 0;">
              <p style="font-size: 14px; color: #666; line-height: 1.6;">
                Cela arrive, ne vous découragez pas ! Continuez à proposer des devis compétitifs et de qualité.
              </p>
            </div>
            
            <div style="background: #e3f2fd; border-left: 4px solid #4A90E2; padding: 15px; margin: 20px 0;">
              <p style="font-size: 14px; color: #1976d2; margin: 0;">
                <strong>💡 Conseil :</strong> Analysez vos devis refusés pour améliorer vos futures propositions. Un prix compétitif et une description détaillée augmentent vos chances de succès !
              </p>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Tous droits réservés</p>
          </div>
        </div>
      ''';

      await _sendEmail(
        to: enterpriseEmail,
        subject: '📝 Devis refusé : $projectType',
        html: emailContent,
        metadata: {
          'type': 'quote_rejected',
          'userName': userName,
          'projectType': projectType,
        }
      );

      print('✅ Email de devis refusé envoyé à $enterpriseEmail');
    } catch (e) {
      print('Erreur envoi email devis refusé: $e');
    }
  }

  /// Envoie un email à tous les admins pour toutes les demandes de devis
  static Future<void> _sendQuoteRequestToAdmin(Map<String, dynamic> quoteData, Establishment? enterprise) async {
    try {
      // Récupérer tous les administrateurs depuis Firestore
      final adminTypeQuery = await _firestore
          .collection('user_types')
          .where('name', isEqualTo: 'Administrateur')
          .limit(1)
          .get();
      
      if (adminTypeQuery.docs.isEmpty) {
        print('❌ Aucun type administrateur trouvé');
        return;
      }
      
      final adminTypeId = adminTypeQuery.docs.first.id;
      
      // Récupérer tous les utilisateurs administrateurs
      final adminsQuery = await _firestore
          .collection('users')
          .where('user_type_id', isEqualTo: adminTypeId)
          .get();
      
      if (adminsQuery.docs.isEmpty) {
        print('❌ Aucun administrateur trouvé');
        return;
      }
      
      // Préparer le type de demande
      final requestType = enterprise != null 
          ? 'Demande pour ${enterprise.name}' 
          : 'Demande générale';
      
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">🔔</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Nouvelle demande de devis</h2>
            <p style="margin: 5px 0; font-size: 16px;">$requestType</p>
          </div>
          
          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <div style="background: #f8f9fa; border-radius: 10px; padding: 20px;">
              <h3 style="color: #667eea; margin-top: 0;">Détails de la demande :</h3>
              <p><strong>📌 Type de projet :</strong> ${quoteData['project_type'] ?? 'Non spécifié'}</p>
              <p><strong>👤 Client :</strong> ${quoteData['user_name'] ?? 'Non spécifié'}</p>
              <p><strong>📧 Email :</strong> ${quoteData['user_email'] ?? 'Non spécifié'}</p>
              <p><strong>📱 Téléphone :</strong> ${quoteData['user_phone'] ?? 'Non spécifié'}</p>
              <p><strong>💰 Budget :</strong> ${quoteData['estimated_budget'] ?? 'Non spécifié'} €</p>
              ${enterprise != null ? '<p><strong>🏢 Entreprise ciblée :</strong> ${enterprise.name}</p>' : '<p><strong>⚠️ Type :</strong> Demande générale</p>'}
              <p><strong>📝 Description :</strong> ${quoteData['project_description'] ?? 'Non fournie'}</p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/admin/quotes" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir dans le panel admin
              </a>
            </div>
          </div>
        </div>
      ''';

      // Envoyer à tous les admins
      for (final adminDoc in adminsQuery.docs) {
        final adminData = adminDoc.data();
        final adminEmail = adminData['email'] as String?;
        
        if (adminEmail != null && adminEmail.isNotEmpty) {
          await _sendEmail(
            to: adminEmail,
            subject: '🔔 Admin - Nouvelle demande de devis',
            html: emailContent,
            metadata: {
              'type': 'admin_quote_notification',
              'quoteData': quoteData,
            }
          );
          print('✅ Email devis envoyé à admin: $adminEmail');
        }
      }
    } catch (e) {
      print('Erreur envoi email admin: $e');
    }
  }

  /// Méthode générique pour envoyer un email
  static Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
    Map<String, dynamic>? metadata,
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
      // Fallback : ajouter à la queue
      await _firestore.collection('email_queue').add({
        'to': to,
        'subject': subject,
        'html': html,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'metadata': metadata,
      });
      print('📧 Email ajouté à la queue');
    }
  }
}