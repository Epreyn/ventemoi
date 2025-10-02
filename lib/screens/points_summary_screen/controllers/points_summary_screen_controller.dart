import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';

class PointsSummaryScreenController extends GetxController with ControllerMixin {
  static const tag = 'points-summary-screen';

  // Observables
  final currentPoints = 0.obs;
  final pendingPoints = 0.obs;
  final totalEarnedPoints = 0.obs;
  final totalSpentPoints = 0.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final vouchers = <Map<String, dynamic>>[].obs;
  final receivedGifts = <Map<String, dynamic>>[].obs;
  final pendingTransactions = <Map<String, dynamic>>[].obs;
  final transfers = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  
  // Filtres
  final selectedFilter = 'all'.obs; // all, earned, spent, pending
  final selectedPeriod = '30'.obs; // 7, 30, 90, all (jours)
  
  // Statistiques
  final monthlyStats = <String, int>{}.obs;

  @override
  // Streams pour actualisation en temps réel
  StreamSubscription? _walletSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _transactionsSubscription;

  void onInit() {
    super.onInit();
    _initializeStreams();
    loadUserPoints();
    loadTransactions();
    loadVouchers();
    loadReceivedGifts();
    loadTransfers();
  }

  @override
  void onClose() {
    _walletSubscription?.cancel();
    _pendingSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.onClose();
  }

