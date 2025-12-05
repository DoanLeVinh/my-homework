import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_city.dart';

class SavedCitiesService {
  static const String _key = 'saved_cities';

  // Get all saved cities
  Future<List<SavedCity>> getSavedCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? citiesJson = prefs.getString(_key);

      if (citiesJson == null) return [];

      final List<dynamic> decoded = json.decode(citiesJson);
      return decoded.map((item) => SavedCity.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save a city
  Future<bool> saveCity(SavedCity city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cities = await getSavedCities();

      // Check if city already exists (by lat/lon)
      if (cities.any((c) => c.lat == city.lat && c.lon == city.lon)) {
        return false; // Already saved
      }

      cities.add(city);
      final String encoded = json.encode(
        cities.map((c) => c.toJson()).toList(),
      );
      return await prefs.setString(_key, encoded);
    } catch (e) {
      return false;
    }
  }

  // Remove a city
  Future<bool> removeCity(SavedCity city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cities = await getSavedCities();

      cities.removeWhere((c) => c.lat == city.lat && c.lon == city.lon);

      final String encoded = json.encode(
        cities.map((c) => c.toJson()).toList(),
      );
      return await prefs.setString(_key, encoded);
    } catch (e) {
      return false;
    }
  }

  // Check if a city is saved
  Future<bool> isCitySaved(double lat, double lon) async {
    final cities = await getSavedCities();
    return cities.any((c) => c.lat == lat && c.lon == lon);
  }

  // Clear all saved cities
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      return false;
    }
  }
}
