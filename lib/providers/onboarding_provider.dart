// lib/providers/onboarding_provider.dart
import 'package:flutter/material.dart';

class OnboardingProvider extends ChangeNotifier {
  bool _disposed = false;

  // Step 1: Email & Password (already passed from SignUp)
  String? _email;
  String? _password;

  // Step 2: Personal Info
  String? _name;
  String? _birthDate;
  String? _gender;
  String? _sexualOrientation;
  String? _bio;

  // Step 3: Physical & Lifestyle
  int? _height;
  int? _weight;
  String? _bodyType;
  String? _relationshipStatus;
  String? _livingSituation;
  String? _childrenStatus;
  String? _smoking;
  String? _drinking;
  String? _education;
  String? _workplace;
  String? _religion;
  String? _ethnicity;
  String? _politicalOrientation;

  // NEW: Languages (multi-select)
  List<String>? _languages;

  // Step 4: Location
  double? _lat;
  double? _lng;
  String? _country;
  String? _province;
  String? _city;

  // Step 5: Interests & Prompts
  List<String>? _interests;
  List<Map<String, dynamic>>? _prompts;

  // NEW: Photos (for PhotoUploadScreen)
  List<String>? _photos;

  // ============================================================
  // Getters
  // ============================================================
  String? get email => _email;
  String? get password => _password;
  String? get name => _name;
  String? get birthDate => _birthDate;
  String? get gender => _gender;
  String? get sexualOrientation => _sexualOrientation;
  String? get bio => _bio;
  int? get height => _height;
  int? get weight => _weight;
  String? get bodyType => _bodyType;
  String? get relationshipStatus => _relationshipStatus;
  String? get livingSituation => _livingSituation;
  String? get childrenStatus => _childrenStatus;
  String? get smoking => _smoking;
  String? get drinking => _drinking;
  String? get education => _education;
  String? get workplace => _workplace;
  String? get religion => _religion;
  String? get ethnicity => _ethnicity;
  String? get politicalOrientation => _politicalOrientation;
  List<String>? get languages => _languages;
  double? get lat => _lat;
  double? get lng => _lng;
  String? get country => _country;
  String? get province => _province;
  String? get city => _city;
  List<String>? get interests => _interests;
  List<Map<String, dynamic>>? get prompts => _prompts;
  List<String>? get photos => _photos;

  bool get hasEmail => _email != null && _email!.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

   void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================
  // Set from SignUp (called after successful verify)
  // ============================================================
  void setEmailAndPassword(String email, String password) {
    _email = email;
    _password = password;
    _safeNotify();
  }

  // ============================================================
  // Step 2: Personal Info
  // ============================================================
  void setPersonalInfo({
    required String name,
    required String birthDate,
    required String gender,
    String? sexualOrientation,
    String? bio,
  }) {
    _name = name;
    _birthDate = birthDate;
    _gender = gender;
    _sexualOrientation = sexualOrientation;
    _bio = bio;
    _safeNotify();
  }

  // ============================================================
  // Step 3: Physical & Lifestyle
  // ============================================================
  void setPhysicalAndLifestyle({
    int? height,
    int? weight,
    String? bodyType,
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
  }) {
    _height = height;
    _weight = weight;
    _bodyType = bodyType;
    _relationshipStatus = relationshipStatus;
    _livingSituation = livingSituation;
    _childrenStatus = childrenStatus;
    _smoking = smoking;
    _drinking = drinking;
    _education = education;
    _workplace = workplace;
    _religion = religion;
    _ethnicity = ethnicity;
    _politicalOrientation = politicalOrientation;
    _languages = languages;
    _safeNotify();
  }

  // ============================================================
  // Step 4: Location
  // ============================================================
  void setLocation({
    required double lat,
    required double lng,
    String? country,
    String? province,
    String? city,
  }) {
    _lat = lat;
    _lng = lng;
    _country = country;
    _province = province;
    _city = city;
    _safeNotify();
  }

  // ============================================================
  // Step 5: Interests & Prompts
  // ============================================================
  void setInterests(List<String> interests) {
    _interests = interests;
    _safeNotify();
  }

  void setPrompts(List<Map<String, dynamic>> prompts) {
    _prompts = prompts;
    _safeNotify();
  }

