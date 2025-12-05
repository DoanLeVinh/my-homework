import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  static const String _permissionKey = 'location_permission';
  static const String _permissionAskedKey = 'location_permission_asked';
  static const String _lastLatKey = 'last_latitude';
  static const String _lastLonKey = 'last_longitude';
  static const String _lastLocationTimeKey = 'last_location_time';

  // Check if permission has been asked before
  static Future<bool> hasAskedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionAskedKey) ?? false;
  }

  // Get saved permission choice
  static Future<String?> getSavedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_permissionKey);
  }

  // Save last known location
  static Future<void> saveLastLocation(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLatKey, lat);
    await prefs.setDouble(_lastLonKey, lon);
    await prefs.setString(
      _lastLocationTimeKey,
      DateTime.now().toIso8601String(),
    );
  }

  // Get last known location
  static Future<Position?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastLatKey);
    final lon = prefs.getDouble(_lastLonKey);
    final timeStr = prefs.getString(_lastLocationTimeKey);

    if (lat != null && lon != null && timeStr != null) {
      final time = DateTime.parse(timeStr);

      // Only use cached location if less than 1 hour old
      if (DateTime.now().difference(time).inHours < 1) {
        return Position(
          latitude: lat,
          longitude: lon,
          timestamp: time,
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }

    return null;
  }

  // Get current location with permission check
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return await getLastKnownLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return await getLastKnownLocation();
      }

      // Try to get current position with timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        // Save this location for future use
        await saveLastLocation(position.latitude, position.longitude);

        return position;
      } catch (e) {
        debugPrint('Error getting current location: $e');
        // Try last known position from Geolocator
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          await saveLastLocation(lastPosition.latitude, lastPosition.longitude);
          return lastPosition;
        }

        // Fallback to our cached location
        return await getLastKnownLocation();
      }
    } catch (e) {
      debugPrint('Location service error: $e');
      return await getLastKnownLocation();
    }
  }

  // Clear all location data
  static Future<void> clearLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionKey);
    await prefs.remove(_permissionAskedKey);
    await prefs.remove(_lastLatKey);
    await prefs.remove(_lastLonKey);
    await prefs.remove(_lastLocationTimeKey);
  }

  // Reset permission (for testing)
  static Future<void> resetPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionKey);
    await prefs.setBool(_permissionAskedKey, false);
  }
}
