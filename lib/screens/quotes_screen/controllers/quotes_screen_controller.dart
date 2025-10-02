import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/models/establishement.dart';
import '../../../core/services/quote_email_service.dart';

class QuotesScreenController extends GetxController with ControllerMixin {
  // Liste des devis
  RxList<QuoteRequest> userQuotes = <QuoteRequest>[].obs;
  RxList<QuoteRequest> enterpriseQuotes = <QuoteRequest>[].obs;
  
  // Filtres
  RxString selectedStatus = 'all'.obs;
  RxBool isLoading = false.obs;
  
  // Formulaire
  final formKey = GlobalKey<FormState>();
  final projectTypeController = TextEditingController();
  final projectDescriptionController = TextEditingController();
  final estimatedBudgetController = TextEditingController();
  final userNameController = TextEditingController();
  final userEmailController = TextEditingController();
  final userPhoneController = TextEditingController();
  
  // Enterprise sélectionnée pour le devis
  Rx<Establishment?> selectedEnterprise = Rx<Establishment?>(null);
  
  // Statistiques
  RxMap<String, int> quoteCountByEnterprise = <String, int>{}.obs;
  RxInt totalQuotesCount = 0.obs;
  
  // Stream subscriptions
  StreamSubscription? _userQuotesSub;
  StreamSubscription? _enterpriseQuotesSub;

  // Admin flag
  RxBool isAdmin = false.obs;
  RxList<QuoteRequest> allQuotes = <QuoteRequest>[].obs;
  StreamSubscription? _allQuotesSub;

  // Simulateur
  final simulatorAmountController = TextEditingController();
  RxDouble simulatedSavings = 0.0.obs;
  RxInt simulatedPercentage = 0.obs;
  RxString selectedProjectType = ''.obs;

  final List<String> projectTypes = [
    'Rénovation',
    'Construction',
    'Plomberie',
    'Électricité',
    'Peinture',
    'Menuiserie',
    'Chauffage',
    'Isolation',
    'Toiture',
    'Jardinage',
    'Autre',
  ];
  
  @override
  void onInit() {
    super.onInit();
    _checkIfAdmin();
    _loadQuotes();
    _loadStatistics();
  }

  @override
  void onClose() {
    simulatorAmountController.dispose();
    projectTypeController.dispose();
    projectDescriptionController.dispose();
    estimatedBudgetController.dispose();
    userNameController.dispose();
    userEmailController.dispose();
    userPhoneController.dispose();
    _userQuotesSub?.cancel();
    _enterpriseQuotesSub?.cancel();
    _allQuotesSub?.cancel();
    super.onClose();
  }
  
