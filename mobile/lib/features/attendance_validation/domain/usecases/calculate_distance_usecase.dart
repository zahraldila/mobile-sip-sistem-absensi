import '../../services/distance_calculator_service.dart';

class CalculateDistanceUseCase {
  final DistanceCalculatorService distanceCalculatorService;

  CalculateDistanceUseCase(this.distanceCalculatorService);

  double execute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return distanceCalculatorService.calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
