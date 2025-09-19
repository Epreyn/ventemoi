import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/quotes_screen_controller.dart';
import '../widgets/quote_request_card.dart';
import '../widgets/general_quote_form.dart';
import '../widgets/admin_quote_assignment_dialog.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildModernTabs(QuotesScreenController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isVerySmallScreen = screenWidth < 380;

    // Déterminer le nombre d'onglets
    int tabCount = 1; // Toujours au moins 1 (Mes demandes ou Tous les devis)
    if (!controller.isAdmin.value && controller.enterpriseQuotes.isNotEmpty) {
      tabCount++; // Demandes reçues
    }
    if (!controller.isAdmin.value) {
      tabCount++; // Nouveau devis
    }

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final tabWidth = containerWidth / tabCount;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                left: _selectedTabIndex * tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: _buildTabButtons(controller, isVerySmallScreen || isSmallScreen),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTabButtons(QuotesScreenController controller, bool isSmallScreen) {
    List<Widget> buttons = [];
    int index = 0;

    // Premier tab : Mes demandes ou Tous les devis (admin)
    buttons.add(_buildResponsiveTabButton(
      index: index++,
      label: controller.isAdmin.value ? 'Tous les devis' : 'Mes demandes',
      icon: Icons.inbox,
      isSmallScreen: isSmallScreen,
    ));

    // Deuxième tab : Demandes reçues (si entreprise)
    if (!controller.isAdmin.value && controller.enterpriseQuotes.isNotEmpty) {
      buttons.add(_buildResponsiveTabButton(
        index: index++,
        label: 'Demandes reçues',
        icon: Icons.business_center,
        isSmallScreen: isSmallScreen,
      ));
    }

    // Troisième tab : Nouveau devis (sauf pour admin)
    if (!controller.isAdmin.value) {
      buttons.add(_buildResponsiveTabButton(
        index: index++,
        label: 'Nouveau devis',
        icon: Icons.add_circle,
        isSmallScreen: isSmallScreen,
      ));
    }

    return buttons;
  }

  Widget _buildResponsiveTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          height: 48,
          color: Colors.transparent,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedTabIndex == index || !isSmallScreen
                ? Container(
                    key: ValueKey('$index-full'),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: isSmallScreen ? 18 : 20,
                          color: _selectedTabIndex == index
                              ? CustomTheme.lightScheme().primary
                              : Colors.grey[600],
                        ),
                        if (!isSmallScreen || _selectedTabIndex == index) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: _selectedTabIndex == index
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _selectedTabIndex == index
                                      ? CustomTheme.lightScheme().primary
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Center(
                    key: ValueKey('$index-icon'),
                    child: Icon(
                      icon,
                      size: 22,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent(QuotesScreenController controller, bool isMobile) {
    List<Widget> content = [];

    // Premier tab : Mes demandes ou Tous les devis (admin)
    content.add(SlideTransition(
      position: _slideAnimation,
      child: controller.isAdmin.value
          ? _buildAllQuotes(controller)
          : _buildMyQuotes(controller),
    ));

    // Deuxième tab : Demandes reçues (si entreprise)
    if (!controller.isAdmin.value && controller.enterpriseQuotes.isNotEmpty) {
      content.add(SlideTransition(
        position: _slideAnimation,
        child: _buildReceivedQuotes(controller),
      ));
    }

    // Troisième tab : Nouveau devis (sauf pour admin)
    if (!controller.isAdmin.value) {
      content.add(GeneralQuoteForm(
        controller: controller,
        isMobile: isMobile,
      ));
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuotesScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;

    return ScreenLayout(
      noFAB: true,
      body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          CustomTheme.lightScheme().primary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement des devis...',
                    style: TextStyle(
                      color: CustomTheme.lightScheme().onSurface.withOpacity(0.6),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header moderne sans simulateur
                if (!controller.isAdmin.value)
                  _buildModernHeader(controller, isMobile),

                // Modern Tabs avec style shop_establishment
                _buildModernTabs(controller),

                // Contenu des tabs avec IndexedStack
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: _buildTabContent(controller, isMobile),
                  ),
                ),
              ],
            ),
          );
      }),
    );
  }

  Widget _buildModernHeader(QuotesScreenController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          // Bouton Simulateur en haut
          _buildSimulatorButton(controller, isMobile),
          const SizedBox(height: 16),

          // Titre et description
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.shade200.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Devis',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créez et gérez vos demandes de devis',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.orange.shade700.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorButton(QuotesScreenController controller, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSimulatorDialog(controller, isMobile),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CustomTheme.lightScheme().primary,
                CustomTheme.lightScheme().primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulateur de Devis',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Estimez rapidement vos économies',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimulatorDialog(QuotesScreenController controller, bool isMobile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomTheme.lightScheme().primary,
                        CustomTheme.lightScheme().primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Simulateur de Devis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildSimulatorContent(controller, isMobile),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulatorContent(QuotesScreenController controller, bool isMobile) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Montant du devis
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.euro,
                    color: CustomTheme.lightScheme().primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Montant du devis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.simulatorAmountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => controller.calculateSimulation(),
                decoration: InputDecoration(
                  hintText: 'Entrez le montant',
                  prefixText: '€ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CustomTheme.lightScheme().primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Type de projet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: CustomTheme.lightScheme().primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Type de projet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: controller.selectedProjectType.value.isEmpty
                    ? null
                    : controller.selectedProjectType.value,
                items: controller.projectTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedProjectType.value = value;
                    controller.calculateSimulation();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Sélectionnez un type',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CustomTheme.lightScheme().primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Résultats
        if (controller.simulatedSavings.value > 0) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[50]!,
                  Colors.green[100]!.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Économies estimées',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.simulatedSavings.value.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jusqu\'à ${controller.simulatedPercentage.value}% d\'économies',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Les économies sont calculées en fonction du type de projet et peuvent varier selon les partenaires.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    ));
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
                // Bouton d'attribution pour les demandes générales sans entreprise
                if (quote.isGeneralRequest && quote.enterpriseId == null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Demande générale',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.dialog(AdminQuoteAssignmentDialog(
                            quote: quote,
                            controller: controller,
                          ));
                        },
                        icon: const Icon(Icons.assignment_turned_in, size: 16, color: Colors.white),
                        label: const Text('Attribuer', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomTheme.lightScheme().primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
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