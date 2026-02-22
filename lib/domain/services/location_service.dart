import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationService {
  Future<LatLng?> getCurrentLocation();
  Stream<LatLng> locationStream();
}

class DemoLocationService implements LocationService {
  final _controller = StreamController<LatLng>.broadcast();
  LatLng _current = const LatLng(37.7749, -122.4194);

  DemoLocationService() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      _current = LatLng(_current.latitude + 0.0003, _current.longitude + 0.0002);
      _controller.add(_current);
    });
  }

  @override
  Future<LatLng?> getCurrentLocation() async => _current;

  @override
  Stream<LatLng> locationStream() => _controller.stream;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return DemoLocationService();
});
