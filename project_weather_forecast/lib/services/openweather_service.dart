import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/city_suggestion.dart';

class OpenWeatherService {
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String _baseUrl = 'api.openweathermap.org';

  // Get current weather by city name
  Future<WeatherModel> getCurrentWeatherByCity(String cityName) async {
    final uri = Uri.https(_baseUrl, '/data/2.5/weather', {
      'q': cityName,
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'vi',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Không thể lấy dữ liệu thời tiết: ${response.statusCode}',
      );
    }
  }

  // Get current weather by coordinates
  Future<WeatherModel> getCurrentWeatherByCoords(double lat, double lon) async {
    final uri = Uri.https(_baseUrl, '/data/2.5/weather', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'vi',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Không thể lấy dữ liệu thời tiết: ${response.statusCode}',
      );
    }
  }

  // Get 5-day forecast by city name
  Future<ForecastModel> getForecastByCity(String cityName) async {
    final uri = Uri.https(_baseUrl, '/data/2.5/forecast', {
      'q': cityName,
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'vi',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ForecastModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Không thể lấy dữ liệu dự báo: ${response.statusCode}');
    }
  }

  // Get 5-day forecast by coordinates
  Future<ForecastModel> getForecastByCoords(double lat, double lon) async {
    final uri = Uri.https(_baseUrl, '/data/2.5/forecast', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'vi',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ForecastModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Không thể lấy dữ liệu dự báo: ${response.statusCode}');
    }
  }

  // Get city suggestions (using geocoding API)
  Future<List<CitySuggestion>> getCitySuggestions(String query) async {
    if (query.isEmpty || query.length < 2) return [];

    final uri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
      'q': query,
      'limit': '5',
      'appid': _apiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => CitySuggestion.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // Get tile layer URL for weather maps
  String getTileLayerUrl(String layerType) {
    // layerType: precipitation_new, clouds_new, temp_new, wind_new, pressure_new
    return 'https://tile.openweathermap.org/map/$layerType/{z}/{x}/{y}.png?appid=$_apiKey';
  }
}
