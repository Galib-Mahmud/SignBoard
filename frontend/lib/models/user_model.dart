class UserModel {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String subscriptionTier;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.phoneNumber,
    this.whatsappNumber,
    required this.subscriptionTier,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      subscriptionTier: json['subscription_tier'] ?? 'free',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'subscription_tier': subscriptionTier,
    };
  }
}
