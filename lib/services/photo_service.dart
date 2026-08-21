// lib/services/photo_service.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/models/photo.dart';

class PhotoService {
  static final Dio _dio = ApiService.dio;

  /// Upload a profile photo.
  /// Returns (response, errorMessage) — errorMessage surfaces backend
  /// rejection reasons (e.g. "Photo rejected: No face detected in the photo").
  static Future<(PhotoUploadResponse?, String?)> uploadPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/users/me/photos',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return (PhotoUploadResponse.fromJson(response.data), null);
    } on DioException catch (e) {
      debugPrint('❌ Upload photo error: $e');
      final detail = _extractDetail(e);
      return (null, detail);
    } catch (e) {
      debugPrint('❌ Upload photo error: $e');
      return (null, 'Failed to upload photo');
    }
  }

  /// Verify identity with a clear frontal selfie.
  /// Returns (verified, message, similarity, mismatchedPhotoIds) — message
  /// surfaces backend rejection reasons (no face, mismatch, lighting, etc.)
  /// and mismatchedPhotoIds lists which of the user's photos didn't match.
  static Future<
    ({
      bool verified,
      String message,
      double? similarity,
      List<String> mismatchedPhotoIds,
    })
  >
  verifyWithSelfie(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/users/me/verify',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final data = response.data as Map<String, dynamic>;
      final mismatched = <String>[];
      if (data['mismatched_photo_ids'] is List) {
        for (final id in data['mismatched_photo_ids'] as List) {
          mismatched.add(id.toString());
        }
      }
      return (
        verified: (data['verified'] ?? false) as bool,
        message:
            (data['message'] ?? 'Profile verified successfully!') as String,
        similarity: (data['similarity_score'] as num?)?.toDouble(),
        mismatchedPhotoIds: mismatched,
      );
    } on DioException catch (e) {
      debugPrint('❌ Verify selfie error: $e');
      return (
        verified: false,
        message: _extractDetail(e),
        similarity: null,
        mismatchedPhotoIds: const <String>[],
      );
    } catch (e) {
      debugPrint('❌ Verify selfie error: $e');
      return (
        verified: false,
        message: 'Verification failed',
        similarity: null,
        mismatchedPhotoIds: const <String>[],
      );
    }
  }

  static String _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return 'Something went wrong';
  }

  /// Check verification status and eligibility (cooldown, already verified).
  static Future<VerificationStatus?> getVerificationStatus() async {
    try {
      final response = await _dio.get('/users/me/verify/status');
      return VerificationStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Get verification status error: $e');
      return null;
    }
  }

  static Future<List<PhotoResponse>> getMyPhotos() async {
    try {
      final response = await _dio.get('/users/me/photos');
      return (response.data as List)
          .map((json) => PhotoResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Get photos error: $e');
      return [];
    }
  }

  static Future<bool> deletePhoto(String photoId) async {
    try {
      await _dio.delete('/users/me/photos/$photoId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete photo error: $e');
      return false;
    }
  }

  static Future<PhotoResponse?> setMainPhoto(String photoId) async {
    try {
      final response = await _dio.put('/users/me/photos/$photoId/main');
      return PhotoResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Set main photo error: $e');
      return null;
    }
  }

  static Future<PhotoResponse?> updateCrop({
    required String photoId,
    required CropData crop,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/me/photos/$photoId/crop',
        data: {'crop': crop.toJson()},
      );
      return PhotoResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Update crop error: $e');
      return null;
    }
  }

  static Future<List<PhotoUploadResponse>> uploadMultiplePhotos(
    List<File> files,
    Function(int, int) onProgress,
  ) async {
    final results = <PhotoUploadResponse>[];
    int uploaded = 0;

    for (final file in files) {
      final (result, _) = await uploadPhoto(file);
      if (result != null) {
        results.add(result);
      }
      uploaded++;
      onProgress(uploaded, files.length);
    }

    return results;
  }

  static Future<bool> reorderPhotos(Map<String, int> orders) async {
    try {
      await _dio.patch('/users/me/photos/order', data: {'orders': orders});
      return true;
    } catch (e) {
      debugPrint('❌ Reorder photos error: $e');
      return false;
    }
  }

  static String? validateImage(File file) {
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    final sizeInBytes = file.lengthSync();
    const maxSize = 5 * 1024 * 1024;
    if (sizeInBytes > maxSize) {
      return 'Image too large. Max 5MB';
    }

    final extension = file.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      return 'Invalid format. Allowed: JPG, PNG, WEBP';
    }

    if (sizeInBytes == 0) {
      return 'File is empty';
    }

    return null;
  }

  static Future<File> convertToJpeg(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg'].contains(extension)) {
      return file;
    }
    return file;
  }

  static String getPhotoUrl(String key) {
    return key;
  }
}
