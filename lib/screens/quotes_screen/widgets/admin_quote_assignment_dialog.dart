import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/establishement.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/theme/custom_theme.dart';
import '../controllers/quotes_screen_controller.dart';

class AdminQuoteAssignmentDialog extends StatefulWidget {
  final QuoteRequest quote;
  final QuotesScreenController controller;

  const AdminQuoteAssignmentDialog({
    super.key,
    required this.quote,
    required this.controller,
  });

  @override
  State<AdminQuoteAssignmentDialog> createState() => _AdminQuoteAssignmentDialogState();
}

class _AdminQuoteAssignmentDialogState extends State<AdminQuoteAssignmentDialog> {
  String? selectedEnterpriseId;
  List<Establishment> enterprises = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEnterprises();
  }

  Future<void> _loadEnterprises() async {
    try {
      // Charger toutes les entreprises de type "Entreprise"
      final userTypeSnapshot = await FirebaseFirestore.instance
          .collection('user_types')
          .where('name', isEqualTo: 'Entreprise')
          .limit(1)
          .get();

      if (userTypeSnapshot.docs.isEmpty) return;

      final enterpriseTypeId = userTypeSnapshot.docs.first.id;

      final snapshot = await FirebaseFirestore.instance
          .collection('establishments')
          .where('user_type_id', isEqualTo: enterpriseTypeId)
          .get();

      setState(() {
        enterprises = snapshot.docs.map((doc) {
          final data = doc.data();
          return Establishment(
            id: doc.id,
            name: data['name'] ?? '',
            userId: data['user_id'] ?? '',
            description: data['description'] ?? '',
            address: data['address'] ?? '',
            email: data['email'] ?? '',
            telephone: data['telephone'] ?? '',
            logoUrl: data['logo_url'] ?? '',
            bannerUrl: data['banner_url'] ?? '',
            categoryId: data['category_id'] ?? '',
            enterpriseCategoryIds: data['enterprise_category_ids'] != null
                ? List<String>.from(data['enterprise_category_ids'])
                : null,
            enterpriseCategorySlots: data['enterprise_category_slots'] ?? 0,
            videoUrl: data['video_url'] ?? '',
            hasAcceptedContract: data['has_accepted_contract'] ?? false,
            affiliatesCount: data['affiliates_count'] ?? 0,
            isVisibleOverride: data['is_visible_override'] ?? false,
            isAssociation: data['is_association'] ?? false,
            maxVouchersPurchase: data['max_vouchers_purchase'] ?? 1,
            cashbackPercentage: (data['cashback_percentage'] ?? 0).toDouble(),
            website: data['website'],
            isPremiumSponsor: data['is_premium_sponsor'],
            isVisible: data['is_visible'] ?? true,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement entreprises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Establishment> get filteredEnterprises {
    if (searchQuery.isEmpty) return enterprises;
    return enterprises.where((e) {
      return e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (e.description.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
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
            // Header avec le même style que QuoteFormDialog
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
                          'Attribuer le devis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.quote.projectType,
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
                  // Liste des entreprises (côté gauche)
                  Expanded(
                    flex: isDesktop ? 3 : 1,
                    child: Column(
                      children: [
                        // Info du devis avec style amélioré
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.blue[200]!),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Client',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          widget.quote.userName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.euro,
                                      size: 20,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Budget',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${widget.quote.estimatedBudget ?? "Non spécifié"} €',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Barre de recherche avec style amélioré
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une entreprise...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: CustomTheme.lightScheme().primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),

                        // Liste des entreprises
                        Expanded(
                          child: isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: CustomTheme.lightScheme().primary,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Chargement des entreprises...'),
                                    ],
                                  ),
                                )
                              : filteredEnterprises.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.business_center_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            searchQuery.isEmpty
                                                ? 'Aucune entreprise disponible'
                                                : 'Aucune entreprise trouvée',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: filteredEnterprises.length,
                                      itemBuilder: (context, index) {
                                        final enterprise = filteredEnterprises[index];
                                        final isSelected = selectedEnterpriseId == enterprise.id;

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? CustomTheme.lightScheme().primary
                                                  : Colors.grey[300]!,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            color: isSelected
                                                ? CustomTheme.lightScheme().primary.withOpacity(0.05)
                                                : Colors.white,
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: CustomTheme.lightScheme()
                                                          .primary
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedEnterpriseId = enterprise.id;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    // Logo
                                                    Container(
                                                      width: 56,
                                                      height: 56,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[100],
                                                        border: Border.all(
                                                          color: Colors.grey[300]!,
                                                          width: 2,
                                                        ),
                                                        image: enterprise.logoUrl.isNotEmpty
                                                            ? DecorationImage(
                                                                image: NetworkImage(enterprise.logoUrl),
                                                                fit: BoxFit.cover,
                                                              )
                                                            : null,
                                                      ),
                                                      child: enterprise.logoUrl.isEmpty
                                                          ? Icon(
                                                              Icons.business,
                                                              color: Colors.grey[600],
                                                              size: 28,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Infos
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            enterprise.name,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            enterprise.description,
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.grey[600],
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Radio
                                                    Radio<String>(
                                                      value: enterprise.id,
                                                      groupValue: selectedEnterpriseId,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          selectedEnterpriseId = value;
                                                        });
                                                      },
                                                      activeColor: CustomTheme.lightScheme().primary,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),

                  // Panneau latéral pour desktop
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
                          // Info sélection
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
                                  Icons.assignment_turned_in,
                                  color: Colors.orange[700],
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Attribution du devis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange[900],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedEnterpriseId != null
                                      ? 'Entreprise sélectionnée'
                                      : 'Sélectionnez une entreprise',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
                                ElevatedButton.icon(
                                  onPressed: selectedEnterpriseId == null
                                      ? null
                                      : () async {
                                          Get.back();
                                          await widget.controller.assignQuoteToEnterprise(
                                            quoteId: widget.quote.id,
                                            enterpriseId: selectedEnterpriseId!,
                                          );
                                        },
                                  icon: const Icon(Icons.send, color: Colors.white),
                                  label: const Text(
                                    'Attribuer le devis',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CustomTheme.lightScheme().primary,
                                    disabledBackgroundColor: Colors.grey[300],
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
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
                      child: ElevatedButton.icon(
                        onPressed: selectedEnterpriseId == null
                            ? null
                            : () async {
                                Get.back();
                                await widget.controller.assignQuoteToEnterprise(
                                  quoteId: widget.quote.id,
                                  enterpriseId: selectedEnterpriseId!,
                                );
                              },
                        icon: const Icon(Icons.send, size: 18, color: Colors.white),
                        label: const Text('Attribuer', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomTheme.lightScheme().primary,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}