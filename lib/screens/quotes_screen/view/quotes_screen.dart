import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/quotes_screen_controller.dart';
import '../widgets/quote_request_card.dart';
import '../widgets/general_quote_form.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuotesScreenController());
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    
    return ScreenLayout(
      noFAB: true,
      body: Obx(() {
        // Debug info
        print('QuotesScreen - isAdmin: ${controller.isAdmin.value}');
        print('QuotesScreen - userQuotes: ${controller.userQuotes.length}');
        print('QuotesScreen - enterpriseQuotes: ${controller.enterpriseQuotes.length}');
        print('QuotesScreen - allQuotes: ${controller.allQuotes.length}');
        
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Row(
          children: [
            // Menu latéral sur desktop
            if (isDesktop) _buildSideMenu(controller),
            
            // Contenu principal
            Expanded(
              child: DefaultTabController(
                length: controller.isAdmin.value 
                    ? 2 
                    : (controller.enterpriseQuotes.isNotEmpty ? 3 : 2),
                child: Column(
                  children: [
                    // Tabs
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        labelColor: CustomTheme.lightScheme().primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: CustomTheme.lightScheme().primary,
                        tabs: [
                          Tab(text: controller.isAdmin.value 
                              ? 'Tous les devis' 
                              : 'Mes demandes'),
                          if (!controller.isAdmin.value && controller.enterpriseQuotes.isNotEmpty)
                            const Tab(text: 'Demandes reçues'),
                          if (!controller.isAdmin.value)
                            const Tab(text: 'Nouveau devis'),
                        ],
                      ),
                    ),
                    
                    // Contenu des tabs
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Mes demandes de devis ou tous les devis (admin)
                          controller.isAdmin.value 
                              ? _buildAllQuotes(controller)
                              : _buildMyQuotes(controller),
                          
                          // Demandes reçues (si entreprise)
                          if (!controller.isAdmin.value && controller.enterpriseQuotes.isNotEmpty)
                            _buildReceivedQuotes(controller),
                          
                          // Formulaire général (sauf pour admin)
                          if (!controller.isAdmin.value)
                            GeneralQuoteForm(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
  
  Widget _buildSideMenu(QuotesScreenController controller) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Statistiques
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CustomTheme.lightScheme().primary,
                  CustomTheme.lightScheme().primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.isAdmin.value 
                      ? '${controller.allQuotes.length}'
                      : '${controller.userQuotes.length + controller.enterpriseQuotes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.isAdmin.value 
                      ? 'Total système'
                      : 'Mes devis',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Filtre par statut
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrer par statut',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...['all', 'pending', 'responded', 'accepted', 'completed'].map((status) {
                  final labels = {
                    'all': 'Tous',
                    'pending': 'En attente',
                    'responded': 'Répondu',
                    'accepted': 'Accepté',
                    'completed': 'Terminé',
                  };
                  
                  return Obx(() => RadioListTile<String>(
                    value: status,
                    groupValue: controller.selectedStatus.value,
                    onChanged: (value) {
                      controller.selectedStatus.value = value!;
                    },
                    title: Text(
                      labels[status]!,
                      style: const TextStyle(fontSize: 13),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMyQuotes(QuotesScreenController controller) {
    final quotes = controller.getFilteredQuotes(controller.userQuotes);
    
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune demande de devis',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par demander un devis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return QuoteRequestCard(
          quote: quotes[index],
          isReceived: false,
          onClaimPoints: () => controller.claimPoints(quotes[index].id),
        );
      },
    );
  }
  
  Widget _buildReceivedQuotes(QuotesScreenController controller) {
    final quotes = controller.getFilteredQuotes(controller.enterpriseQuotes);
    
    if (quotes.isEmpty) {
      return const Center(
        child: Text('Aucune demande reçue'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return QuoteRequestCard(
          quote: quotes[index],
          isReceived: true,
          onRespond: () => _showResponseDialog(controller, quotes[index]),
        );
      },
    );
  }
  
  Widget _buildAllQuotes(QuotesScreenController controller) {
    final quotes = controller.getFilteredQuotes(controller.allQuotes);
    
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun devis',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il n\'y a aucun devis dans le système',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.projectType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Client: ${quote.userName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (quote.enterpriseName != null)
                            Text(
                              'Entreprise: ${quote.enterpriseName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(quote.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  quote.projectDescription,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: ${quote.estimatedBudget?.toStringAsFixed(2) ?? 'N/A'} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      _formatDate(quote.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending': Colors.orange,
      'responded': Colors.blue,
      'accepted': Colors.green,
      'rejected': Colors.red,
      'completed': Colors.purple,
    };
    
    final labels = {
      'pending': 'En attente',
      'responded': 'Répondu',
      'accepted': 'Accepté',
      'rejected': 'Rejeté',
      'completed': 'Terminé',
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors[status]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors[status]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          color: colors[status] ?? Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showResponseDialog(QuotesScreenController controller, quote) {
    final responseController = TextEditingController();
    final amountController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Répondre au devis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Votre réponse',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant du devis (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              controller.respondToQuote(
                quote.id,
                responseController.text,
                amount,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomTheme.lightScheme().primary,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}