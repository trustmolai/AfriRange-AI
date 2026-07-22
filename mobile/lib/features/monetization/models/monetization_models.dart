class SubscriptionPlanModel {
  final String id;
  final String planName;
  final String displayName;
  final double monthlyPrice;
  final String currency;
  final int aiCreditsIncluded;
  final Map<String, dynamic> features;
  final String googlePlayProductId;

  SubscriptionPlanModel({
    required this.id,
    required this.planName,
    required this.displayName,
    required this.monthlyPrice,
    required this.currency,
    required this.aiCreditsIncluded,
    required this.features,
    required this.googlePlayProductId,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      planName: json['planName'] as String,
      displayName: json['displayName'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      aiCreditsIncluded: json['aiCreditsIncluded'] as int? ?? 10,
      features: json['features'] as Map<String, dynamic>? ?? {},
      googlePlayProductId: json['googlePlayProductId'] as String? ?? '',
    );
  }
}

class UserSubscriptionModel {
  final String id;
  final String userId;
  final String planName;
  final String displayName;
  final double monthlyPrice;
  final int aiCreditsIncluded;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final int aiCreditBalance;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.displayName,
    required this.monthlyPrice,
    required this.aiCreditsIncluded,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.autoRenew,
    required this.aiCreditBalance,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planName: json['planName'] as String,
      displayName: json['displayName'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      aiCreditsIncluded: json['aiCreditsIncluded'] as int? ?? 10,
      status: json['status'] as String? ?? 'active',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      autoRenew: json['autoRenew'] as bool? ?? true,
      aiCreditBalance: json['aiCreditBalance'] as int? ?? 0,
    );
  }
}

class AiCreditTransactionModel {
  final String id;
  final String transactionType;
  final int creditsAdded;
  final int creditsUsed;
  final int balanceAfter;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  AiCreditTransactionModel({
    required this.id,
    required this.transactionType,
    required this.creditsAdded,
    required this.creditsUsed,
    required this.balanceAfter,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory AiCreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return AiCreditTransactionModel(
      id: json['id'] as String,
      transactionType: json['transactionType'] as String,
      creditsAdded: json['creditsAdded'] as int? ?? 0,
      creditsUsed: json['creditsUsed'] as int? ?? 0,
      balanceAfter: json['balanceAfter'] as int,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PaymentRecordModel {
  final String id;
  final String paymentProvider;
  final double amount;
  final String currency;
  final String status;
  final String transactionReference;
  final DateTime createdAt;

  PaymentRecordModel({
    required this.id,
    required this.paymentProvider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as String,
      paymentProvider: json['paymentProvider'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String,
      transactionReference: json['transactionReference'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
