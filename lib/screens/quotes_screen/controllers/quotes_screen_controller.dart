import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/models/establishement.dart';

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
  
  @override
  void onInit() {
    super.onInit();
    _loadQuotes();
    _loadStatistics();
  }
  
  @override
  void onClose() {
    _userQuotesSub?.cancel();
    _enterpriseQuotesSub?.cancel();
    projectTypeController.dispose();
    projectDescriptionController.dispose();
    estimatedBudgetController.dispose();
    userNameController.dispose();
    userEmailController.dispose();
    userPhoneController.dispose();
    super.onClose();
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
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      userQuotes.value = snapshot.docs
          .map((doc) => QuoteRequest.fromFirestore(doc))
          .toList();
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
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        enterpriseQuotes.value = snapshot.docs
            .map((doc) => QuoteRequest.fromFirestore(doc))
            .toList();
      });
    }
  }
  
  void _loadStatistics() async {
    // Charger les statistiques de demandes par entreprise
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
  }
  
  // Répondre à un devis (pour les entreprises)
  Future<void> respondToQuote(
    String quoteId,
    String response,
    double quotedAmount,
  ) async {
    try {
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
    // 1% du montant en points
    return (amount * 0.01).round();
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
}