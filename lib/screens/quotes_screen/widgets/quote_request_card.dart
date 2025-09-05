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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CustomTheme.lightScheme().primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.all(20),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(
              children: [
                // Icône de statut animée
                Hero(
                  tag: 'status_${quote.id}',
                  child: _buildStatusIcon(),
                ),
                const SizedBox(width: 16),
                
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.projectType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isReceived ? Icons.person_outline : Icons.business_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isReceived ? quote.userName : (quote.enterpriseName ?? 'Demande générale'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Montant et statut
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (quote.quotedAmount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${quote.quotedAmount?.toStringAsFixed(0)} €',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (quote.estimatedBudget != null)
                      Text(
                        '~${quote.estimatedBudget?.toStringAsFixed(0)} €',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.03),
                      Colors.white,
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date de création avec animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(quote.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Description du projet
                    _buildInfoCard(
                      title: 'Description du projet',
                      content: quote.projectDescription,
                      icon: Icons.description_outlined,
                      color: Colors.blue,
                    ),
                    
                    if (quote.estimatedBudget != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Budget estimé',
                        content: '${quote.estimatedBudget?.toStringAsFixed(2)} €',
                        icon: Icons.euro,
                        color: Colors.green,
                      ),
                    ],
                    
                    // Informations de contact (si reçu)
                    if (isReceived) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Contact client',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildContactChip(
                              Icons.email_outlined,
                              quote.userEmail,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildContactChip(
                              Icons.phone_outlined,
                              quote.userPhone,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Réponse de l'entreprise avec design amélioré
                    if (quote.enterpriseResponse != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[50]!,
                              Colors.blue[100]!.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.business_center, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Réponse de l\'entreprise',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              quote.enterpriseResponse!,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                            if (quote.quotedAmount != null) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Montant du devis:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue[200]!.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${quote.quotedAmount} €',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Points générés avec nouveau design
                    if (quote.pointsGenerated != null && !isReceived) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange[50]!,
                              Colors.amber[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange[200]!.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.stars_rounded,
                                color: Colors.orange[700],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Points à gagner',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  Text(
                                    '${quote.pointsGenerated} points',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            if (quote.pointsClaimed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Réclamés',
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Actions avec nouveau style
                    if (isReceived && quote.status == 'pending') ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: onRespond,
                            icon: const Icon(Icons.reply_rounded),
                            label: const Text('Répondre au devis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomTheme.lightScheme().primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
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
        ),
      ),
    );
  }
  
  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    Color bgColor;
    
    switch (quote.status) {
      case 'pending':
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        bgColor = Colors.orange[50]!;
        break;
      case 'responded':
        icon = Icons.mark_email_read_rounded;
        color = Colors.blue;
        bgColor = Colors.blue[50]!;
        break;
      case 'accepted':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        bgColor = Colors.green[50]!;
        break;
      case 'rejected':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        bgColor = Colors.red[50]!;
        break;
      case 'completed':
        icon = Icons.verified_rounded;
        color = Colors.purple;
        bgColor = Colors.purple[50]!;
        break;
      default:
        icon = Icons.help_outline_rounded;
        color = Colors.grey;
        bgColor = Colors.grey[50]!;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
  
  Widget _buildStatusBadge() {
    String label;
    Color color;
    IconData icon;
    
    switch (quote.status) {
      case 'pending':
        label = 'En attente';
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'responded':
        label = 'Répondu';
        color = Colors.blue;
        icon = Icons.reply;
        break;
      case 'accepted':
        label = 'Accepté';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        label = 'Refusé';
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case 'completed':
        label = 'Terminé';
        color = Colors.purple;
        icon = Icons.task_alt;
        break;
      default:
        label = 'Inconnu';
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}