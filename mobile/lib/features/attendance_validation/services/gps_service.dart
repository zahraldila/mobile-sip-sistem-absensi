import 'dart:async';
import 'package:geolocator/geolocator.dart';

class DevicePosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;

  const DevicePosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude = 0.0,
    this.speed = 0.0,
    required this.timestamp,
  });

  factory DevicePosition.fromGeolocator(Position pos) {
    return DevicePosition(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed,
      timestamp: pos.timestamp,
    );
  }
}

abstract class GpsService {
  Future<bool> isLocationServiceEnabled();
  Future<DevicePosition> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  });
  Future<DevicePosition?> getLastKnownPosition();
  Future<bool> openLocationSettings();
}

class GpsServiceImpl implements GpsService {
  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<DevicePosition> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    final locationSettings = LocationSettings(
      accuracy: desiredAccuracy,
      timeLimit: timeLimit,
    );

    final position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    return DevicePosition.fromGeolocator(position);
  }

  @override
  Future<DevicePosition?> getLastKnownPosition() async {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    return DevicePosition.fromGeolocator(position);
  }

  @override
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
