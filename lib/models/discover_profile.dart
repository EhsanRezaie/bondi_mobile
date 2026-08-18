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
  final DateTime? createdAt;

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
    this.createdAt,
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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  DiscoverProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? bio,
    int? height,
    int? weight,
    String? bodyType,
    String? sexualOrientation,
    String? relationshipStatus,
    String? livingSituation,
    String? childrenStatus,
    String? smoking,
    String? drinking,
    String? education,
    String? workplace,
    String? religion,
    String? ethnicity,
    String? politicalOrientation,
    List<String>? languages,
    String? city,
    String? province,
    String? country,
    double? distanceKm,
    String? mainPhotoUrl,
    List<String>? photos,
    List<String>? interests,
    List<Map<String, dynamic>>? prompts,
    bool? isPremium,
    bool? isVerified,
    String? lastSeenAt,
    bool? isOnline,
    String? currentUserAction,
  }) {
    return DiscoverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyType: bodyType ?? this.bodyType,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      livingSituation: livingSituation ?? this.livingSituation,
      childrenStatus: childrenStatus ?? this.childrenStatus,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      education: education ?? this.education,
      workplace: workplace ?? this.workplace,
      religion: religion ?? this.religion,
      ethnicity: ethnicity ?? this.ethnicity,
      politicalOrientation: politicalOrientation ?? this.politicalOrientation,
      languages: languages ?? this.languages,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      distanceKm: distanceKm ?? this.distanceKm,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts,
      isPremium: isPremium ?? this.isPremium,
      isVerified: isVerified ?? this.isVerified,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      currentUserAction: currentUserAction ?? this.currentUserAction,
    );
  }
}
