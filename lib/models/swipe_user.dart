class SwipeUser {
  final String id;
  final String name;
  final int age;
  final String? mainPhotoUrl;
  final bool isPremium;
  final bool isVerified;
  final DateTime? swipedAt;
  final bool? isOnline;
  final String? lastSeenAt;
  final double? distanceKm;

  SwipeUser({
    required this.id,
    required this.name,
    required this.age,
    this.mainPhotoUrl,
    this.isPremium = false,
    this.isVerified = false,
    this.swipedAt,
    this.isOnline,
    this.lastSeenAt,
    this.distanceKm,
  });

  factory SwipeUser.fromJson(Map<String, dynamic> json) {
    return SwipeUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      mainPhotoUrl: json['main_photo_url'],
      isPremium: json['is_premium'] ?? false,
      isVerified: json['is_verified'] ?? false,
      swipedAt: json['swiped_at'] != null
          ? DateTime.tryParse(json['swiped_at'])
          : null,
      isOnline: json['is_online'],
      lastSeenAt: json['last_seen_at'],
      distanceKm: json['distance_km']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'main_photo_url': mainPhotoUrl,
      'is_premium': isPremium,
      'is_verified': isVerified,
      'swiped_at': swipedAt?.toIso8601String(),
      'is_online': isOnline,
      'last_seen_at': lastSeenAt,
      'distance_km': distanceKm,
    };
  }
}
