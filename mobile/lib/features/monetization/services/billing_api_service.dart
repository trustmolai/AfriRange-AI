import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monetization_models.dart';
import '../../../config/env.dart';

class BillingApiService {
  final String baseUrl = Env.apiUrl;
  final String authToken;

  BillingApiService({required this.authToken});

  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  /// GET available subscription plans
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/subscriptions/plans'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['plans'] as List)
          .map((item) => SubscriptionPlanModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load subscription plans: ${response.statusCode}');
    }
  }

  /// GET user's active subscription details
  Future<UserSubscriptionModel> getCurrentSubscription() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/subscriptions/current'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserSubscriptionModel.fromJson(data['subscription']);
    } else {
      throw Exception('Failed to load active subscription: ${response.statusCode}');
    }
  }

  /// Verify Google Play Purchase Token with Backend
  Future<Map<String, dynamic>> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    bool isCreditPack = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/subscriptions/verify-google-play'),
      headers: _getHeaders(),
      body: json.encode({
        'productId': productId,
        'purchaseToken': purchaseToken,
        'isCreditPack': isCreditPack,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to verify purchase.');
    }
  }

  /// GET AI Credit Balance
  Future<int> getCreditBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/credits/balance'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['balance'] as int;
    } else {
      throw Exception('Failed to load credit balance.');
    }
  }

  /// GET AI Credit Ledger History
  Future<List<AiCreditTransactionModel>> getCreditHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/credits/history'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['history'] as List)
          .map((item) => AiCreditTransactionModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load credit history.');
    }
  }

  /// Consume Credits server-side after AI response
  Future<int> consumeCredits({int amount = 1, String featureTag = 'AI Action'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/credits/consume'),
      headers: _getHeaders(),
      body: json.encode({
        'amount': amount,
        'featureTag': featureTag,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['remaining'] as int;
    } else if (response.statusCode == 402) {
      throw Exception('INSUFFICIENT_CREDITS');
    } else {
      throw Exception('Failed to deduct credits.');
    }
  }

  /// Cancel Auto-Renew
  Future<void> cancelSubscription() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/subscriptions/cancel'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription auto-renewal.');
    }
  }

  /// GET Payment History
  Future<List<PaymentRecordModel>> getPaymentHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/subscriptions/history'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['history'] as List)
          .map((item) => PaymentRecordModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load payment history.');
    }
  }
}
