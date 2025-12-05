class WeatherModel {
  final String cityName;
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final int clouds;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;
  final int dt;
  final int sunrise;
  final int sunset;
  final double lat;
  final double lon;

  WeatherModel({
    required this.cityName,
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.clouds,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.dt,
    required this.sunrise,
    required this.sunset,
    required this.lat,
    required this.lon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      pressure: json['main']['pressure'] as int,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      windDeg: json['wind']['deg'] as int,
      clouds: json['clouds']['all'] as int,
      weatherMain: json['weather'][0]['main'] ?? '',
      weatherDescription: json['weather'][0]['description'] ?? '',
      weatherIcon: json['weather'][0]['icon'] ?? '',
      dt: json['dt'] as int,
      sunrise: json['sys']['sunrise'] as int,
      sunset: json['sys']['sunset'] as int,
      lat: (json['coord']['lat'] as num).toDouble(),
      lon: (json['coord']['lon'] as num).toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$weatherIcon@4x.png';

  // Get current time at this location
  DateTime get currentTime => DateTime.fromMillisecondsSinceEpoch(dt * 1000);

  // Check if it's night time at this location - DÙNG THỜI GIAN HIỆN TẠI
  bool get isNightTime {
    // Lấy timestamp hiện tại theo UTC (giây)
    final nowUtc = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    // So sánh với sunrise/sunset tại vị trí đó
    // sunrise và sunset đã là UTC timestamp từ API
    return nowUtc < sunrise || nowUtc > sunset;
  }
}
