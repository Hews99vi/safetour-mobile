import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class LocationService {
  Future<bool> requestPermission() async {
    final status = await permissions.Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Stream<Position> watchPosition() async* {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      yield* Geolocator.getPositionStream(
        locationSettings: settings,
      ).handleError((Object error, StackTrace stackTrace) {
        debugPrint('Location stream unavailable: $error');
      });
    } on LocationServiceDisabledException catch (error) {
      debugPrint('Location services are disabled: $error');
    } on PermissionDeniedException catch (error) {
      debugPrint('Location permission denied: $error');
    } catch (error) {
      debugPrint('Location stream failed: $error');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied.');
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } on LocationServiceDisabledException catch (error) {
      debugPrint('Location services are disabled: $error');
      return null;
    } on PermissionDeniedException catch (error) {
      debugPrint('Location permission denied: $error');
      return null;
    } catch (error) {
      debugPrint('Current location unavailable: $error');
      return null;
    }
  }
}
