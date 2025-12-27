import 'package:flutter/foundation.dart';
import '../models/scheduled_payment.dart';
import 'api_service.dart';

class ScheduledPaymentService {
  // Obtenir les paiements planifiés d'un utilisateur
  static Future<List<ScheduledPayment>> getScheduledPayments(String userId) async {
    try {
      final response = await ApiService.get('/scheduled-payments/user/$userId');
      final data = response['data'] as List<dynamic>;
      return data.map((json) => ScheduledPayment.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Si l'endpoint n'existe pas encore, retourner liste vide
      return [];
    }
  }

  // Créer un paiement planifié
  static Future<ScheduledPayment> createScheduledPayment(Map<String, dynamic> paymentData) async {
    final response = await ApiService.post('/scheduled-payments', paymentData);
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledPayment.fromJson(data);
  }

  // Mettre à jour un paiement planifié
  static Future<ScheduledPayment> updateScheduledPayment(
      String paymentId, Map<String, dynamic> paymentData) async {
    final response = await ApiService.put('/scheduled-payments/$paymentId', paymentData);
    final data = response['data'] as Map<String, dynamic>;
    debugPrint('   Date reçue: ${data['dueDate']}');
    debugPrint('   Données complètes: $data');
    return ScheduledPayment.fromJson(data);
  }

  // Supprimer un paiement planifié
  static Future<void> deleteScheduledPayment(String paymentId) async {
    await ApiService.delete('/scheduled-payments/$paymentId');
  }

  // Marquer comme payé
  static Future<ScheduledPayment> markAsPaid(String paymentId, DateTime paymentDate) async {
    final dateStr = paymentDate.toIso8601String().split('.')[0]; // Format: YYYY-MM-DDTHH:mm:ss
    final response = await ApiService.put(
      '/scheduled-payments/$paymentId/pay?paymentDate=$dateStr',
      {},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledPayment.fromJson(data);
  }
}

