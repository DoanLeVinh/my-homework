import 'package:flutter/material.dart';

class WeatherDebugMenu extends StatelessWidget {
  final Function(String) onWeatherChanged;
  final String currentWeather;

  const WeatherDebugMenu({
    super.key,
    required this.onWeatherChanged,
    required this.currentWeather,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.yellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'Weather Debug Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Current: $currentWeather',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
            ),
            SizedBox(height: 12),
            _buildWeatherButton('☀️ Sunny', 'Clear', Colors.yellow.shade700),
            SizedBox(height: 8),
            _buildWeatherButton('🌧️ Rainy', 'Rain', Colors.blue.shade700),
            SizedBox(height: 8),
            _buildWeatherButton(
              '⚡ Thunderstorm',
              'Thunderstorm',
              Colors.purple.shade900,
            ),
            SizedBox(height: 8),
            _buildWeatherButton('❄️ Snowy', 'Snow', Colors.lightBlue.shade200),
            SizedBox(height: 8),
            _buildWeatherButton('☁️ Cloudy', 'Clouds', Colors.grey.shade600),
            SizedBox(height: 8),
            _buildWeatherButton('🌫️ Foggy', 'Mist', Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherButton(String label, String weatherType, Color color) {
    final isActive = currentWeather == weatherType;

    return InkWell(
      onTap: () => onWeatherChanged(weatherType),
      child: Container(
        width: 180,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isActive)
              Icon(Icons.check_circle, color: Colors.white, size: 16),
            if (isActive) SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
