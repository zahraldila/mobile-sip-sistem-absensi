import 'dart:math';
import 'package:geolocator/geolocator.dart';

abstract class DistanceCalculatorService {
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );

  bool isWithinRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double maxRadiusMeters,
  });
}

class DistanceCalculatorServiceImpl implements DistanceCalculatorService {
  @override
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      // Fallback to pure Haversine formula (Earth radius = 6371000m)
      return calculateHaversineDistance(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    }
  }

  @override
  bool isWithinRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double maxRadiusMeters,
  }) {
    final distance = calculateDistance(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= maxRadiusMeters;
  }

  /// Pure Dart Haversine formula for geodesic distance calculation (in meters)
  static double calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
