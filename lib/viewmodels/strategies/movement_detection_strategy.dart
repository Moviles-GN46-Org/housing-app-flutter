import 'package:geolocator/geolocator.dart';

abstract class MovementDetectionStrategy {
  bool isMoving({
    required Position currentPosition,
    required Position? previousPosition,
  });
}

class SpeedAndDeltaMovementStrategy implements MovementDetectionStrategy {
  final double speedThresholdMps;

  const SpeedAndDeltaMovementStrategy({required this.speedThresholdMps});

  @override
  bool isMoving({
    required Position currentPosition,
    required Position? previousPosition,
  }) {
    if (currentPosition.speed >= speedThresholdMps) {
      return true;
    }

    if (previousPosition == null) {
      return false;
    }

    final previousTime = previousPosition.timestamp;
    final currentTime = currentPosition.timestamp;
    if (previousTime == null || currentTime == null) {
      return false;
    }

    final deltaSeconds = currentTime.difference(previousTime).inSeconds.abs();
    if (deltaSeconds <= 0) {
      return false;
    }

    final distanceMeters = Geolocator.distanceBetween(
      previousPosition.latitude,
      previousPosition.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );
    final estimatedSpeed = distanceMeters / deltaSeconds;
    return estimatedSpeed >= speedThresholdMps;
  }
}
