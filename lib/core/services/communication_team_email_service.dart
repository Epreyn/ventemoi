import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CommunicationTeamEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Email de l'équipe communication
  static const String COMMUNICATION_TEAM_EMAIL = 'communication@ventemoi.com';

  /// Envoie un email à l'équipe communication pour une nouvelle inscription de partenaire
  static Future<void> sendNewPartnerRegistrationEmail({
    required String partnerName,
    required String partnerEmail,
    required String partnerType,
    String? companyName,
  }) async {
    try {
      // Ne pas envoyer d'email pour les particuliers
      if (partnerType == 'Particulier') {
        return;
      }

      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #10B981 0%, #059669 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">🎉</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Nouveau partenaire inscrit !</h2>
          </div>

          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour l'équipe Communication,
            </p>

            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Un nouveau partenaire vient de s'inscrire sur VenteMoi !
            </p>

            <div style="background: #f0fdf4; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #10B981;">
              <h3 style="color: #10B981; margin-top: 0;">📋 Informations du partenaire :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>👤 Nom :</strong> ${partnerName}
              </p>
              ${companyName != null && companyName.isNotEmpty ? '''
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>🏢 Entreprise :</strong> ${companyName}
              </p>''' : ''}
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📧 Email :</strong> ${partnerEmail}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>🏷️ Type :</strong> ${partnerType}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📅 Date d'inscription :</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
              </p>
            </div>

            <div style="background: #e0f2fe; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <h4 style="color: #0284c7; margin-top: 0;">💡 Actions suggérées :</h4>
              <ul style="font-size: 14px; color: #555; line-height: 1.8;">
                <li>Préparer un message de bienvenue personnalisé</li>
                <li>Créer du contenu pour valoriser ce nouveau partenariat</li>
                <li>Planifier une publication sur les réseaux sociaux</li>
                <li>Ajouter à la newsletter mensuelle</li>
              </ul>
            </div>

            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/admin/users" style="display: inline-block; background: linear-gradient(135deg, #10B981 0%, #059669 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir le profil du partenaire
              </a>
            </div>

            <p style="font-size: 14px; color: #666; margin-top: 20px; text-align: center; font-style: italic;">
              Cette notification automatique vous permet de valoriser rapidement chaque nouveau partenariat ! 🚀
            </p>
          </div>

          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Notification automatique</p>
          </div>
        </div>
      ''';

      final callable = _functions.httpsCallable('sendEmail');
      await callable.call({
        'to': COMMUNICATION_TEAM_EMAIL,
        'subject': '🎉 Nouveau partenaire : $partnerName ${companyName != null && companyName.isNotEmpty ? "($companyName)" : ""}',
        'html': emailContent,
      });

    } catch (e) {
      // Ne pas faire échouer l'inscription si l'email échoue
    }
  }

  /// Envoie un email à l'équipe communication pour une vente d'un partenaire
  static Future<void> sendPartnerSaleNotification({
    required String partnerName,
    required String partnerEmail,
    required String productOrService,
    required double amount,
    required String customerName,
    String? companyName,
  }) async {
    try {
      final emailContent = '''
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); border-radius: 20px; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 48px;">💰</h1>
            <h2 style="margin: 10px 0; font-size: 28px;">Nouvelle vente partenaire !</h2>
          </div>

          <div style="background: white; border-radius: 15px; padding: 30px; margin-top: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
            <p style="font-size: 18px; color: #333; margin-bottom: 20px;">
              Bonjour l'équipe Communication,
            </p>

            <p style="font-size: 16px; color: #555; line-height: 1.6;">
              Un partenaire vient de réaliser une vente sur VenteMoi !
            </p>

            <div style="background: #fef3c7; border-radius: 10px; padding: 20px; margin: 20px 0; border-left: 4px solid #F59E0B;">
              <h3 style="color: #F59E0B; margin-top: 0;">💼 Détails de la vente :</h3>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>🏪 Partenaire :</strong> ${partnerName} ${companyName != null && companyName.isNotEmpty ? "($companyName)" : ""}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📧 Email :</strong> ${partnerEmail}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>🛍️ Produit/Service :</strong> ${productOrService}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>💵 Montant :</strong> ${amount.toStringAsFixed(2)} €
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>👤 Client :</strong> ${customerName}
              </p>
              <p style="font-size: 15px; color: #333; margin: 8px 0;">
                <strong>📅 Date :</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
              </p>
            </div>

            <div style="background: #dcfce7; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <h4 style="color: #16a34a; margin-top: 0;">📈 Opportunités de communication :</h4>
              <ul style="font-size: 14px; color: #555; line-height: 1.8;">
                <li>Créer un post de succès sur les réseaux sociaux</li>
                <li>Mettre en avant cette vente dans la newsletter</li>
                <li>Créer un témoignage client/partenaire</li>
                <li>Utiliser comme exemple de réussite pour attirer de nouveaux partenaires</li>
              </ul>
            </div>

            <div style="text-align: center; margin-top: 30px;">
              <a href="https://ventemoi.com/admin/sales" style="display: inline-block; background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 50px; font-weight: bold; font-size: 16px;">
                Voir les détails de la vente
              </a>
            </div>

            <p style="font-size: 14px; color: #666; margin-top: 20px; text-align: center; font-style: italic;">
              Valorisez cette réussite pour inspirer d'autres partenaires ! 🎯
            </p>
          </div>

          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 14px;">
            <p>© ${DateTime.now().year} VenteMoi - Notification automatique</p>
          </div>
        </div>
      ''';

      final callable = _functions.httpsCallable('sendEmail');
      await callable.call({
        'to': COMMUNICATION_TEAM_EMAIL,
        'subject': '💰 Nouvelle vente : ${partnerName} - ${amount.toStringAsFixed(2)}€',
        'html': emailContent,
      });

    } catch (e) {
      // Ne pas faire échouer la vente si l'email échoue
    }
  }
}