// lib/models/photo.dart
import 'dart:io';

class PhotoUpload {
  final String id;
  final File file;
  bool isMain;
  bool isUploaded;
  String? url;
  String? serverId;
  String? rejectReason;
  bool needsSelfieMatch;

  bool get isRejected => rejectReason != null;

  PhotoUpload({
    required this.id,
    required this.file,
    this.isMain = false,
    this.isUploaded = false,
    this.url,
    this.serverId,
    this.rejectReason,
    this.needsSelfieMatch = false,
  });

  PhotoUpload copyWith({
    String? id,
    File? file,
    bool? isMain,
    bool? isUploaded,
    String? url,
    String? serverId,
    String? rejectReason,
    bool? needsSelfieMatch,
  }) {
    return PhotoUpload(
      id: id ?? this.id,
      file: file ?? this.file,
      isMain: isMain ?? this.isMain,
      isUploaded: isUploaded ?? this.isUploaded,
      url: url ?? this.url,
      serverId: serverId ?? this.serverId,
      rejectReason: rejectReason ?? this.rejectReason,
      needsSelfieMatch: needsSelfieMatch ?? this.needsSelfieMatch,
    );
  }
}

class CropData {
  final double x;
  final double y;
  final double size;

  CropData({this.x = 0.0, this.y = 0.0, this.size = 120.0});

  factory CropData.fromJson(Map<String, dynamic> json) {
    return CropData(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      size: (json['size'] ?? 120).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'size': size};
  }
}

class PhotoResponse {
  final String id;
  final String userId;
  final String url;
  final int order;
  bool isMain;
  final String status;
  final String? rejectReason;
  final bool faceVerified;
  final CropData? crop;

  PhotoResponse({
    required this.id,
    required this.userId,
    required this.url,
    required this.order,
    required this.isMain,
    required this.status,
    this.rejectReason,
    required this.faceVerified,
    this.crop,
  });

  String get displayUrl {
    if (Platform.isAndroid) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  // Calculate the offset for cropping
  double get cropOffsetX {
    if (crop == null) return 0.0;
    return crop!.x;
  }

  double get cropOffsetY {
    if (crop == null) return 0.0;
    return crop!.y;
  }

  // The size of the crop circle (120px for avatar)
  double get cropSize {
    if (crop == null) return 120.0;
    return crop!.size;
  }

  factory PhotoResponse.fromJson(Map<String, dynamic> json) {
    return PhotoResponse(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      url: json['url'] ?? '',
      order: json['order'] ?? 0,
      isMain: json['is_main'] ?? false,
      status: json['status'] ?? 'pending',
      rejectReason: json['reject_reason'],
      faceVerified: json['face_verified'] ?? false,
      crop: json['crop'] != null ? CropData.fromJson(json['crop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'url': url,
      'order': order,
      'is_main': isMain,
      'status': status,
      'reject_reason': rejectReason,
      'face_verified': faceVerified,
      if (crop != null) 'crop': crop!.toJson(),
    };
  }
}

class PhotoUploadResponse {
  final String id;
  final String url;
  final String status;
  final String message;

  PhotoUploadResponse({
    required this.id,
    required this.url,
    required this.status,
    required this.message,
  });

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResponse(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'] ?? 'Photo uploaded. Under review by admin.',
    );
  }
}

class VerificationStatus {
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool eligibleToVerify;
  final int? cooldownRemainingSeconds;

  VerificationStatus({
    required this.isVerified,
    this.verifiedAt,
    required this.eligibleToVerify,
    this.cooldownRemainingSeconds,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      isVerified: json['is_verified'] ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      eligibleToVerify: json['eligible_to_verify'] ?? false,
      cooldownRemainingSeconds: json['cooldown_remaining_seconds'] != null
          ? (json['cooldown_remaining_seconds'] as num).toInt()
          : null,
    );
  }
}
