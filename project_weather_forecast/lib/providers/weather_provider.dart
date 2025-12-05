import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/city_suggestion.dart';
import '../models/saved_city.dart';
import '../services/openweather_service.dart';
import '../services/speech_service.dart';
import 'package:geolocator/geolocator.dart';
import 'database_provider.dart';

class WeatherProvider with ChangeNotifier {
  final OpenWeatherService _weatherService = OpenWeatherService();
  final SpeechService _speechService = SpeechService();
  final DatabaseProvider? _databaseProvider;

  WeatherProvider([this._databaseProvider]);

  WeatherModel? _currentWeather;
  ForecastModel? _forecast;
  List<CitySuggestion> _citySuggestions = [];
  List<SavedCity> _savedCities = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isListening = false;
  bool _isCurrentCitySaved = false;
  String? _error;
  String _searchQuery = '';

  // Cache cho getWeatherForDate để tránh rebuild không cần thiết
  final Map<String, WeatherModel?> _dateWeatherCache = {};
  DateTime? _lastFetchTime;

  // Cache timeout: 10 phút
  static const _cacheTimeout = Duration(minutes: 10);

  WeatherModel? get currentWeather => _currentWeather;
  ForecastModel? get forecast => _forecast;
  List<CitySuggestion> get citySuggestions => _citySuggestions;
  List<SavedCity> get savedCities => _savedCities;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isListening => _isListening;
  bool get isCurrentCitySaved => _isCurrentCitySaved;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Initialize with current location
  Future<void> initializeWithLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permission denied forever, using default location',
        );
        // Fallback to Ho Chi Minh City
        await fetchWeatherByCoords(10.8231, 106.6297);
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied, using default location');
        // Fallback to Ho Chi Minh City
        await fetchWeatherByCoords(10.8231, 106.6297);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position with timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        debugPrint('Got location: ${position.latitude}, ${position.longitude}');

        // Fetch weather data
        await fetchWeatherByCoords(position.latitude, position.longitude);
      } catch (locationError) {
        debugPrint('Error getting location: $locationError, using default');
        // Timeout hoặc lỗi GPS, fallback to Ho Chi Minh City
        await fetchWeatherByCoords(10.8231, 106.6297);
      }
    } catch (e) {
      debugPrint('Error in initializeWithLocation: $e');
      _error = e.toString();
      // Fallback to Ho Chi Minh City
      await fetchWeatherByCoords(10.8231, 106.6297);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch weather by city name
  Future<void> fetchWeatherByCity(String cityName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getCurrentWeatherByCity(cityName);
      _forecast = await _weatherService.getForecastByCity(cityName);
      await _checkIfCurrentCitySaved();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch weather by coordinates
  Future<void> fetchWeatherByCoords(double lat, double lon) async {
    // Kiểm tra cache trước khi fetch
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheTimeout &&
        _currentWeather != null &&
        (_currentWeather!.lat - lat).abs() < 0.01 &&
        (_currentWeather!.lon - lon).abs() < 0.01) {
      // Dùng cache nếu cùng vị trí và chưa hết hạn
      debugPrint('Using cached weather data');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getCurrentWeatherByCoords(
        lat,
        lon,
      );
      _forecast = await _weatherService.getForecastByCoords(lat, lon);
      _lastFetchTime = DateTime.now();
      _dateWeatherCache.clear(); // Clear cache khi có data mới
      await _checkIfCurrentCitySaved();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching weather: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search city suggestions
  Future<void> searchCities(String query) async {
    _searchQuery = query;
    notifyListeners();

    if (query.isEmpty || query.length < 2) {
      _citySuggestions = [];
      notifyListeners();
      return;
    }

    try {
      _citySuggestions = await _weatherService.getCitySuggestions(query);
    } catch (e) {
      _citySuggestions = [];
    }
    notifyListeners();
  }

  // Select city from suggestions
  Future<void> selectCity(CitySuggestion city) async {
    _searchQuery = city.displayName;
    _citySuggestions = [];
    _isSearching = false;
    notifyListeners();

    await fetchWeatherByCoords(city.lat, city.lon);
  }

  // Voice search
  Future<void> startVoiceSearch() async {
    _isListening = true;
    notifyListeners();

    try {
      final result = await _speechService.listen();
      if (result != null && result.isNotEmpty) {
        _searchQuery = result;
        await searchCities(result);
      }
    } catch (e) {
      _error = 'Lỗi nhận dạng giọng nói: $e';
    } finally {
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop voice search
  Future<void> stopVoiceSearch() async {
    await _speechService.stop();
    _isListening = false;
    notifyListeners();
  }

  // Toggle search mode
  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = '';
      _citySuggestions = [];
    }
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _citySuggestions = [];
    notifyListeners();
  }

  // Get tile layer URL
  String getTileLayerUrl(String layerType) {
    return _weatherService.getTileLayerUrl(layerType);
  }

  // Load saved cities from database
  Future<void> loadSavedCities() async {
    // Chỉ load nếu user đã đăng nhập
    if (_databaseProvider == null || _databaseProvider!.currentUser == null) {
      _savedCities = [];
      _isCurrentCitySaved = false;
      notifyListeners();
      return;
    }

    try {
      // Load từ DatabaseProvider (FavoriteCities)
      await _databaseProvider!.loadFavoriteCities();

      // Convert FavoriteCity → SavedCity
      _savedCities = _databaseProvider!.favoriteCities.map((fc) {
        return SavedCity(
          name: fc.cityName,
          displayName: fc.cityName,
          country: fc.countryCode,
          lat: fc.latitude,
          lon: fc.longitude,
          savedAt: fc.createdAt,
        );
      }).toList();

      await _checkIfCurrentCitySaved();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved cities: $e');
      _savedCities = [];
    }
  }

  // Save current city to database
  Future<bool> saveCurrentCity() async {
    if (_currentWeather == null) return false;
    if (_databaseProvider == null || _databaseProvider!.currentUser == null) {
      debugPrint('Cannot save city: User not logged in');
      return false;
    }

    try {
      final success = await _databaseProvider!.addFavoriteCity(
        cityName: _currentWeather!.cityName,
        countryCode: '', // Could be added to WeatherModel if needed
        latitude: _currentWeather!.lat,
        longitude: _currentWeather!.lon,
        isPrimary: false,
      );

      if (success) {
        await loadSavedCities();
      }
      return success;
    } catch (e) {
      debugPrint('Error saving city: $e');
      return false;
    }
  }

  // Remove saved city from database
  Future<bool> removeSavedCity(SavedCity city) async {
    if (_databaseProvider == null || _databaseProvider!.currentUser == null) {
      return false;
    }

    try {
      // Tìm FavoriteCity tương ứng
      final favoriteCity = _databaseProvider!.favoriteCities.firstWhere(
        (fc) =>
            (fc.latitude - city.lat).abs() < 0.01 &&
            (fc.longitude - city.lon).abs() < 0.01,
        orElse: () => throw Exception('City not found'),
      );

      await _databaseProvider!.removeFavoriteCity(favoriteCity.id);
      await loadSavedCities();
      return true;
    } catch (e) {
      debugPrint('Error removing city: $e');
      return false;
    }
  }

  // Check if current city is saved
  Future<void> _checkIfCurrentCitySaved() async {
    if (_currentWeather == null) {
      _isCurrentCitySaved = false;
      return;
    }

    if (_databaseProvider == null || _databaseProvider!.currentUser == null) {
      _isCurrentCitySaved = false;
      return;
    }

    _isCurrentCitySaved = _databaseProvider!.isCityFavorited(
      _currentWeather!.lat,
      _currentWeather!.lon,
    );
  }

  // Toggle save current city
  Future<void> toggleSaveCurrentCity() async {
    if (_isCurrentCitySaved) {
      // Remove
      final city = _savedCities.firstWhere(
        (c) => c.lat == _currentWeather!.lat && c.lon == _currentWeather!.lon,
      );
      await removeSavedCity(city);
    } else {
      // Save
      await saveCurrentCity();
    }
  }

  // Get weather for specific date (for calendar/event screens) - WITH CACHING
  Future<WeatherModel?> getWeatherForDate(DateTime date) async {
    if (_currentWeather == null) return null;

    // Tạo cache key
    final cacheKey = '${date.year}-${date.month}-${date.day}';

    // Kiểm tra cache
    if (_dateWeatherCache.containsKey(cacheKey)) {
      return _dateWeatherCache[cacheKey];
    }

    try {
      WeatherModel? result;

      // Nếu là ngày hôm nay, trả về current weather
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        result = _currentWeather;
      }
      // Nếu trong 5 ngày tới, lấy từ forecast
      else {
        final daysFromNow = date.difference(now).inDays;
        if (daysFromNow > 0 && daysFromNow <= 5 && _forecast != null) {
          // Tìm forecast gần nhất với ngày được chọn
          final targetDate = DateTime(date.year, date.month, date.day);

          for (var item in _forecast!.items) {
            final itemDate = DateTime.fromMillisecondsSinceEpoch(
              item.dt * 1000,
            );
            final itemDateOnly = DateTime(
              itemDate.year,
              itemDate.month,
              itemDate.day,
            );

            if (itemDateOnly.isAtSameMomentAs(targetDate)) {
              // Tạo WeatherModel từ forecast item
              result = WeatherModel(
                cityName: _currentWeather!.cityName,
                temp: item.temp,
                feelsLike: item.feelsLike,
                tempMin: item.tempMin,
                tempMax: item.tempMax,
                humidity: item.humidity,
                pressure: item.pressure,
                weatherMain: item.weatherMain,
                weatherDescription: item.weatherDescription,
                weatherIcon: item.weatherIcon,
                windSpeed: item.windSpeed,
                windDeg: item.windDeg,
                clouds: item.clouds,
                dt: item.dt,
                sunrise: _currentWeather!.sunrise,
                sunset: _currentWeather!.sunset,
                lat: _currentWeather!.lat,
                lon: _currentWeather!.lon,
              );
              break;
            }
          }
        }

        // Nếu là quá khứ hoặc quá xa, dùng current weather làm fallback
        result ??= _currentWeather;
      }

      // Lưu vào cache
      _dateWeatherCache[cacheKey] = result;
      return result;
    } catch (e) {
      debugPrint('Error getting weather for date: $e');
      return _currentWeather;
    }
  }
}
