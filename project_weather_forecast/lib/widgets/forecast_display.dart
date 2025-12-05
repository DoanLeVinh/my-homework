import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/forecast_model.dart';
import '../models/weather_model.dart';
import 'glass_card.dart';
import 'weather_detail_sheet.dart';

class ForecastDisplay extends StatelessWidget {
  final ForecastModel forecast;
  final WeatherModel? currentWeather;

  const ForecastDisplay({Key? key, required this.forecast, this.currentWeather})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group forecast by day (get one item per day at 12:00)
    final dailyForecasts = <ForecastItem>[];
    final seenDates = <String>{};

    for (final item in forecast.items) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.fromMillisecondsSinceEpoch(item.dt * 1000));

      if (!seenDates.contains(date) && item.dtTxt.contains('12:00:00')) {
        dailyForecasts.add(item);
        seenDates.add(date);
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // Open detail sheet for today when tapping the header
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WeatherDetailSheet(
                  forecast: forecast,
                  currentWeather: currentWeather,
                  selectedDate: DateTime.now(),
                ),
              );
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Dự báo 5 ngày',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...dailyForecasts.map((item) => _buildForecastItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildForecastItem(BuildContext context, ForecastItem item) {
    final dateFormat = DateFormat('EEE, dd/MM', 'vi_VN');
    final date = DateTime.fromMillisecondsSinceEpoch(item.dt * 1000);

    return GestureDetector(
      onTap: () {
        // Open detail sheet for selected date
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WeatherDetailSheet(
            forecast: forecast,
            currentWeather: currentWeather,
            selectedDate: date,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Date
            SizedBox(
              width: 80,
              child: Text(
                dateFormat.format(date),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),

            // Weather icon
            CachedNetworkImage(
              imageUrl: item.iconUrl,
              width: 40,
              height: 40,
              placeholder: (context, url) => SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error, size: 40),
            ),
            const SizedBox(width: 12),

            // Description
            Expanded(
              child: Text(
                item.weatherDescription,
                style: TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),

            // Min/Max temperature
            Row(
              children: [
                Text(
                  '${item.tempMin.round()}°',
                  style: TextStyle(color: Colors.blue[200], fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.tempMax.round()}°',
                  style: TextStyle(
                    color: Colors.red[200],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
