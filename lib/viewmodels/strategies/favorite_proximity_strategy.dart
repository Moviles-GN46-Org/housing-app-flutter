import 'package:geolocator/geolocator.dart';
import '../../models/property_model.dart';

class FavoriteProximityMatch {
  final Property property;
  final double distanceMeters;

  const FavoriteProximityMatch({
    required this.property,
    required this.distanceMeters,
  });
}

abstract class FavoriteProximityStrategy {
  FavoriteProximityMatch? findClosestFavorite({
    required Position userPosition,
    required List<Property> properties,
    required Set<String> favoritePropertyIds,
  });
}

class RadiusFavoriteProximityStrategy implements FavoriteProximityStrategy {
  final double radiusMeters;

  const RadiusFavoriteProximityStrategy({required this.radiusMeters});

  @override
  FavoriteProximityMatch? findClosestFavorite({
    required Position userPosition,
    required List<Property> properties,
    required Set<String> favoritePropertyIds,
  }) {
    FavoriteProximityMatch? closest;

    for (final property in properties) {
      if (!favoritePropertyIds.contains(property.id)) {
        continue;
      }
      if (property.latitude == 0.0 && property.longitude == 0.0) {
        continue;
      }

      final distanceMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        property.latitude,
        property.longitude,
      );

      if (closest == null || distanceMeters < closest.distanceMeters) {
        closest = FavoriteProximityMatch(
          property: property,
          distanceMeters: distanceMeters,
        );
      }
    }

    if (closest == null || closest.distanceMeters > radiusMeters) {
      return null;
    }
    return closest;
  }
}
