class ForecastModel {
  final String cityName;
  final List<ForecastItem> items;

  ForecastModel({required this.cityName, required this.items});

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List;
    return ForecastModel(
      cityName: json['city']['name'] ?? '',
      items: list.map((item) => ForecastItem.fromJson(item)).toList(),
    );
  }
}

class ForecastItem {
  final int dt;
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
  final String dtTxt;

  ForecastItem({
    required this.dt,
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
    required this.dtTxt,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      dt: json['dt'] as int,
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
      dtTxt: json['dt_txt'] ?? '',
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$weatherIcon@2x.png';
}
