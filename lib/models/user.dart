// lib/models/user.dart
class UserSettings {
  final bool hideLastSeen;
  final bool hideOnlineStatus;
  final bool pushEnabled;
  final bool likeNotifications;
  final bool matchNotifications;
  final bool messageNotifications;
  final String language;
  final bool darkMode;

  const UserSettings({
    this.hideLastSeen = false,
    this.hideOnlineStatus = false,
    this.pushEnabled = true,
    this.likeNotifications = true,
    this.matchNotifications = true,
    this.messageNotifications = true,
    this.language = 'fa',
    this.darkMode = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      hideLastSeen: json['hide_last_seen'] ?? false,
      hideOnlineStatus: json['hide_online_status'] ?? false,
      pushEnabled: json['push_enabled'] ?? true,
      likeNotifications: json['like_notifications'] ?? true,
      matchNotifications: json['match_notifications'] ?? true,
      messageNotifications: json['message_notifications'] ?? true,
      language: json['language'] ?? 'fa',
      darkMode: json['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hide_last_seen': hideLastSeen,
      'hide_online_status': hideOnlineStatus,
      'push_enabled': pushEnabled,
      'like_notifications': likeNotifications,
      'match_notifications': matchNotifications,
      'message_notifications': messageNotifications,
      'language': language,
      'dark_mode': darkMode,
    };
  }
}

class User {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final String? birthDate;
  final String? gender;
  final String? sexualOrientation;
  final String? bio;
  final int? height;
  final int? weight;
  final String? bodyType;
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
  final String? country;
  final String? province;
  final String? city;
  final double? lat;
  final double? lng;
  final bool locationManual;
  final bool isPremium;
  final DateTime? premiumUntil;
  final bool isVerified;
  final bool isActive;
  final bool isProfileComplete;
  final int profileCompletion;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final bool hideLastSeen;
  final bool hideOnlineStatus;
  final List<String>? interests;
  final List<Map<String, dynamic>>? prompts;
  final UserSettings? settings;

  User({
    required this.id,
    required this.email,
    this.name,
    this.age,
    this.birthDate,
    this.gender,
    this.sexualOrientation,
    this.bio,
    this.height,
    this.weight,
    this.bodyType,
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
    this.country,
    this.province,
    this.city,
    this.lat,
    this.lng,
    this.locationManual = false,
    this.isPremium = false,
    this.premiumUntil,
    this.isVerified = false,
    this.isActive = true,
    this.isProfileComplete = false,
    this.profileCompletion = 0,
    required this.createdAt,
    this.lastSeenAt,
    this.hideLastSeen = false,
    this.hideOnlineStatus = false,
    this.interests,
    this.prompts,
    this.settings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? parsedPrompts;
    if (json['prompts'] != null) {
      parsedPrompts = List<Map<String, dynamic>>.from(json['prompts']);
    }

    UserSettings? parsedSettings;
    if (json['settings'] != null) {
      parsedSettings = UserSettings.fromJson(json['settings']);
    }

    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      age: json['age'],
      birthDate: json['birth_date'],
      gender: json['gender'],
      sexualOrientation: json['sexual_orientation'],
      bio: json['bio'],
      height: json['height'],
      weight: json['weight'],
      bodyType: json['body_type'],
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
      country: json['country'],
      province: json['province'],
      city: json['city'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      locationManual: json['location_manual'] ?? false,
      isPremium: json['is_premium'] ?? false,
      premiumUntil: json['premium_until'] != null 
          ? DateTime.parse(json['premium_until']) 
          : null,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      isProfileComplete: json['is_profile_complete'] ?? false,
      profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at']) 
          : null,
      hideLastSeen: json['hide_last_seen'] ?? parsedSettings?.hideLastSeen ?? false,
      hideOnlineStatus: json['hide_online_status'] ?? parsedSettings?.hideOnlineStatus ?? false,
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      prompts: parsedPrompts,
      settings: parsedSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'birth_date': birthDate,
      'gender': gender,
      'sexual_orientation': sexualOrientation,
      'bio': bio,
      'height': height,
      'weight': weight,
      'body_type': bodyType,
      'relationship_status': relationshipStatus,
      'living_situation': livingSituation,
      'children_status': childrenStatus,
      'smoking': smoking,
      'drinking': drinking,
      'education': education,
      'workplace': workplace,
      'religion': religion,
      'ethnicity': ethnicity,
      'political_orientation': politicalOrientation,
      'languages': languages,
      'country': country,
      'province': province,
      'city': city,
      'lat': lat,
      'lng': lng,
      'location_manual': locationManual,
      'is_premium': isPremium,
      'premium_until': premiumUntil?.toIso8601String(),
      'is_verified': isVerified,
      'is_active': isActive,
      'is_profile_complete': isProfileComplete,
      'profile_completion': profileCompletion,
      'created_at': createdAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'hide_last_seen': hideLastSeen,
      'hide_online_status': hideOnlineStatus,
      'interests': interests,
      'prompts': prompts,
    };
  }

  int? getAgeFromBirthDate() {
    if (birthDate == null) return age;
    try {
      final birth = DateTime.parse(birthDate!);
      final now = DateTime.now();
      int calculatedAge = now.year - birth.year;
      if (now.month < birth.month || 
          (now.month == birth.month && now.day < birth.day)) {
        calculatedAge--;
      }
      return calculatedAge;
    } catch (_) {
      return age;
    }
  }
}