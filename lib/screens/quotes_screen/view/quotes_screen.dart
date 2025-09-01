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
                length: controller.enterpriseQuotes.isNotEmpty ? 3 : 2,
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
                          const Tab(text: 'Mes demandes'),
                          if (controller.enterpriseQuotes.isNotEmpty)
                            const Tab(text: 'Demandes reçues'),
                          const Tab(text: 'Nouveau devis'),
                        ],
                      ),
                    ),
                    
                    // Contenu des tabs
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Mes demandes de devis
                          _buildMyQuotes(controller),
                          
                          // Demandes reçues (si entreprise)
                          if (controller.enterpriseQuotes.isNotEmpty)
                            _buildReceivedQuotes(controller),
                          
                          // Formulaire général
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
                  '${controller.totalQuotesCount.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Devis total',
                  style: TextStyle(
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