import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/custom_theme.dart';
import '../controllers/quotes_screen_controller.dart';

class GeneralQuoteForm extends StatefulWidget {
  final QuotesScreenController controller;
  final bool isMobile;

  const GeneralQuoteForm({
    super.key,
    required this.controller,
    this.isMobile = false,
  });

  @override
  State<GeneralQuoteForm> createState() => _GeneralQuoteFormState();
}

class _GeneralQuoteFormState extends State<GeneralQuoteForm> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.isMobile ? double.infinity : 800,
              ),
              child: Form(
                key: widget.controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre moderne avec icône orange
                    Container(
                      padding: EdgeInsets.all(widget.isMobile ? 20 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade50,
                            Colors.orange.shade100.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
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
                                  'Un projet ou besoin de devis ?',
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Remplissez ce formulaire et nous trouverons les meilleures entreprises pour vous',
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 13 : 14,
                                    color: Colors.orange.shade700.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Informations personnelles avec icône
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
                    const SizedBox(height: 16),

                    _buildModernTextField(
                      controller: widget.controller.userNameController,
                      label: 'Nom complet',
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    if (isSmallScreen)
                      Column(
                        children: [
                          _buildModernTextField(
                            controller: widget.controller.userEmailController,
                            label: 'Email',
                            icon: Icons.email,
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
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: widget.controller.userPhoneController,
                            label: 'Téléphone',
                            icon: Icons.phone,
                            iconColor: Colors.purple,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre téléphone';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              controller: widget.controller.userEmailController,
                              label: 'Email',
                              icon: Icons.email,
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
                              controller: widget.controller.userPhoneController,
                              label: 'Téléphone',
                              icon: Icons.phone,
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

                    // Section Projet avec icône
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.work,
                            color: Colors.orange.shade600,
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
                    const SizedBox(height: 16),

                    _buildModernTextField(
                      controller: widget.controller.projectTypeController,
                      label: 'Type de projet',
                      hint: 'Ex: Rénovation cuisine, Installation panneaux solaires...',
                      icon: Icons.home_repair_service,
                      iconColor: Colors.orange,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez décrire le type de projet';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildModernTextField(
                      controller: widget.controller.projectDescriptionController,
                      label: 'Description détaillée',
                      hint: 'Décrivez votre projet en détail...',
                      icon: Icons.description,
                      iconColor: Colors.indigo,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez décrire votre projet';
                        }
                        if (value.length < 20) {
                          return 'Description trop courte (min 20 caractères)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildModernTextField(
                      controller: widget.controller.estimatedBudgetController,
                      label: 'Budget estimé (optionnel)',
                      icon: Icons.euro,
                      iconColor: Colors.teal,
                      keyboardType: TextInputType.number,
                      suffix: '€',
                    ),

                    const SizedBox(height: 32),

                    // Message d'information moderne
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Votre demande sera transmise à notre équipe qui sélectionnera les meilleures entreprises partenaires pour votre projet.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: widget.isMobile ? 12 : 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton de soumission moderne
                    Center(
                      child: Obx(() => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: widget.controller.isLoading.value
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
                          onPressed: widget.controller.isLoading.value
                              ? null
                              : () => widget.controller.submitQuoteRequest(isGeneralRequest: true),
                          icon: widget.controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            widget.controller.isLoading.value
                                ? 'Envoi en cours...'
                                : 'Envoyer ma demande',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomTheme.lightScheme().primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isMobile ? 24 : 40,
                              vertical: widget.isMobile ? 14 : 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
}