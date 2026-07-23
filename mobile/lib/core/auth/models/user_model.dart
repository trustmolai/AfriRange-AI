class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String subscriptionTier;
  final int aiCreditBalance;
  final bool emailVerified;

  final String? firstName;
  final String? lastName;
  final String? occupation; // 'farmer', 'student', 'guest', 'manager', 'researcher'
  final String? country;
  final String? city;
  final String currency; // e.g. 'ZAR', 'KES', 'NGN', 'USD', 'BWP', 'NAD'
  final String currencySymbol; // e.g. 'R', 'KSh', '₦', '$', 'P', 'N$'
  final double? farmSizeHectares;
  final String? primaryLivestock;
  final String? primaryGoal;
  final bool hasCompletedOnboarding;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.subscriptionTier,
    required this.aiCreditBalance,
    required this.emailVerified,
    this.firstName,
    this.lastName,
    this.occupation,
    this.country,
    this.city,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.farmSizeHectares,
    this.primaryLivestock,
    this.primaryGoal,
    this.hasCompletedOnboarding = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      role: json['role'] as String? ?? 'farmer',
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
      aiCreditBalance: json['aiCreditBalance'] as int? ?? 5,
      emailVerified: json['emailVerified'] as bool? ?? false,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      occupation: json['occupation'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      farmSizeHectares: (json['farmSizeHectares'] as num?)?.toDouble(),
      primaryLivestock: json['primaryLivestock'] as String?,
      primaryGoal: json['primaryGoal'] as String?,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'subscriptionTier': subscriptionTier,
      'aiCreditBalance': aiCreditBalance,
      'emailVerified': emailVerified,
      'firstName': firstName,
      'lastName': lastName,
      'occupation': occupation,
      'country': country,
      'city': city,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'farmSizeHectares': farmSizeHectares,
      'primaryLivestock': primaryLivestock,
      'primaryGoal': primaryGoal,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? subscriptionTier,
    int? aiCreditBalance,
    bool? emailVerified,
    String? firstName,
    String? lastName,
    String? occupation,
    String? country,
    String? city,
    String? currency,
    String? currencySymbol,
    double? farmSizeHectares,
    String? primaryLivestock,
    String? primaryGoal,
    bool? hasCompletedOnboarding,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      aiCreditBalance: aiCreditBalance ?? this.aiCreditBalance,
      emailVerified: emailVerified ?? this.emailVerified,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      occupation: occupation ?? this.occupation,
      country: country ?? this.country,
      city: city ?? this.city,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      farmSizeHectares: farmSizeHectares ?? this.farmSizeHectares,
      primaryLivestock: primaryLivestock ?? this.primaryLivestock,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

