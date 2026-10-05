class PostModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String contactWhatsapp;
  final Map<String, dynamic> structuredData;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final double? distanceKm;
  bool isSaved;
  final int viewsCount;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.contactWhatsapp,
    required this.structuredData,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    this.distanceKm,
    this.isSaved = false,
    this.viewsCount = 0,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) {
      final meters = (distanceKm! * 1000).round();
      return '$meters m away';
    }
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? json['category']?.toString() ?? '',
      categoryName: json['category_name'] ?? 'General',
      contactWhatsapp: json['contact_whatsapp'] ?? '',
      structuredData: json['structured_data'] is Map<String, dynamic>
          ? json['structured_data']
          : {},
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isSaved: json['is_saved'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      userName: json['user_name'] ?? 'User',
      userAvatar: json['user_avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