  Future<void> _checkIfAdmin() async {
    final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
    if (currentUser == null) return;
    
    try {
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        final userTypeId = userDoc.data()?['user_type_id'];
        if (userTypeId != null) {
          final userTypeDoc = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('user_types')
              .doc(userTypeId)
              .get();
          
          if (userTypeDoc.exists) {
            final userTypeName = userTypeDoc.data()?['name'];
            isAdmin.value = userTypeName == 'Admin';
            
            if (isAdmin.value) {
              _loadAllQuotes();
            }
          }
        }
      }
    } catch (e) {
    }
  }
  
  void _loadAllQuotes() {
    // Charger tous les devis pour l'admin
    _allQuotesSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('quote_requests')
        .snapshots()
        .listen((snapshot) {
      try {
        allQuotes.value = snapshot.docs
            .map((doc) {
              try {
                return QuoteRequest.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .where((quote) => quote != null)
            .cast<QuoteRequest>()
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
      }
    }, onError: (error) {
    });
  }
  
  
  void _loadQuotes() {
    final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
    if (currentUser == null) return;
    
    // Charger les devis de l'utilisateur (en tant que particulier)
    _userQuotesSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('quote_requests')
        .where('user_id', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      try {
        userQuotes.value = snapshot.docs
            .map((doc) {
              try {
                return QuoteRequest.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .where((quote) => quote != null)
            .cast<QuoteRequest>()
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
      }
    }, onError: (error) {
    });
    
    // Si l'utilisateur est une entreprise, charger aussi les devis reçus
    _loadEnterpriseQuotes();
  }
  
  void _loadEnterpriseQuotes() async {
    final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
    if (currentUser == null) return;
    
    // Vérifier si l'utilisateur a un établissement
    final estabSnapshot = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .where('user_id', isEqualTo: currentUser.uid)
        .limit(1)
        .get();
    
    if (estabSnapshot.docs.isNotEmpty) {
      final establishmentId = estabSnapshot.docs.first.id;
      
      _enterpriseQuotesSub = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .where('enterprise_id', isEqualTo: establishmentId)
          .snapshots()
          .listen((snapshot) {
        try {
          enterpriseQuotes.value = snapshot.docs
              .map((doc) {
                try {
                  return QuoteRequest.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((quote) => quote != null)
              .cast<QuoteRequest>()
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } catch (e) {
        }
      }, onError: (error) {
      });
    }
  }
  
  void _loadStatistics() async {
    // Ne charger les stats globales que pour les admins
    if (!isAdmin.value) {
      // Pour les utilisateurs normaux, juste compter leurs propres devis
      totalQuotesCount.value = userQuotes.length + enterpriseQuotes.length;
      return;
    }
    
    // Pour les admins, charger toutes les stats
    final quotesSnapshot = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('quote_requests')
        .get();
    
    Map<String, int> counts = {};
    int total = 0;
    
    for (var doc in quotesSnapshot.docs) {
      total++;
      final enterpriseId = doc.data()['enterprise_id'] as String?;
      if (enterpriseId != null) {
        counts[enterpriseId] = (counts[enterpriseId] ?? 0) + 1;
      }
    }
    
    quoteCountByEnterprise.value = counts;
    totalQuotesCount.value = total;
  }
  
  // Soumettre une demande de devis
  Future<void> submitQuoteRequest({
    Establishment? enterprise,
    bool isGeneralRequest = false,
  }) async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    
    try {
      final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
      if (currentUser == null) throw 'Utilisateur non connecté';
      
      final quoteData = {
        'user_id': currentUser.uid,
        'enterprise_id': isGeneralRequest ? null : enterprise?.id,
        'enterprise_name': isGeneralRequest ? null : enterprise?.name,
        'user_name': userNameController.text,
        'user_email': userEmailController.text,
        'user_phone': userPhoneController.text,
        'project_type': projectTypeController.text,
        'project_description': projectDescriptionController.text,
        'estimated_budget': double.tryParse(estimatedBudgetController.text),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'points_claimed': false,
        'is_general_request': isGeneralRequest,
      };
      
      // Ajouter le devis
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .add(quoteData);
      
      // Incrémenter le compteur pour l'entreprise
      if (!isGeneralRequest && enterprise != null) {
        await _incrementEnterpriseQuoteCount(enterprise.id);
      }
      
      // Notifier l'entreprise ou l'admin
      if (isGeneralRequest) {
        await _notifyAdmin(quoteData);
      } else if (enterprise != null) {
        await _notifyEnterprise(enterprise, quoteData);
      }
      
      // Réinitialiser le formulaire
      _resetForm();
      
      Get.back();
      UniquesControllers().data.snackbar(
        'Succès',
        'Votre demande de devis a été envoyée',
        false,
      );
      
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'envoyer la demande: $e',
        true,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _incrementEnterpriseQuoteCount(String enterpriseId) async {
    final statsRef = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('quote_statistics')
        .doc(enterpriseId);
    
    final doc = await statsRef.get();
    if (doc.exists) {
      await statsRef.update({
        'total_quotes': FieldValue.increment(1),
        'last_quote_date': FieldValue.serverTimestamp(),
      });
    } else {
      await statsRef.set({
        'enterprise_id': enterpriseId,
        'total_quotes': 1,
        'last_quote_date': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> _notifyAdmin(Map<String, dynamic> quoteData) async {
    // Créer une notification pour l'admin
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('admin_notifications')
        .add({
      'type': 'general_quote_request',
      'quote_data': quoteData,
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  
  Future<void> _notifyEnterprise(Establishment enterprise, Map<String, dynamic> quoteData) async {
    // Créer une notification pour l'entreprise
    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('notifications')
        .add({
      'user_id': enterprise.userId,
      'type': 'quote_request',
      'title': 'Nouvelle demande de devis',
      'message': 'Vous avez reçu une nouvelle demande de devis pour ${quoteData['project_type']}',
      'quote_id': quoteData['id'],
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    });
    
    // Envoyer un email à l'entreprise
    await QuoteEmailService.sendNewQuoteRequestEmail(
      quoteData: quoteData,
      enterprise: enterprise,
    );
  }
  
  // Répondre à un devis (pour les entreprises)
  Future<void> respondToQuote(
    String quoteId,
    String response,
    double quotedAmount,
  ) async {
    try {
      // Récupérer les infos du devis pour l'email
      final quoteDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .get();
      
      if (!quoteDoc.exists) {
        throw Exception('Devis introuvable');
      }
      
      final quoteData = quoteDoc.data()!;
      
      // Mettre à jour le devis
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'status': 'responded',
        'enterprise_response': response,
        'quoted_amount': quotedAmount,
        'responded_at': FieldValue.serverTimestamp(),
        'points_generated': _calculatePoints(quotedAmount),
      });
      
      // Envoyer un email au client
      await QuoteEmailService.sendQuoteResponseEmail(
        userEmail: quoteData['user_email'],
        userName: quoteData['user_name'],
        enterpriseName: quoteData['enterprise_name'] ?? 'L\'entreprise',
        projectType: quoteData['project_type'],
        response: response,
        quotedAmount: quotedAmount,
      );
      
      UniquesControllers().data.snackbar(
        'Succès',
        'Réponse envoyée au client',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'envoyer la réponse: $e',
        true,
      );
    }
  }
  
  // Calculer les points générés par un devis
  int _calculatePoints(double amount) {
    // 2% du montant en points
    return (amount * 0.02).round();
  }

  // Attribuer une demande générale à une entreprise (admin only)
  Future<void> assignQuoteToEnterprise({
    required String quoteId,
    required String enterpriseId,
  }) async {
    try {
      // Vérifier que l'utilisateur est admin
      if (!isAdmin.value) {
        throw 'Seuls les administrateurs peuvent attribuer des devis';
      }

      // Récupérer les infos du devis
      final quoteDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .get();

      if (!quoteDoc.exists) {
        throw 'Devis introuvable';
      }

      final quoteData = quoteDoc.data()!;

      // Récupérer les infos de l'entreprise
      final enterpriseDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(enterpriseId)
          .get();

      if (!enterpriseDoc.exists) {
        throw 'Entreprise introuvable';
      }

      final data = enterpriseDoc.data()!;
      final establishment = Establishment(
        id: enterpriseDoc.id,
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

      // Mettre à jour le devis avec l'entreprise assignée
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'enterprise_id': enterpriseId,
        'enterprise_name': establishment.name,
        'assigned_by_admin': true,
        'assigned_at': FieldValue.serverTimestamp(),
        'is_general_request': false, // N'est plus une demande générale
      });

      // Notifier l'entreprise
      await _notifyEnterprise(establishment, {
        ...quoteData,
        'enterprise_id': enterpriseId,
        'enterprise_name': establishment.name,
      });

      // Créer une notification pour l'entreprise
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .add({
        'user_id': establishment.userId,
        'type': 'quote_assigned',
        'title': 'Nouveau devis attribué',
        'message': 'Un administrateur vous a attribué une demande de devis pour ${quoteData['project_type']}',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      UniquesControllers().data.snackbar(
        'Succès',
        'Devis attribué à ${establishment.name}',
        false,
      );

      // Recharger les devis
      _loadQuotes();

    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        e.toString(),
        true,
      );
    }
  }
  
  // Réclamer les points (après signature du devis)
  Future<void> claimPoints(String quoteId) async {
    try {
      final quoteDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .get();
      
      if (!quoteDoc.exists) throw 'Devis introuvable';
      
      final quoteData = quoteDoc.data()!;
      if (quoteData['status'] != 'accepted') {
        throw 'Le devis doit être accepté et signé pour recevoir les points';
      }
      
      if (quoteData['points_claimed'] == true) {
        throw 'Les points ont déjà été réclamés';
      }
      
      final points = quoteData['points_generated'] ?? 0;
      final userId = quoteData['user_id'];
      
      // Ajouter les points à l'utilisateur
      final userRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId);
      
      await userRef.update({
        'points': FieldValue.increment(points),
      });
      
      // Marquer les points comme réclamés
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'points_claimed': true,
        'points_claimed_at': FieldValue.serverTimestamp(),
      });
      
      UniquesControllers().data.snackbar(
        'Succès',
        'Vous avez reçu $points points !',
        false,
      );
      
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        e.toString(),
        true,
      );
    }
  }
  
  void resetForm() {
    projectTypeController.clear();
    projectDescriptionController.clear();
    estimatedBudgetController.clear();
    userNameController.clear();
    userEmailController.clear();
    userPhoneController.clear();
  }
  
  void _resetForm() {
    resetForm();
  }
  
  // Filtrer les devis par statut
  List<QuoteRequest> getFilteredQuotes(List<QuoteRequest> quotes) {
    if (selectedStatus.value == 'all') return quotes;
    return quotes.where((q) => q.status == selectedStatus.value).toList();
  }

  // Calculer la simulation d'économies
  void calculateSimulation() {
    final amountStr = simulatorAmountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0 || selectedProjectType.value.isEmpty) {
      simulatedSavings.value = 0.0;
      simulatedPercentage.value = 0;
      return;
    }

    // Pourcentages d'économies par type de projet
    final savingsPercentages = {
      'Rénovation': 15,
      'Construction': 20,
      'Plomberie': 12,
      'Électricité': 10,
      'Peinture': 18,
      'Menuiserie': 15,
      'Chauffage': 14,
      'Isolation': 16,
      'Toiture': 12,
      'Jardinage': 25,
      'Autre': 10,
    };

    final percentage = savingsPercentages[selectedProjectType.value] ?? 10;
    simulatedPercentage.value = percentage;
    simulatedSavings.value = amount * (percentage / 100);
  }
  
  // Accepter un devis (pour le client)
  Future<void> acceptQuote(String quoteId) async {
    try {
      // Récupérer les infos du devis
      final quoteDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .get();
      
      if (!quoteDoc.exists) {
        throw Exception('Devis introuvable');
      }
      
      final quoteData = quoteDoc.data()!;
      final enterpriseId = quoteData['enterprise_id'];
      
      // Récupérer les infos de l'entreprise
      Establishment? enterprise;
      if (enterpriseId != null) {
        final estabDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(enterpriseId)
            .get();
        
        if (estabDoc.exists) {
          enterprise = Establishment.fromDocument(estabDoc);
        }
      }
      
      // Mettre à jour le statut du devis
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
      });
      
      // Envoyer un email à l'entreprise si elle existe
      if (enterprise != null) {
        await QuoteEmailService.sendQuoteAcceptedEmail(
          enterpriseEmail: enterprise.email,
          enterpriseName: enterprise.name,
          userName: quoteData['user_name'],
          projectType: quoteData['project_type'],
          quotedAmount: quoteData['quoted_amount'] ?? 0,
        );
      }
      
      UniquesControllers().data.snackbar(
        'Succès',
        'Devis accepté avec succès',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'accepter le devis: $e',
        true,
      );
    }
  }
  
  // Refuser un devis (pour le client)
  Future<void> rejectQuote(String quoteId) async {
    try {
      // Récupérer les infos du devis
      final quoteDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .get();
      
      if (!quoteDoc.exists) {
        throw Exception('Devis introuvable');
      }
      
      final quoteData = quoteDoc.data()!;
      final enterpriseId = quoteData['enterprise_id'];
      
      // Récupérer les infos de l'entreprise
      Establishment? enterprise;
      if (enterpriseId != null) {
        final estabDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(enterpriseId)
            .get();
        
        if (estabDoc.exists) {
          enterprise = Establishment.fromDocument(estabDoc);
        }
      }
      
      // Mettre à jour le statut du devis
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('quote_requests')
          .doc(quoteId)
          .update({
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
      });
      
      // Envoyer un email à l'entreprise si elle existe
      if (enterprise != null) {
        await QuoteEmailService.sendQuoteRejectedEmail(
          enterpriseEmail: enterprise.email,
          enterpriseName: enterprise.name,
          userName: quoteData['user_name'],
          projectType: quoteData['project_type'],
        );
      }
      
      UniquesControllers().data.snackbar(
        'Info',
        'Devis refusé',
        false,
      );
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de refuser le devis: $e',
        true,
      );
    }
  }
}