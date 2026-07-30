class DiscoverProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? bio;
  final int? height;
  final int? weight;
  final String? bodyType;
  final String? sexualOrientation;
  final String? relationshipStatus;
  final String? livingSituation;
  final String? childrenStatus;
  final String? smoking;
  final String? drinking;
  final String? education;
  final String? workplace;
  final String? religion;
  final String? ethnicity;
  final String? politicalOrientation;
  final List<String>? languages;
  final String? city;
  final String? province;
  final String? country;
  final double? distanceKm;
  final String? mainPhotoUrl;
  final List<String> photos;
  final List<String> interests;
  final List<Map<String, dynamic>> prompts;
  final bool isPremium;
  final bool isVerified;
  final String? lastSeenAt;
  final bool isOnline;
  final String? currentUserAction;

  DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.bio,
    this.height,
    this.weight,
    this.bodyType,
    this.sexualOrientation,
    this.relationshipStatus,
    this.livingSituation,
    this.childrenStatus,
    this.smoking,
    this.drinking,
    this.education,
    this.workplace,
    this.religion,
    this.ethnicity,
    this.politicalOrientation,
    this.languages,
    this.city,
    this.province,
    this.country,
    this.distanceKm,
    this.mainPhotoUrl,
    this.photos = const [],
    this.interests = const [],
    this.prompts = const [],
    this.isPremium = false,
    this.isVerified = false,
    this.lastSeenAt,
    this.isOnline = false,
    this.currentUserAction,
  });

  String get displayPhotoUrl {
    if (mainPhotoUrl == null || mainPhotoUrl!.isEmpty) return '';
    return mainPhotoUrl!;
  }

  String get locationDisplay {
    if (city != null && province != null) return '$city, $province';
    if (city != null) return city!;
    return '';
  }

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    return DiscoverProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      bio: json['bio'],
      height: json['height'],
      weight: json['weight'],
      bodyType: json['body_type'],
      sexualOrientation: json['sexual_orientation'],
      relationshipStatus: json['relationship_status'],
      livingSituation: json['living_situation'],
      childrenStatus: json['children_status'],
      smoking: json['smoking'],
      drinking: json['drinking'],
      education: json['education'],
      workplace: json['workplace'],
      religion: json['religion'],
      ethnicity: json['ethnicity'],
      politicalOrientation: json['political_orientation'],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      city: json['city'],
      province: json['province'],
      country: json['country'],
      distanceKm: json['distance_km']?.toDouble(),
      mainPhotoUrl: json['main_photo_url'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : [],
      prompts: json['prompts'] != null ? List<Map<String, dynamic>>.from(json['prompts']) : [],
      isPremium: json['is_premium'] ?? false,
      isVerified: json['is_verified'] ?? false,
      lastSeenAt: json['last_seen_at'],
      isOnline: json['is_online'] ?? false,
      currentUserAction: json['current_user_action'],
    );
  }
}
