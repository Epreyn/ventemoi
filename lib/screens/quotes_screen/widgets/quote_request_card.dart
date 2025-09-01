import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/theme/custom_theme.dart';

class QuoteRequestCard extends StatelessWidget {
  final QuoteRequest quote;
  final bool isReceived;
  final VoidCallback? onRespond;
  final VoidCallback? onClaimPoints;
  
  const QuoteRequestCard({
    super.key,
    required this.quote,
    required this.isReceived,
    this.onRespond,
    this.onClaimPoints,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            // Icône de statut
            _buildStatusIcon(),
            const SizedBox(width: 12),
            
            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.projectType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReceived ? quote.userName : (quote.enterpriseName ?? 'Demande générale'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Date et statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(quote.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description du projet
                _buildSection(
                  'Description du projet',
                  quote.projectDescription,
                ),
                
                if (quote.estimatedBudget != null) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    'Budget estimé',
                    '${quote.estimatedBudget} €',
                  ),
                ],
                
                // Informations de contact (si reçu)
                if (isReceived) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    'Contact',
                    '${quote.userEmail}\n${quote.userPhone}',
                  ),
                ],
                
                // Réponse de l'entreprise
                if (quote.enterpriseResponse != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Réponse de l\'entreprise',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(quote.enterpriseResponse!),
                        if (quote.quotedAmount != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Montant du devis: ${quote.quotedAmount} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Points générés
                if (quote.pointsGenerated != null && !isReceived) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[50]!,
                          Colors.orange[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Points à réclamer: ${quote.pointsGenerated}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                        if (quote.status == 'accepted' && !quote.pointsClaimed)
                          ElevatedButton.icon(
                            onPressed: onClaimPoints,
                            icon: const Icon(Icons.card_giftcard, size: 18),
                            label: const Text('Réclamer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (quote.pointsClaimed)
                          const Chip(
                            label: Text(
                              'Réclamés',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: Colors.green,
                          ),
                      ],
                    ),
                  ),
                ],
                
                // Actions
                if (isReceived && quote.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onRespond,
                        icon: const Icon(Icons.reply),
                        label: const Text('Répondre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomTheme.lightScheme().primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    
    switch (quote.status) {
      case 'pending':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case 'responded':
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      case 'accepted':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'completed':
        icon = Icons.done_all;
        color = Colors.green;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
  
  Widget _buildStatusBadge() {
    String label;
    Color color;
    
    switch (quote.status) {
      case 'pending':
        label = 'En attente';
        color = Colors.orange;
        break;
      case 'responded':
        label = 'Répondu';
        color = Colors.blue;
        break;
      case 'accepted':
        label = 'Accepté';
        color = Colors.green;
        break;
      case 'rejected':
        label = 'Refusé';
        color = Colors.red;
        break;
      case 'completed':
        label = 'Terminé';
        color = Colors.green;
        break;
      default:
        label = 'Inconnu';
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}