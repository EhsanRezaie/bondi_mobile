// lib/services/photo_service.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/models/photo.dart';

class PhotoService {
  static final Dio _dio = ApiService.dio;

  static Future<PhotoUploadResponse?> uploadPhoto(File file) async {
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
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return PhotoUploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Upload photo error: $e');
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
      final result = await uploadPhoto(file);
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
      await _dio.patch(
        '/users/me/photos/order',
        data: {'orders': orders},
      );
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