class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String subscriptionTier;
  final int aiCreditBalance;
  final bool emailVerified;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.subscriptionTier,
    required this.aiCreditBalance,
    required this.emailVerified,
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
    };
  }
}
