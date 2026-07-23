import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Tier 1: Try high accuracy GPS (LocationAccuracy.best) with an 8-second timeout
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      // Tier 2: Try last known position
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
      } catch (_) {}

      // Tier 3: Try low accuracy GPS with 5-second timeout as quick fallback
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (err) {
        return Future.error('Failed to acquire location coordinates: $err');
      }
    }
  }

  /// Reverse-geocode using native free OS geocoding first, with OSM Nominatim fallback.
  Future<String> getAddressFromLatLng(Position position) async {
    // Tier 1: Free Native Geocoder (Android Play Services / iOS CoreLocation)
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        // We want exact details: street/thoroughfare, subLocality (neighborhood/society/colony), and city (locality)
        final street = place.street ?? place.thoroughfare;
        final neighborhood = place.subLocality ?? place.subAdministrativeArea;
        final city = place.locality;

        if (street != null && street.isNotEmpty && street != city) {
          parts.add(street);
        } else if (neighborhood != null && neighborhood.isNotEmpty && neighborhood != city) {
          parts.add(neighborhood);
        }

        if (city != null && city.isNotEmpty) {
          parts.add(city);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      // Native geocoder failed (no internet, missing services, emulator, or rate limit)
      // Fall through to OSM Nominatim
    }

    // Tier 2: Free OpenStreetMap Nominatim reverse geocoding
    return await _reverseGeocodeNominatim(position.latitude, position.longitude);
  }

  /// Reverse-geocode via Nominatim OpenStreetMap — works on ALL platforms (web + mobile).
  Future<String> _reverseGeocodeNominatim(double lat, double lon) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': 'en',
          'User-Agent': 'LocalSyncApp/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        
        final road = address['road'] as String?;
        final neighbourhood = address['neighbourhood'] as String?;
        final suburb = address['suburb'] as String?;
        final village = address['village'] as String? ?? address['town'] as String? ?? address['city'] as String?;
        
        final localParts = <String>[];
        if (road != null && road.isNotEmpty) {
          localParts.add(road);
        } else if (neighbourhood != null && neighbourhood.isNotEmpty) {
          localParts.add(neighbourhood);
        } else if (suburb != null && suburb.isNotEmpty) {
          localParts.add(suburb);
        }
        
        if (village != null && village.isNotEmpty) {
          localParts.add(village);
        }
        
        if (localParts.isNotEmpty) {
          return localParts.join(', ');
        }
        
        // Fallback to display_name first two parts
        final display = data['display_name'] as String? ?? '';
        if (display.isNotEmpty) {
          final split = display.split(',');
          if (split.length >= 2) {
            return '${split[0].trim()}, ${split[1].trim()}';
          }
          return split.first.trim();
        }
      }
    } catch (_) {}
    return '';
  }

  /// Detect approximate city from IP — used when GPS coords unavailable.
  Future<String> _cityFromIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final city = (data['city'] as String?) ??
            (data['region'] as String?) ??
            '';
        if (city.isNotEmpty) return city;
      }
    } catch (_) {}
    return 'Kuthambakkam, Chennai';
  }

  /// Checks whether an item's location falls within the user's neighborhood radius (default 5.0 KM).
  static bool isWithinNeighborhoodRadius({
    required double? itemLat,
    required double? itemLng,
    required String? itemLocationLabel,
    required Position? userPosition,
    required String? userCity,
    required double radiusKm,
    required String? currentUserId,
    required String? authorId,
  }) {
    // 1. Author's own posts are always visible to the author
    if (currentUserId != null && authorId != null && currentUserId == authorId) {
      return true;
    }

    // 2. If radiusKm is 0 or very large (e.g. >= 1000), show all items
    if (radiusKm <= 0 || radiusKm >= 1000) {
      return true;
    }

    // 3. Exact GPS Distance Calculation (Haversine formula via Geolocator)
    if (userPosition != null && itemLat != null && itemLng != null && itemLat != 0.0 && itemLng != 0.0) {
      final distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        itemLat,
        itemLng,
      );
      final distanceInKm = distanceInMeters / 1000.0;
      return distanceInKm <= radiusKm;
    }

    // 4. Locality / City Text Matching Fallback when GPS coordinates are partial
    if (itemLocationLabel != null && itemLocationLabel.trim().isNotEmpty &&
        userCity != null && userCity.trim().isNotEmpty) {
      final labelLower = itemLocationLabel.toLowerCase();
      final cityLower = userCity.toLowerCase();
      final cityTokens = cityLower.split(RegExp(r'[\s,]+')).where((t) => t.length > 2);
      for (final token in cityTokens) {
        if (labelLower.contains(token)) {
          return true;
        }
      }
      // If explicit location labels exist on both item & user but do not match -> Hide
      return false;
    }

    // If user position is available and item coords are available but outside radiusKm -> Hide
    if (userPosition != null && itemLat != null && itemLng != null && itemLat != 0.0 && itemLng != 0.0) {
      return false;
    }

    // 5. If item has NO valid location data (lat/lng null or 0, and locationLabel null/empty),
    // strictly HIDE IT from other users when neighborhood radius isolation is active!
    return false;
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

/// Neighborhood radius in kilometers — default strictly set to 5.0 KM
final neighborhoodRadiusKmProvider = StateProvider<double>((ref) => 5.0);

final userCoordinatesProvider = FutureProvider<Position?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  try {
    return await service.getCurrentLocation();
  } catch (_) {
    return null;
  }
});

final userLocationProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(locationServiceProvider);
  try {
    final position = await service.getCurrentLocation();
    final address = await service.getAddressFromLatLng(position);
    if (address.isNotEmpty) return address;
  } catch (_) {}

  // IP-based city fallback — always returns a valid city name
  return service._cityFromIp();
});

/// Exposes just the city/neighborhood name as a simple string (non-null, non-async).
final cityNameProvider = Provider<String>((ref) {
  final locationAsync = ref.watch(userLocationProvider);
  return locationAsync.when(
    data: (address) {
      if (address.isEmpty) return 'Your Locality';
      final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[0]}, ${parts[1]}';
      }
      return address;
    },
    loading: () => 'Locating...',
    error: (_, __) => 'Your Locality',
  );
});
