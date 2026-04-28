import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/safe_zone.dart';
import 'safety_providers.dart';

const double _cacheDistanceMeters = 500;
const int _defaultRadiusMeters = 2000;

final _distance = Distance();
LatLng? _lastFetchPosition;
List<SafeZone>? _lastSafeZones;

final safeZonesProvider = FutureProvider.family<List<SafeZone>, LatLng>((
  ref,
  position,
) async {
  final cachedPosition = _lastFetchPosition;
  final cachedZones = _lastSafeZones;

  if (cachedPosition != null &&
      cachedZones != null &&
      _distance(position, cachedPosition) <= _cacheDistanceMeters) {
    return cachedZones;
  }

  final zones = await ref
      .watch(safetyApiProvider)
      .fetchNearbySafeZones(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: _defaultRadiusMeters,
      );

  _lastFetchPosition = position;
  _lastSafeZones = zones;

  return zones;
});
