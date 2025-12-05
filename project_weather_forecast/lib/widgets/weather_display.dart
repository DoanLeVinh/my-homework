import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import 'glass_card.dart';

class WeatherDisplay extends StatelessWidget {
  final WeatherModel weather;

  const WeatherDisplay({Key? key, required this.weather}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM', 'vi_VN');
    final timeFormat = DateFormat('HH:mm', 'vi_VN');

    return Column(
      children: [
        // City name and date
        Text(
          weather.cityName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateFormat.format(
            DateTime.fromMillisecondsSinceEpoch(weather.dt * 1000),
          ),
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),

        // Weather icon and main info
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Weather icon
              CachedNetworkImage(
                imageUrl: weather.iconUrl,
                width: 120,
                height: 120,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    Icon(Icons.error, size: 120),
              ),
              const SizedBox(height: 16),

              // Temperature
              Text(
                '${weather.temp.round()}°C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Weather description
              Text(
                weather.weatherDescription,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Feels like
              Text(
                'Cảm giác như ${weather.feelsLike.round()}°C',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Min/Max temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_downward, color: Colors.blue[200], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.tempMin.round()}°',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.arrow_upward, color: Colors.red[200], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.tempMax.round()}°',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Weather details
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDetailRow(
                Icons.water_drop,
                'Độ ẩm',
                '${weather.humidity}%',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.air,
                'Tốc độ gió',
                '${weather.windSpeed.toStringAsFixed(1)} m/s',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.compress,
                'Áp suất',
                '${weather.pressure} hPa',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.cloud, 'Mây che phủ', '${weather.clouds}%'),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.wb_sunny,
                'Mặt trời mọc',
                timeFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(weather.sunrise * 1000),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.nightlight,
                'Mặt trời lặn',
                timeFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(weather.sunset * 1000),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
