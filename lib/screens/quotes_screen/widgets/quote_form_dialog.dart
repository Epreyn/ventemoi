import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../controllers/quotes_screen_controller.dart';

class QuoteFormDialog extends StatefulWidget {
  final Establishment enterprise;
  
  const QuoteFormDialog({
    super.key,
    required this.enterprise,
  });
  
  @override
  State<QuoteFormDialog> createState() => _QuoteFormDialogState();
}

class _QuoteFormDialogState extends State<QuoteFormDialog> {
  final controller = Get.find<QuotesScreenController>();
  double simulatedAmount = 0;
  int simulatedPoints = 0;
  
  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les infos de l'utilisateur connecté si disponible
    _prefillUserInfo();
  }
  
  void _prefillUserInfo() async {
    // Logique pour pré-remplir les infos utilisateur
  }
  
  void _simulatePoints() {
    final amount = double.tryParse(controller.estimatedBudgetController.text) ?? 0;
    setState(() {
      simulatedAmount = amount;
      simulatedPoints = (amount * 0.02).round(); // 2% en points
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isDesktop ? 900 : screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CustomTheme.lightScheme().primary,
                    CustomTheme.lightScheme().primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demander un devis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.enterprise.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: Row(
                children: [
                  // Formulaire (côté gauche)
                  Expanded(
                    flex: isDesktop ? 3 : 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations de contact',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: controller.userNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Requis' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.userEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Requis';
                                      if (!GetUtils.isEmail(value!)) {
                                        return 'Email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.userPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Téléphone',
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Requis' : null,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Détails du projet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: controller.projectTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Type de projet',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Requis' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: controller.projectDescriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 60),
                                  child: Icon(Icons.description),
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Requis' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: controller.estimatedBudgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Budget estimé',
                                prefixIcon: Icon(Icons.euro),
                                suffixText: '€',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _simulatePoints(),
                            ),
                            
                            // Simulateur de points pour mobile
                            if (!isDesktop) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange[50]!,
                                      Colors.orange[100]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calculate,
                                          color: Colors.orange[700],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Simulateur de points',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: simulatedPoints > 0
                                          ? Column(
                                              key: ValueKey(simulatedPoints),
                                              children: [
                                                Text(
                                                  '$simulatedPoints',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange[700],
                                                  ),
                                                ),
                                                Text(
                                                  'points estimés',
                                                  style: TextStyle(
                                                    color: Colors.orange[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[100],
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    '2% du montant',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.orange[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'Entrez un budget pour\nvoir vos points',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.orange[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _showPointsInfoDialog,
                                      icon: Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      label: Text(
                                        'Comment ça marche ?',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Simulateur et actions (côté droit sur desktop)
                  if (isDesktop)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Simulateur de points
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange[50]!,
                                  Colors.orange[100]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  color: Colors.orange[700],
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Simulateur de points',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (simulatedAmount > 0) ...[
                                  Text(
                                    'Pour un projet de',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '${simulatedAmount.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vous pourriez recevoir',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '$simulatedPoints points',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'Entrez un budget pour simuler',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Bouton Recevez vos points
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton.icon(
                              onPressed: () => _showPointsInfoDialog(),
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Recevez vos points'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Boutons d'action
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              children: [
                                Obx(() => ElevatedButton.icon(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => controller.submitQuoteRequest(
                                            enterprise: widget.enterprise,
                                          ),
                                  icon: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(
                                    controller.isLoading.value
                                        ? 'Envoi...'
                                        : 'Envoyer le devis',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        CustomTheme.lightScheme().primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Annuler'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Actions pour mobile
            if (!isDesktop)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.submitQuoteRequest(
                                  enterprise: widget.enterprise,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomTheme.lightScheme().primary,
                          foregroundColor: Colors.white,
                        ),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text('Envoyer'),
                      )),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showPointsInfoDialog() {
    final isSmallScreen = MediaQuery.of(Get.context!).size.height < 700;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: isSmallScreen 
                ? MediaQuery.of(Get.context!).size.height * 0.75
                : 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[700]!],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Comment recevoir vos points ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              
              // Content scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pour recevoir vos points, vous devez :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildStep('1', 'Avoir demandé un devis'),
                      _buildStep('2', 'Avoir signé le devis avec l\'entreprise'),
                      _buildStep('3', 'Rendez-vous dans la page "Vos devis"'),
                      _buildStep('4', 'Cliquez sur "Réclamer mes points"'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stars, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous recevrez 2% du montant du devis en points',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions en bas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Fermer'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/quotes');
                      },
                      icon: const Icon(Icons.description, color: Colors.white),
                      label: const Text('Voir mes devis', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomTheme.lightScheme().primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}