import '../models/weather_model.dart';
import '../database/app_database.dart';

class SmartNotificationEngine {
  // Analyze weather và tạo message thông minh
  static String generateWeatherMessage(WeatherModel weather, {Event? event}) {
    final StringBuffer message = StringBuffer();

    // Header
    if (event != null) {
      message.writeln('📅 Sự kiện: ${event.title}');
      message.writeln('');
    }

    // Temperature
    final temp = weather.temp.round();
    message.writeln('🌡️ Nhiệt độ: $temp°C');

    // Weather condition
    final condition = _getWeatherConditionVietnamese(weather.weatherMain);
    message.writeln(condition);
    message.writeln('');

    // Analysis và suggestions
    final suggestions = _analyzeWeather(weather, event);

    if (suggestions['warnings']!.isNotEmpty) {
      message.writeln('⚠️ Cảnh báo:');
      for (var warning in suggestions['warnings']!) {
        message.writeln('• $warning');
      }
      message.writeln('');
    }

    if (suggestions['clothing']!.isNotEmpty) {
      message.writeln('👕 Gợi ý trang phục:');
      message.writeln(suggestions['clothing']!.join(', '));
      message.writeln('');
    }

    if (suggestions['accessories']!.isNotEmpty) {
      message.writeln('🎒 Đồ cần mang:');
      for (var item in suggestions['accessories']!) {
        message.writeln('• $item');
      }
      message.writeln('');
    }

    // Personalized advice
    if (suggestions['advice']!.isNotEmpty) {
      message.writeln('💬 Lời khuyên:');
      message.writeln(suggestions['advice']!.first);
    }

    return message.toString();
  }

  static Map<String, List<String>> _analyzeWeather(
    WeatherModel weather,
    Event? event,
  ) {
    final Map<String, List<String>> suggestions = {
      'warnings': [],
      'clothing': [],
      'accessories': [],
      'advice': [],
    };

    final temp = weather.temp;
    final condition = weather.weatherMain.toLowerCase();
    final isOutdoorEvent =
        event?.eventType == 'outdoor' ||
        event?.eventType == 'sport' ||
        event?.eventType == 'travel';

    // Temperature analysis
    if (temp > 32) {
      suggestions['warnings']!.add('Trời rất nóng! 🥵');
      suggestions['clothing']!.addAll(['Áo cotton mỏng', 'Quần short']);
      suggestions['accessories']!.addAll([
        '☂️ Ô che nắng',
        '🧴 Kem chống nắng SPF 50+',
        '🕶️ Kính râm',
        '🧢 Mũ/nón',
        '💧 Nước uống',
      ]);
      suggestions['advice']!.add(
        'Hôm nay trời nắng lắm đó nhớ bôi kem chống nắng và che chắn kĩ nha người đẹp! 🌞😎',
      );
    } else if (temp > 27) {
      suggestions['clothing']!.addAll(['Áo thun', 'Quần dài nhẹ']);
      suggestions['accessories']!.addAll(['☂️ Ô (nắng/mưa)', '💧 Nước uống']);
      suggestions['advice']!.add(
        'Thời tiết dễ chịu, nhưng vẫn nên mang theo nước nha! 😊',
      );
    } else if (temp > 20) {
      suggestions['clothing']!.addAll(['Áo dài tay', 'Quần dài']);
      suggestions['advice']!.add(
        'Thời tiết mát mẻ, rất phù hợp để đi chơi! 🌤️',
      );
    } else if (temp > 15) {
      suggestions['warnings']!.add('Trời khá lạnh! 🥶');
      suggestions['clothing']!.addAll(['Áo khoác', 'Quần dài']);
      suggestions['advice']!.add('Trời lạnh đấy, nhớ mặc ấm nha! 🧥');
    } else {
      suggestions['warnings']!.add('Trời rất lạnh! ❄️');
      suggestions['clothing']!.addAll(['Áo ấm/khoác dày', 'Quần dài ấm']);
      suggestions['accessories']!.add('🧣 Khăn quàng cổ');
      suggestions['advice']!.add('Trời lạnh lắm, nhớ giữ ấm cơ thể nha! 🥶🧥');
    }

    // Rain analysis
    if (condition.contains('rain') || condition.contains('drizzle')) {
      suggestions['warnings']!.add('Có mưa! ☔');
      suggestions['accessories']!.addAll(['☂️ Ô/áo mưa', '👟 Giày chống nước']);
      suggestions['advice']!.clear();
      suggestions['advice']!.add('Trời sắp mưa rồi, nhớ mang theo ô nhé! ☔');
    }

    // Thunderstorm
    if (condition.contains('thunder')) {
      suggestions['warnings']!.add('Có dông! ⛈️');
      if (isOutdoorEvent) {
        suggestions['advice']!.clear();
        suggestions['advice']!.add(
          'Có dông, nên hạn chế hoạt động ngoài trời nha! ⛈️',
        );
      }
    }

    // Wind analysis
    if (weather.windSpeed > 10) {
      suggestions['warnings']!.add('Gió mạnh! 🌬️');
      suggestions['advice']!.add('Gió mạnh đấy, cẩn thận khi ra ngoài nha!');
    }

    // UV analysis (giả sử UV cao khi nắng và nhiệt độ > 28)
    if (temp > 28 &&
        (condition.contains('clear') || condition.contains('sun'))) {
      suggestions['warnings']!.add('UV Index cao! ☀️');
      if (!suggestions['accessories']!.contains('🧴 Kem chống nắng SPF 50+')) {
        suggestions['accessories']!.add('🧴 Kem chống nắng SPF 50+');
      }
    }

    // Air quality warning (giả sử AQI xấu khi có mist/haze)
    if (condition.contains('mist') ||
        condition.contains('haze') ||
        condition.contains('smoke')) {
      suggestions['warnings']!.add('Chất lượng không khí kém! 😷');
      suggestions['accessories']!.add('😷 Khẩu trang');
      suggestions['advice']!.add(
        'Không khí không tốt, nên đeo khẩu trang khi ra ngoài nha! 😷',
      );
    }

    return suggestions;
  }

