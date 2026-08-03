// lib/services/location_service.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/models/location.dart';

class LocationService {
  // ============================================================================
  // Permission
  // ============================================================================

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ============================================================================
  // GPS Location
  // ============================================================================

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      debugPrint('❌ Location error: $e');
      return null;
    }
  }

  // ============================================================================
  // Reverse Geocode (GPS -> Location Text)
  // ============================================================================

  static Future<ReverseGeocodeResponse?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/locations/reverse-geocode',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
      );
      return ReverseGeocodeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Reverse geocoding error: $e');
      return null;
    }
  }

  // ============================================================================
  // Countries
  // ============================================================================

  static Future<List<CountryResponse>> getCountries() async {
    try {
      final response = await ApiService.dio.get('/locations/countries');
      return (response.data as List)
          .map((json) => CountryResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Get countries error: $e');
      return [];
    }
  }

  // ============================================================================
  // States/Provinces
  // ============================================================================

  static Future<List<ProvinceResponse>> getStates({
    required String countryIso2,
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/locations/states',
        queryParameters: {'country': countryIso2},
      );
      return (response.data as List)
          .map((json) => ProvinceResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Get states error: $e');
      return [];
    }
  }

  // ============================================================================
  // Cities (with optional state_code filter)
  // ============================================================================

  static Future<List<CityResponse>> getCities({
    required String countryIso2,
    String? stateCode,
    String? stateName,
  }) async {
    try {
      final queryParams = {
        'country': countryIso2,
      };
      
      if (stateCode != null) {
        queryParams['state_code'] = stateCode;
      } else if (stateName != null) {
        queryParams['state_name'] = stateName;
      }
      
      final response = await ApiService.dio.get(
        '/locations/cities',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((json) => CityResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Get cities error: $e');
      return [];
    }
  }

  // ============================================================================
  // Search Cities (autocomplete)
  // ============================================================================

  static Future<List<CityResponse>> searchCities({
    required String countryIso2,
    required String query,
    String? stateCode,
  }) async {
    try {
      final queryParams = {
        'country': countryIso2,
        'query': query,
      };
      
      if (stateCode != null) {
        queryParams['state_code'] = stateCode;
      }
      
      final response = await ApiService.dio.get(
        '/locations/cities/search',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((json) => CityResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Search cities error: $e');
      return [];
    }
  }

  // ============================================================================
  // City Centroid (for manual location)
  // ============================================================================

  static Future<CityResponse?> getCityCentroid({
    required String countryIso2,
    required String cityName,
    String? stateCode,
  }) async {
    try {
      final queryParams = {
        'country': countryIso2,
        'city': cityName,
      };
      
      if (stateCode != null) {
        queryParams['state_code'] = stateCode;
      }
      
      final response = await ApiService.dio.get(
        '/locations/city-centroid',
        queryParameters: queryParams,
      );
      return CityResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Get city centroid error: $e');
      return null;
    }
  }

  // ============================================================================
  // Clear Cache
  // ============================================================================

  static Future<void> clearCache() async {
    try {
      await ApiService.dio.post('/locations/clear-cache');
      debugPrint('✅ Location cache cleared');
    } catch (e) {
      debugPrint('❌ Clear cache error: $e');
    }
  }

  // ============================================================================
  // Update User Location (GPS) - POST /users/me/location
  // ============================================================================

  static Future<bool> updateLocationGPS({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/users/me/location',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
      );
      debugPrint('✅ GPS location updated: ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('❌ Update location GPS error: $e');
      return false;
    }
  }

  // ============================================================================
  // Update User Location Text - PATCH /users/me/location-text
  // ============================================================================

  static Future<bool> updateLocationText({
    required String country,
    required String province,
    required String city,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/users/me/location-text',
        data: {
          'country': country,
          'province': province,
          'city': city,
        },
      );
      debugPrint('✅ Location text updated: ${response.data}');
      return true;
    } catch (e) {
      debugPrint('❌ Update location text error: $e');
      return false;
    }
  }

  // ============================================================================
  // Update User Location (Manual) - DEPRECATED use updateLocationText instead
  // ============================================================================

  @Deprecated('Use updateLocationText instead')
  static Future<Map<String, dynamic>?> updateLocationManual({
    required String country,
    required String province,
    required String city,
    required String countryIso2,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/locations/me/location-manual',
        queryParameters: {
          'country': country,
          'province': province,
          'city': city,
          'country_iso2': countryIso2,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('❌ Update location manual error: $e');
      return null;
    }
  }

  // ============================================================================
  // Get Country ISO2 Code by Name
  // ============================================================================

  static Future<String?> getCountryIso2ByName(String countryName) async {
    final countries = await getCountries();
    for (var country in countries) {
      if (country.name == countryName) {
        return country.iso2;
      }
    }
    return null;
  }

  // ============================================================================
  // Get Country ISO2 Code from Full Country List (for dropdown)
  // ============================================================================

  static Future<Map<String, String>> getCountryMap() async {
    final countries = await getCountries();
    return {for (var c in countries) c.name: c.iso2};
  }
}