import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class DatabaseProvider extends ChangeNotifier {
  final AppDatabase _database = AppDatabase();

  // Current user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Favorite cities
  List<FavoriteCity> _favoriteCities = [];
  List<FavoriteCity> get favoriteCities => _favoriteCities;

  // Search history
  List<SearchHistoryData> _searchHistory = [];
  List<SearchHistoryData> get searchHistory => _searchHistory;

  // User settings
  UserSetting? _userSettings;
  UserSetting? get userSettings => _userSettings;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppDatabase get database => _database;

  // Initialize database và load user data
  Future<void> initialize({String? userEmail}) async {
    try {
      if (userEmail != null) {
        // Load user từ database
        _currentUser = await _database.getUserByEmail(userEmail);

        // Nếu chưa có user, tạo user mới
        if (_currentUser == null) {
          await _database.insertUser(
            UsersCompanion.insert(
              email: userEmail,
              password: '', // Temporary empty password for non-auth users
              uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
              displayName: const Value(null),
              phoneNumber: const Value(null),
              photoUrl: const Value(null),
            ),
          );
          _currentUser = await _database.getUserByEmail(userEmail);

          // Tạo settings mặc định
          if (_currentUser != null) {
            await _database.createDefaultSettings(_currentUser!.id);
          }
        } else {
          // Update last login
          await _database.updateLastLogin(_currentUser!.id);
        }

        // Load user data
        if (_currentUser != null) {
          await loadUserData();
        }
      }

      _isInitialized = true;

      // Schedule notifyListeners after the current frame to avoid setState during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  // Load all user data
  Future<void> loadUserData() async {
    if (_currentUser == null) return;

    try {
      await Future.wait([
        loadFavoriteCities(),
        loadSearchHistory(),
        loadUserSettings(),
      ]);

      // Clean up expired cache
      await _database.deleteExpiredCache();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // ===== FAVORITE CITIES =====

  Future<void> loadFavoriteCities() async {
    if (_currentUser == null) return;
    _favoriteCities = await _database.getFavoriteCities(_currentUser!.id);
    notifyListeners();
  }

  Future<bool> addFavoriteCity({
    required String cityName,
    required String countryCode,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    if (_currentUser == null) return false;

    try {
      // Kiểm tra xem đã lưu chưa
      final exists = await _database.isCityFavorited(
        _currentUser!.id,
        latitude,
        longitude,
      );
      if (exists) {
        debugPrint('City already favorited');
        return false;
      }

      // Lấy số lượng cities hiện tại để tạo displayOrder
      final currentCount = _favoriteCities.length;

      await _database.addFavoriteCity(
        FavoriteCitiesCompanion.insert(
          userId: _currentUser!.id,
          cityName: cityName,
          countryCode: countryCode,
          latitude: latitude,
          longitude: longitude,
          displayOrder: Value(currentCount),
          isPrimary: Value(isPrimary),
        ),
      );

      await loadFavoriteCities();
      return true;
    } catch (e) {
      debugPrint('Error adding favorite city: $e');
      return false;
    }
  }

  Future<void> removeFavoriteCity(int cityId) async {
    try {
      await _database.deleteFavoriteCity(cityId);
      await loadFavoriteCities();
    } catch (e) {
      debugPrint('Error removing favorite city: $e');
    }
  }

  Future<void> setPrimaryCity(int cityId) async {
    if (_currentUser == null) return;

    try {
      final city = _favoriteCities.firstWhere((c) => c.id == cityId);
      await _database.updateFavoriteCity(
        FavoriteCitiesCompanion(
          id: Value(cityId),
          userId: Value(_currentUser!.id),
          cityName: Value(city.cityName),
          countryCode: Value(city.countryCode),
          latitude: Value(city.latitude),
          longitude: Value(city.longitude),
          displayOrder: Value(city.displayOrder),
          isPrimary: const Value(true),
        ),
      );

      await loadFavoriteCities();
    } catch (e) {
      debugPrint('Error setting primary city: $e');
    }
  }

  Future<void> updateCityLastViewed(int cityId) async {
    try {
      await _database.updateCityLastViewed(cityId);
    } catch (e) {
      debugPrint('Error updating city last viewed: $e');
    }
  }

  Future<void> reorderFavoriteCities(int oldIndex, int newIndex) async {
    try {
      // Update local list first
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final city = _favoriteCities.removeAt(oldIndex);
      _favoriteCities.insert(newIndex, city);

      // Update displayOrder in database
      for (int i = 0; i < _favoriteCities.length; i++) {
        await _database.updateCityOrder(_favoriteCities[i].id, i);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error reordering cities: $e');
    }
  }

  bool isCityFavorited(double lat, double lon) {
    return _favoriteCities.any(
      (city) =>
          (city.latitude - lat).abs() < 0.01 &&
          (city.longitude - lon).abs() < 0.01,
    );
  }

  // ===== SEARCH HISTORY =====

  Future<void> loadSearchHistory({int limit = 20}) async {
    if (_currentUser == null) return;
    _searchHistory = await _database.getRecentSearches(
      _currentUser!.id,
      limit: limit,
    );
    notifyListeners();
  }

  Future<void> addSearchHistory({
    required String searchQuery,
    String? cityName,
    String? countryCode,
    double? latitude,
    double? longitude,
  }) async {
    if (_currentUser == null) return;

    try {
      await _database.addSearchHistory(
        SearchHistoryCompanion.insert(
          userId: _currentUser!.id,
          searchQuery: searchQuery,
          cityName: Value(cityName),
          countryCode: Value(countryCode),
          latitude: Value(latitude),
          longitude: Value(longitude),
        ),
      );

      await loadSearchHistory();
    } catch (e) {
      debugPrint('Error adding search history: $e');
    }
  }

  Future<void> deleteSearchHistoryItem(int searchId) async {
    try {
      await _database.deleteSearchHistory(searchId);
      await loadSearchHistory();
    } catch (e) {
      debugPrint('Error deleting search history: $e');
    }
  }

  Future<void> clearSearchHistory() async {
    if (_currentUser == null) return;

    try {
      await _database.clearSearchHistory(_currentUser!.id);
      _searchHistory = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  // ===== USER SETTINGS =====

  Future<void> loadUserSettings() async {
    if (_currentUser == null) return;
    _userSettings = await _database.getUserSettings(_currentUser!.id);
    notifyListeners();
  }

  Future<void> updateTemperatureUnit(String unit) async {
    if (_currentUser == null || _userSettings == null) return;

    try {
      await _database.updateSetting(
        _currentUser!.id,
        UserSettingsCompanion(temperatureUnit: Value(unit)),
      );
      await loadUserSettings();
    } catch (e) {
      debugPrint('Error updating temperature unit: $e');
    }
  }

  Future<void> updateWindSpeedUnit(String unit) async {
    if (_currentUser == null || _userSettings == null) return;

    try {
      await _database.updateSetting(
        _currentUser!.id,
        UserSettingsCompanion(windSpeedUnit: Value(unit)),
      );
      await loadUserSettings();
    } catch (e) {
      debugPrint('Error updating wind speed unit: $e');
    }
  }

  Future<void> updateTheme(String theme) async {
    if (_currentUser == null || _userSettings == null) return;

    try {
      await _database.updateSetting(
        _currentUser!.id,
        UserSettingsCompanion(theme: Value(theme)),
      );
      await loadUserSettings();
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_currentUser == null || _userSettings == null) return;

    try {
      await _database.updateSetting(
        _currentUser!.id,
        UserSettingsCompanion(notificationsEnabled: Value(enabled)),
      );
      await loadUserSettings();
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
    }
  }

  Future<void> toggleWeatherAlerts(bool enabled) async {
    if (_currentUser == null || _userSettings == null) return;

    try {
      await _database.updateSetting(
        _currentUser!.id,
        UserSettingsCompanion(weatherAlertsEnabled: Value(enabled)),
      );
      await loadUserSettings();
    } catch (e) {
      debugPrint('Error toggling weather alerts: $e');
    }
  }

  // ===== WEATHER CACHE =====

  Future<Map<String, dynamic>?> getCachedWeather(String cityName) async {
    try {
      final cache = await _database.getCachedWeather(cityName);
      if (cache != null) {
        // Parse JSON từ cache
        return {
          'weather': cache.weatherData,
          'forecast': cache.forecastData,
          'cachedAt': cache.cachedAt,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached weather: $e');
      return null;
    }
  }

  Future<void> cacheWeather({
    required String cityName,
    required double latitude,
    required double longitude,
    required String weatherData,
    String? forecastData,
    int cacheMinutes = 10,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: cacheMinutes));

      await _database.cacheWeatherData(
        WeatherCacheCompanion.insert(
          cityName: cityName,
          latitude: latitude,
          longitude: longitude,
          weatherData: weatherData,
          forecastData: Value(forecastData),
          expiresAt: expiresAt,
        ),
      );
    } catch (e) {
      debugPrint('Error caching weather: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _database.clearAllCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}