  static String _getWeatherConditionVietnamese(String condition) {
    final conditionLower = condition.toLowerCase();

    if (conditionLower.contains('clear')) return '☀️ Trời quang đãng';
    if (conditionLower.contains('cloud')) return '☁️ Nhiều mây';
    if (conditionLower.contains('rain')) return '🌧️ Có mưa';
    if (conditionLower.contains('drizzle')) return '🌦️ Mưa phùn';
    if (conditionLower.contains('thunder')) return '⛈️ Có dông';
    if (conditionLower.contains('snow')) return '❄️ Có tuyết';
    if (conditionLower.contains('mist') || conditionLower.contains('fog'))
      return '🌫️ Có sương mù';
    if (conditionLower.contains('haze')) return '😷 Có khói mù';

    return '🌤️ $condition';
  }

  // Generate notification title
  static String generateTitle(Event? event) {
    if (event != null) {
      return '📅 Nhắc nhở: ${event.title}';
    }
    return '🌞 Thời tiết hôm nay';
  }

  // Async wrapper for analyzeWeather (returns Map)
  Future<Map<String, dynamic>> analyzeWeather(WeatherModel weather) async {
    return {'temp': weather.temp, 'condition': weather.weatherMain};
  }

  // Generate smart message for event
  String generateSmartMessage(Map<String, dynamic> weatherInfo, Event event) {
    final StringBuffer message = StringBuffer();

    // Event info
    message.writeln('📅 ${event.title}');
    message.writeln('');

    // Weather info
    final temp = (weatherInfo['temp'] as double).round();
    message.writeln('🌡️ Nhiệt độ dự báo: $temp°C');
    message.writeln(weatherInfo['condition']);
    message.writeln('');

    // Smart suggestions based on weather and event type
    if (event.eventType == 'outdoor' || event.eventType == 'sport') {
      if (temp > 30) {
        message.writeln('☀️ Trời nắng nóng!');
        message.writeln('• Mang theo nước uống');
        message.writeln('• Bôi kem chống nắng');
        message.writeln('• Đội mũ/đeo kính');
      } else if (temp < 20) {
        message.writeln('🧥 Trời mát/lạnh!');
        message.writeln('• Mang theo áo khoác');
      }

      final condition = weatherInfo['condition'].toString().toLowerCase();
      if (condition.contains('rain')) {
        message.writeln('☔ Có mưa!');
        message.writeln('• Mang theo ô/áo mưa');
        message.writeln('• Cân nhắc hoãn nếu có thể');
      }
    }

    message.writeln('');
    message.writeln('Chúc bạn có khoảng thời gian vui vẻ! 😊');

    return message.toString();
  }
}
