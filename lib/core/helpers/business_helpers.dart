import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../config/app_theme_config.dart';

/// Classe d'helpers pour les fonctions métier de l'application
class BusinessHelpers {
  // ============================================================================
  // USER HELPERS
  // ============================================================================
  
  /// Récupère l'utilisateur connecté
  static User? getCurrentUser() {
    // Utiliser GetX pour récupérer l'utilisateur stocké
    if (Get.isRegistered<User>()) {
      return Get.find<User>();
    }
    return null;
  }
  
  /// Vérifie si l'utilisateur est un administrateur
  static bool isAdmin() {
    final user = getCurrentUser();
    return user?.userTypeID == 'admin';
  }
  
  /// Vérifie si l'utilisateur est un professionnel
  static bool isProfessional() {
    final user = getCurrentUser();
    return user?.userTypeID == 'professional' || user?.userTypeID == 'pro';
  }
  
  /// Vérifie si l'utilisateur est un particulier
  static bool isIndividual() {
    final user = getCurrentUser();
    return user?.userTypeID == 'individual' || user?.userTypeID == 'particulier';
  }
  
  /// Récupère les initiales de l'utilisateur
  static String getUserInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    
    final words = name.trim().split(' ');
    final initials = words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    
    return initials;
  }
  
  // ============================================================================
  // FORMATTERS
  // ============================================================================
  
  /// Formate un montant en euros
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }
  
  /// Formate un pourcentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
  
  /// Formate une date
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Formate une date avec l'heure
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Formate une date relative (il y a X temps)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return 'Il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
  
  /// Formate un numéro de téléphone
  static String formatPhoneNumber(String phone) {
    // Enlever tous les caractères non numériques
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format français : 06 12 34 56 78
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8)}';
    }
    
    // Format international : +33 6 12 34 56 78
    if (cleaned.length == 11 && cleaned.startsWith('33')) {
      return '+33 ${cleaned.substring(2, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)} ${cleaned.substring(9)}';
    }
    
    return phone;
  }
  
  // ============================================================================
  // VALIDATORS
  // ============================================================================
  
  /// Valide une adresse email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Adresse email invalide';
    }
    
    return null;
  }
  
  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    
    return null;
  }
  
  /// Valide un numéro de téléphone
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 10 && cleaned.length != 11) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }
  
  /// Valide un code postal
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code postal est requis';
    }
    
    if (value.length != 5 || !RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Code postal invalide';
    }
    
    return null;
  }
  
  // ============================================================================
  // CALCULATIONS
  // ============================================================================
  
  /// Calcule la commission sur un montant
  static double calculateCommission(double amount, double commissionRate) {
    return amount * (commissionRate / 100);
  }
  
  /// Calcule le montant TTC à partir du HT
  static double calculateTTC(double amountHT, {double tvaRate = 20}) {
    return amountHT * (1 + tvaRate / 100);
  }
  
  /// Calcule le montant HT à partir du TTC
  static double calculateHT(double amountTTC, {double tvaRate = 20}) {
    return amountTTC / (1 + tvaRate / 100);
  }
  
  /// Calcule le pourcentage de changement
  static double calculateChangePercentage(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }
  
  // ============================================================================
  // FIRESTORE HELPERS
  // ============================================================================
  
  /// Convertit un Timestamp Firestore en DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return null;
  }
  
  /// Convertit un DateTime en Timestamp Firestore
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
  
  /// Récupère un document Firestore par ID
  static Future<DocumentSnapshot?> getDocument(String collection, String id) async {
    try {
      return await FirebaseFirestore.instance.collection(collection).doc(id).get();
    } catch (e) {
      return null;
    }
  }
  
  /// Met à jour un document Firestore
  static Future<bool> updateDocument(String collection, String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // ============================================================================
  // UI HELPERS
  // ============================================================================
  
  /// Affiche un snackbar de succès
  static void showSuccess(String message) {
    Get.snackbar(
      'Succès',
      message,
      backgroundColor: AppThemeConfig.successColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(AppThemeConfig.spaceMD),
      borderRadius: AppThemeConfig.cardBorderRadius,
    );
  }
  
  /// Affiche un snackbar d'erreur
  static void showError(String message) {
    Get.snackbar(
      'Erreur',
      message,
      backgroundColor: AppThemeConfig.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(AppThemeConfig.spaceMD),
      borderRadius: AppThemeConfig.cardBorderRadius,
    );
  }
  
  /// Affiche un snackbar d'information
  static void showInfo(String message) {
    Get.snackbar(
      'Information',
      message,
      backgroundColor: AppThemeConfig.infoColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(AppThemeConfig.spaceMD),
      borderRadius: AppThemeConfig.cardBorderRadius,
    );
  }
  
  /// Affiche un dialog de confirmation
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title, style: AppThemeConfig.h4),
        content: Text(message, style: AppThemeConfig.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.cardBorderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeConfig.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================
  
  /// Navigue vers une route
  static void navigateTo(String route, {dynamic arguments}) {
    Get.toNamed(route, arguments: arguments);
  }
  
  /// Remplace la route actuelle
  static void replaceTo(String route, {dynamic arguments}) {
    Get.offNamed(route, arguments: arguments);
  }
  
  /// Remplace toutes les routes
  static void replaceAllTo(String route, {dynamic arguments}) {
    Get.offAllNamed(route, arguments: arguments);
  }
  
  /// Retour à la page précédente
  static void goBack({dynamic result}) {
    Get.back(result: result);
  }
}