  void _initializeStreams() {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    // Stream pour les points actuels
    _walletSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        currentPoints.value = snapshot.docs.first.data()['points'] ?? 0;
        // Calculer le total gagné
        _updateTotalEarned();
      }
    });

    // Stream pour les points en attente (utiliser exactement la même requête que l'appBar)
    _pendingSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('points_attributions')
        .where('target_id', isEqualTo: userId)
        .where('validated', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      int pending = 0;
      for (var doc in snapshot.docs) {
        final rawPoints = doc.data()['points'] ?? 0;
        pending += (rawPoints as num).toInt();
      }
      print('📊 Points en attente (Portefeuille): $pending points');
      pendingPoints.value = pending;
    });

    // Stream pour les transactions (actualise automatiquement)
    _transactionsSubscription = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('transactions')
        .where('to_user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      loadTransactions(); // Recharger les transactions
    });
  }

  void _updateTotalEarned() {
    // Le total gagné est le total des points actuels + dépensés
    totalEarnedPoints.value = currentPoints.value + totalSpentPoints.value;
  }

  Future<void> loadUserPoints() async {
    try {
      isLoading.value = true;
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Charger les points actuels depuis le wallet
      final walletSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (walletSnap.docs.isNotEmpty) {
        currentPoints.value = walletSnap.docs.first.data()['points'] ?? 0;
      }

      // Charger les points en attente (exactement comme l'appBar)
      final pendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_attributions')
          .where('target_id', isEqualTo: userId)
          .where('validated', isEqualTo: false)
          .get();

      int pending = 0;
      for (var doc in pendingSnap.docs) {
        final rawPoints = doc.data()['points'] ?? 0;
        pending += (rawPoints as num).toInt();
      }
      print('📊 Points en attente chargés (Portefeuille): $pending points');
      pendingPoints.value = pending;

    } catch (e) {
      print('Erreur chargement points: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTransactions() async {
    try {
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      Query query = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('transactions');

      // Récupérer les transactions où l'utilisateur est impliqué
      final sentQuery = query.where('from_user_id', isEqualTo: userId);
      final receivedQuery = query.where('to_user_id', isEqualTo: userId);

      final sentSnap = await sentQuery
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final receivedSnap = await receivedQuery
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      List<Map<String, dynamic>> allTransactions = [];
      Set<String> processedIds = {}; // Pour éviter les doublons

      // Traiter les transactions envoyées (dépenses)
      for (var doc in sentSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Pour les transferts, vérifier la direction
        if (data['type'] == 'transfer' && data['direction'] == 'received') {
          continue; // Skip les transactions de réception quand on cherche les envois
        }

        if (processedIds.contains(doc.id)) continue;
        processedIds.add(doc.id);

        // Récupérer le nom de l'établissement si c'est un achat
        String recipientName = '';
        if (data['to_establishment_id'] != null) {
          recipientName = await _getEstablishmentName(data['to_establishment_id']);
        } else if (data['to_user_id'] != null) {
          recipientName = await _getUserName(data['to_user_id']);
        }

        // Conserver le type original pour les achats et dons
        final originalType = data['type'] ?? '';

        allTransactions.add({
          'id': doc.id,
          'type': 'spent',
          'points': data['points'],
          'description': _getTransactionDescription(data),
          'date': data['created_at'],
          'status': data['status'] ?? 'completed',
          'recipient_name': recipientName,
          'recipient_type': data['to_establishment_id'] != null ? 'establishment' : 'user',
          'original_type': originalType,  // Conserver le type original
          'transaction_type': originalType, // Pour compatibilité
          ...data,
        });
      }

      // Traiter les transactions reçues (gains)
      for (var doc in receivedSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Pour les transferts, vérifier la direction
        if (data['type'] == 'transfer' && data['direction'] == 'sent') {
          continue; // Skip les transactions d'envoi quand on cherche les réceptions
        }

        if (processedIds.contains(doc.id)) continue;
        processedIds.add(doc.id);

        // Récupérer le nom de l'expéditeur
        String senderName = '';
        if (data['from_user_id'] != null) {
          senderName = await _getUserName(data['from_user_id']);
        }

        allTransactions.add({
          'id': doc.id,
          'type': 'earned',
          'points': data['points'],
          'description': _getTransactionDescription(data),
          'date': data['created_at'],
          'status': data['status'] ?? 'completed',
          'sender_name': senderName,
          ...data,
        });
      }
      
      // Séparer les transactions en attente
      pendingTransactions.value = allTransactions
          .where((t) => t['status'] == 'pending')
          .toList();

      // Trier par date
      allTransactions.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      transactions.value = allTransactions;
      _calculateStats();

    } catch (e) {
      print('Erreur chargement transactions: $e');
    }
  }

  Future<void> loadVouchers() async {
    try {
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Charger les bons d'achat
      final vouchersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('vouchers')
          .where('buyer_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      vouchers.value = vouchersSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

    } catch (e) {
      print('Erreur chargement bons: $e');
      // Fallback sans orderBy si index manquant
      _loadVouchersSimple();
    }
  }

  Future<void> _loadVouchersSimple() async {
    try {
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      final vouchersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('vouchers')
          .where('buyer_id', isEqualTo: userId)
          .get();

      final vouchersList = vouchersSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Trier manuellement
      vouchersList.sort((a, b) {
        final aDate = a['created_at'] as Timestamp?;
        final bDate = b['created_at'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      vouchers.value = vouchersList.take(50).toList();
    } catch (e) {
      print('Erreur finale chargement bons: $e');
      vouchers.value = [];
    }
  }

  Future<void> loadReceivedGifts() async {
    try {
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Charger les cadeaux reçus
      final giftsSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('gifts')
          .where('recipient_id', isEqualTo: userId)
          .get();

      receivedGifts.value = giftsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'points': data['points'] ?? 0,
          'sender_name': data['sender_name'] ?? 'Anonyme',
          'message': data['message'] ?? '',
          'date': data['created_at'],
          'claimed': data['claimed'] ?? false,
          ...data,
        };
      }).toList();

      // Trier par date
      receivedGifts.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      print('Erreur chargement cadeaux: $e');
      receivedGifts.value = [];
    }
  }

  Future<void> loadTransfers() async {
    try {
      final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Charger les transferts envoyés et reçus
      final sentTransfersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('transfers')
          .where('from_user_id', isEqualTo: userId)
          .get();

      final receivedTransfersSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('transfers')
          .where('to_user_id', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> allTransfers = [];
      
      // Transferts envoyés
      for (var doc in sentTransfersSnap.docs) {
        final data = doc.data();
        final recipientName = await _getUserName(data['to_user_id']);
        allTransfers.add({
          'id': doc.id,
          'type': 'sent',
          'points': data['points'] ?? 0,
          'user_name': recipientName,
          'date': data['created_at'],
          'message': data['message'] ?? '',
          ...data,
        });
      }
      
      // Transferts reçus
      for (var doc in receivedTransfersSnap.docs) {
        final data = doc.data();
        final senderName = await _getUserName(data['from_user_id']);
        allTransfers.add({
          'id': doc.id,
          'type': 'received',
          'points': data['points'] ?? 0,
          'user_name': senderName,
          'date': data['created_at'],
          'message': data['message'] ?? '',
          ...data,
        });
      }

      // Trier par date
      allTransfers.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      transfers.value = allTransfers;
    } catch (e) {
      print('Erreur chargement transferts: $e');
      transfers.value = [];
    }
  }

  Future<String> _getEstablishmentName(String establishmentId) async {
    try {
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Établissement inconnu';
      }
    } catch (e) {
      print('Erreur récupération nom établissement: $e');
    }
    return 'Établissement';
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final firstName = data?['first_name'] ?? '';
        final lastName = data?['last_name'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim();
        }
        return data?['email'] ?? 'Utilisateur';
      }
    } catch (e) {
      print('Erreur récupération nom utilisateur: $e');
    }
    return 'Utilisateur';
  }

  String _getTransactionDescription(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final recipientName = data['recipient_name'] ?? data['to_establishment_name'] ?? '';
    final senderName = data['sender_name'] ?? '';

    switch (type) {
      case 'voucher_purchase':
      case 'purchase':
        final voucherCount = data['voucher_count'] ?? 1;
        final establishmentName = data['to_establishment_name'] ?? recipientName;
        if (establishmentName.isNotEmpty) {
          return 'Achat de $voucherCount bon(s) chez $establishmentName';
        }
        return 'Achat de $voucherCount bon(s)';
      case 'donation':
        if (recipientName.isNotEmpty) {
          return 'Don à $recipientName';
        }
        return 'Don à une association';
      case 'reward':
        return 'Récompense ${data['reason'] ?? ''}';
      case 'sponsorship':
        return 'Points de parrainage';
      case 'gift':
        if (senderName.isNotEmpty) {
          return 'Cadeau de $senderName';
        }
        return 'Cadeau reçu';
      case 'transfer':
        if (data['direction'] == 'sent' && recipientName.isNotEmpty) {
          return 'Transfert vers $recipientName';
        } else if (data['direction'] == 'received' && senderName.isNotEmpty) {
          return 'Transfert de $senderName';
        }
        return 'Transfert de points';
      default:
        return 'Transaction';
    }
  }

  void _calculateStats() {
    int earned = 0;
    int spent = 0;

    for (var transaction in transactions) {
      if (transaction['type'] == 'earned') {
        earned += (transaction['points'] as int?) ?? 0;
      } else if (transaction['type'] == 'spent') {
        spent += (transaction['points'] as int?) ?? 0;
      }
    }

    totalEarnedPoints.value = earned;
    totalSpentPoints.value = spent;

    // Calculer les statistiques mensuelles
    final Map<String, int> stats = {};
    final now = DateTime.now();
    
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.month}/${month.year}';
      stats[monthKey] = 0;
    }

    for (var transaction in transactions) {
      final date = (transaction['date'] as Timestamp?)?.toDate();
      if (date != null) {
        final monthKey = '${date.month}/${date.year}';
        if (stats.containsKey(monthKey)) {
          if (transaction['type'] == 'earned') {
            stats[monthKey] = (stats[monthKey] ?? 0) + ((transaction['points'] as int?) ?? 0);
          }
        }
      }
    }

    monthlyStats.value = stats;
  }

  List<Map<String, dynamic>> get filteredTransactions {
    List<Map<String, dynamic>> filtered = List.from(transactions);

    // Filtrer par type
    if (selectedFilter.value != 'all') {
      filtered = filtered.where((t) => t['type'] == selectedFilter.value || 
                                       (selectedFilter.value == 'pending' && t['status'] == 'pending')).toList();
    }

    // Filtrer par période
    if (selectedPeriod.value != 'all') {
      final days = int.tryParse(selectedPeriod.value) ?? 30;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      filtered = filtered.where((t) {
        final date = (t['date'] as Timestamp?)?.toDate();
        return date != null && date.isAfter(cutoffDate);
      }).toList();
    }

    return filtered;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
  }

  Future<void> refreshData() async {
    await Future.wait([
      loadUserPoints(),
      loadTransactions(),
      loadVouchers(),
    ]);
  }

  Color getTransactionColor(String type) {
    switch (type) {
      case 'earned':
        return Colors.green;
      case 'spent':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color getTransactionColorDetailed(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final originalType = transaction['original_type'] ?? transaction['transaction_type'] ?? transaction['type'] ?? '';
    final direction = transaction['direction'] ?? '';

    // Pour les transactions de type transfer
    if (originalType == 'transfer' || originalType.contains('transfer')) {
      if (direction == 'sent') {
        return Colors.blue[700]!; // Bleu foncé pour envoi
      } else if (direction == 'received') {
        return Colors.teal; // Vert-bleu pour réception
      }
    }

    // Pour les achats de bons (voucher_purchase)
    if (originalType == 'voucher_purchase' || originalType.contains('voucher') || originalType.contains('purchase')) {
      return Colors.purple; // Violet pour les achats
    }

    // Pour les dons
    if (originalType == 'donation' || originalType.contains('donation')) {
      return Colors.pink; // Rose pour les dons
    }

    // Pour les cadeaux
    if (originalType.contains('gift')) {
      return Colors.amber; // Ambre pour les cadeaux
    }

    // Pour le parrainage
    if (originalType.contains('sponsor')) {
      return Colors.indigo; // Indigo pour parrainage
    }

    // Pour les récompenses
    if (originalType.contains('reward')) {
      return Colors.orange; // Orange pour récompenses
    }

    // Couleurs par défaut selon le type simple
    if (type == 'earned') {
      return Colors.green;
    } else if (type == 'spent') {
      return Colors.red;
    } else if (type == 'pending') {
      return Colors.orange;
    }

    return Colors.grey;
  }

  IconData getTransactionIcon(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final originalType = transaction['original_type'] ?? transaction['transaction_type'] ?? '';
    final direction = transaction['direction'] ?? '';

    // Pour les transferts
    if (originalType == 'transfer' || transaction['transaction_type'] == 'transfer') {
      if (direction == 'sent') {
        return Icons.arrow_upward; // Flèche vers le haut pour envoi
      } else if (direction == 'received') {
        return Icons.arrow_downward; // Flèche vers le bas pour réception
      }
      return Icons.swap_horiz;
    }

    if (type == 'earned') {
      if (originalType.contains('gift')) return Icons.card_giftcard;
      if (originalType.contains('sponsor')) return Icons.people;
      if (originalType.contains('reward')) return Icons.emoji_events;
      return Icons.add_circle;
    } else if (type == 'spent') {
      // Vérifier spécifiquement pour les achats de bons
      if (originalType.contains('voucher') || originalType.contains('purchase')) {
        return Icons.confirmation_number;
      }
      if (originalType.contains('donation')) return Icons.volunteer_activism;
      return Icons.remove_circle;
    }
    return Icons.swap_horiz;
  }
}