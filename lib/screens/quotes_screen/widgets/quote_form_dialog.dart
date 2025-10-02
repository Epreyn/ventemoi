import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../controllers/quotes_screen_controller.dart';

class QuoteFormDialog extends StatefulWidget {
  final Establishment enterprise;
  final QuotesScreenController? controller;

  const QuoteFormDialog({
    super.key,
    required this.enterprise,
    this.controller,
  });

  @override
  State<QuoteFormDialog> createState() => _QuoteFormDialogState();
}

class _QuoteFormDialogState extends State<QuoteFormDialog> with SingleTickerProviderStateMixin {
  late QuotesScreenController controller;
  double simulatedAmount = 0;
  int simulatedPoints = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Utiliser le controller passé en paramètre ou en créer un nouveau
    controller = widget.controller ?? Get.put(QuotesScreenController());

    // Réinitialiser le formulaire si c'est un nouveau controller
    if (widget.controller == null) {
      controller.resetForm();
    }

    // Pré-remplir avec les infos de l'utilisateur connecté si disponible
    _prefillUserInfo();

    // Animations
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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  void _prefillUserInfo() async {
    final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
    if (currentUser != null) {
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        setState(() {
          controller.userNameController.text = userData['name'] ?? '';
          controller.userEmailController.text = userData['email'] ?? '';
          controller.userPhoneController.text = userData['telephone'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    // Ne disposer le controller que si on l'a créé localement
    if (widget.controller == null) {
      controller.onClose();
    }
    _animationController.dispose();
    super.dispose();
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
    final isMobile = screenSize.width <= 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 16 : 32),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: isDesktop ? 900 : screenSize.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header moderne style GeneralQuoteForm
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade100.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.orange.shade200.withOpacity(0.3),
                        width: 1,
                      ),
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
                          Icons.description,
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
                              'Demander un devis',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.enterprise.name,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: Colors.orange.shade700.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu avec scroll
                Expanded(
                  child: Row(
                    children: [
                      // Formulaire principal
                      Expanded(
                        flex: isDesktop ? 3 : 1,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Informations personnelles
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Vos informations',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: controller.userNameController,
                                  label: 'Nom complet',
                                  icon: Icons.person_outline,
                                  iconColor: Colors.blue,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre nom';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: controller.userEmailController,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        iconColor: Colors.green,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre email';
                                          }
                                          if (!GetUtils.isEmail(value)) {
                                            return 'Email invalide';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: controller.userPhoneController,
                                        label: 'Téléphone',
                                        icon: Icons.phone_outlined,
                                        iconColor: Colors.purple,
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre téléphone';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Section Détails du projet
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.work_outline,
                                        color: Colors.green.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Votre projet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Dropdown type de projet avec style moderne
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: controller.selectedProjectType.value.isNotEmpty
                                        ? controller.selectedProjectType.value
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: 'Type de projet',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.category_outlined,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: controller.projectTypes.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      controller.selectedProjectType.value = value ?? '';
                                      controller.projectTypeController.text = value ?? '';
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez sélectionner un type de projet';
                                      }
                                      return null;
                                    },
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: controller.projectDescriptionController,
                                  label: 'Description du projet',
                                  hint: 'Décrivez votre projet en détail...',
                                  icon: Icons.description_outlined,
                                  iconColor: Colors.amber,
                                  maxLines: 4,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez décrire votre projet';
                                    }
                                    return null;
                                  },
                                ),

                                // Simulation de points
                                if (simulatedPoints > 0) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade50,
                                          Colors.green.shade100.withOpacity(0.5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.stars,
                                            color: Colors.green.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Points de fidélité estimés',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$simulatedPoints points',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: controller.estimatedBudgetController,
                                  label: 'Budget estimé',
                                  icon: Icons.euro_outlined,
                                  iconColor: Colors.teal,
                                  keyboardType: TextInputType.number,
                                  suffix: '€',
                                  onChanged: (_) => _simulatePoints(),
                                ),

                                const SizedBox(height: 32),

                                // Bouton d'envoi
                                Center(
                                  child: Obx(() => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: controller.isLoading.value
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : () => controller.submitQuoteRequest(
                                                enterprise: widget.enterprise,
                                                isGeneralRequest: false,
                                              ),
                                      icon: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.send, color: Colors.white),
                                      label: Text(
                                        controller.isLoading.value
                                            ? 'Envoi en cours...'
                                            : 'Envoyer ma demande',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: CustomTheme.lightScheme().primary,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 24 : 40,
                                          vertical: isMobile ? 14 : 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Panneau latéral pour desktop
                      if (isDesktop)
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              // Logo de l'entreprise
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  image: widget.enterprise.logoUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(widget.enterprise.logoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: widget.enterprise.logoUrl.isEmpty
                                    ? Icon(
                                        Icons.business,
                                        size: 50,
                                        color: Colors.blue.shade300,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                widget.enterprise.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.enterprise.description,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Avantages
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.blue.shade600,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Pourquoi nous choisir ?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAdvantage(Icons.check_circle, 'Devis gratuit'),
                                    _buildAdvantage(Icons.speed, 'Réponse rapide'),
                                    _buildAdvantage(Icons.star, 'Service de qualité'),
                                    _buildAdvantage(Icons.card_giftcard, '2% en points fidélité'),
                                  ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    TextInputType? keyboardType,
    String? suffix,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        suffixText: suffix,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CustomTheme.lightScheme().primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildAdvantage(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}