  void addInterest(String interest) {
    _interests ??= [];
    if (!_interests!.contains(interest)) {
      _interests!.add(interest);
      _safeNotify();
    }
  }

  void removeInterest(String interest) {
    if (_interests != null) {
      _interests!.remove(interest);
      _safeNotify();
    }
  }

  // ============================================================
  // NEW: Photos methods
  // ============================================================
  void setPhotos(List<String> photos) {
    _photos = photos;
    _safeNotify();
  }

  void addPhoto(String photoPath) {
    _photos ??= [];
    _photos!.add(photoPath);
    _safeNotify();
  }

  void removePhoto(String photoPath) {
    if (_photos != null) {
      _photos!.remove(photoPath);
      _safeNotify();
    }
  }

  // ============================================================
  // Build complete request for /auth/register/complete
  // ============================================================
  Map<String, dynamic> buildCompleteRequest() {
    return {
      'name': _name,
      'birth_date': _birthDate,
      'gender': _gender,
      if (_sexualOrientation != null && _sexualOrientation!.isNotEmpty)
        'sexual_orientation': _sexualOrientation,
      if (_bio != null && _bio!.isNotEmpty) 'bio': _bio,
      if (_height != null) 'height': _height,
      if (_weight != null) 'weight': _weight,
      if (_bodyType != null && _bodyType!.isNotEmpty) 'body_type': _bodyType,
      if (_relationshipStatus != null && _relationshipStatus!.isNotEmpty)
        'relationship_status': _relationshipStatus,
      if (_livingSituation != null && _livingSituation!.isNotEmpty)
        'living_situation': _livingSituation,
      if (_childrenStatus != null && _childrenStatus!.isNotEmpty)
        'children_status': _childrenStatus,
      if (_smoking != null && _smoking!.isNotEmpty) 'smoking': _smoking,
      if (_drinking != null && _drinking!.isNotEmpty) 'drinking': _drinking,
      if (_education != null && _education!.isNotEmpty) 'education': _education,
      if (_workplace != null && _workplace!.isNotEmpty) 'workplace': _workplace,
      if (_religion != null && _religion!.isNotEmpty) 'religion': _religion,
      if (_ethnicity != null && _ethnicity!.isNotEmpty) 'ethnicity': _ethnicity,
      if (_politicalOrientation != null && _politicalOrientation!.isNotEmpty)
        'political_orientation': _politicalOrientation,
      if (_languages != null && _languages!.isNotEmpty) 'languages': _languages,
      // Only include lat/lng if they exist, otherwise 0.0
      'lat': _lat ?? 0.0,
      'lng': _lng ?? 0.0,
      if (_country != null && _country!.isNotEmpty) 'country': _country,
      if (_province != null && _province!.isNotEmpty) 'province': _province,
      if (_city != null && _city!.isNotEmpty) 'city': _city,
      if (_interests != null && _interests!.isNotEmpty) 'interests': _interests,
      if (_prompts != null && _prompts!.isNotEmpty) 'prompts': _prompts,
    };
  }

  // ============================================================
  // Check if all required fields are filled
  // ============================================================
  bool get isComplete {
    final nameValid = _name != null && _name!.isNotEmpty;
    final birthDateValid = _birthDate != null && _birthDate!.isNotEmpty;
    final genderValid = _gender != null && _gender!.isNotEmpty;
    final latValid = _lat != null;
    final lngValid = _lng != null;

    return nameValid && birthDateValid && genderValid && latValid && lngValid;
  }

  // ============================================================
  // Reset all data
  // ============================================================
  void clear() {
    _email = null;
    _password = null;
    _name = null;
    _birthDate = null;
    _gender = null;
    _sexualOrientation = null;
    _bio = null;
    _height = null;
    _weight = null;
    _bodyType = null;
    _relationshipStatus = null;
    _livingSituation = null;
    _childrenStatus = null;
    _smoking = null;
    _drinking = null;
    _education = null;
    _workplace = null;
    _religion = null;
    _ethnicity = null;
    _politicalOrientation = null;
    _languages = null;
    _lat = null;
    _lng = null;
    _country = null;
    _province = null;
    _city = null;
    _interests = null;
    _prompts = null;
    _photos = null;
    _safeNotify();
  }
}