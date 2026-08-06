import 'package:flutter_test/flutter_test.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/distance_calculator_service.dart';

void main() {
  late DistanceCalculatorServiceImpl distanceService;

  setUp(() {
    distanceService = DistanceCalculatorServiceImpl();
  });

  group('DistanceCalculatorService', () {
    test('calculateHaversineDistance calculates exact distance between two known points', () {
      // Monas Jakarta (-6.175392, 106.827153) to Bundaran HI (-6.195000, 106.823000)
      // Distance is ~2.2 km (2200m)
      final distance = DistanceCalculatorServiceImpl.calculateHaversineDistance(
        -6.175392,
        106.827153,
        -6.195000,
        106.823000,
      );

      expect(distance, greaterThan(2100));
      expect(distance, lessThan(2300));
    });

    test('isWithinRadius returns true when user is within 50 meters of target', () {
      // Point A: -6.208800, 106.845600
      // Point B: ~20 meters away (-6.208900, 106.845600)
      final isInside = distanceService.isWithinRadius(
        currentLatitude: -6.208900,
        currentLongitude: 106.845600,
        targetLatitude: -6.208800,
        targetLongitude: 106.845600,
        maxRadiusMeters: 50.0,
      );

      expect(isInside, isTrue);
    });

    test('isWithinRadius returns false when user is far outside 50 meters radius', () {
      // Point A: -6.208800, 106.845600
      // Point B: 500 meters away (-6.213000, 106.845600)
      final isInside = distanceService.isWithinRadius(
        currentLatitude: -6.213000,
        currentLongitude: 106.845600,
        targetLatitude: -6.208800,
        targetLongitude: 106.845600,
        maxRadiusMeters: 50.0,
      );

      expect(isInside, isFalse);
    });
  });
}
