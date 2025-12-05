import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/forecast_model.dart';
import '../models/weather_model.dart';

class WeatherDetailSheet extends StatelessWidget {
  final ForecastModel forecast;
  final WeatherModel? currentWeather;
  final DateTime? selectedDate;

  const WeatherDetailSheet({
    Key? key,
    required this.forecast,
    this.currentWeather,
    this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetDate = selectedDate ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

    print('=== WEATHER DETAIL SHEET DEBUG ===');
    print('Selected Date: $dateStr');
    print('Total forecast items: ${forecast.items.length}');

    // Get all forecast items for the selected date
    final dayForecasts = forecast.items.where((item) {
      final itemDate = DateTime.fromMillisecondsSinceEpoch(item.dt * 1000);
      final itemDateStr = DateFormat('yyyy-MM-dd').format(itemDate);
      final match = itemDateStr == dateStr;

      if (match) {
        print('Found match: ${item.dtTxt} - Temp: ${item.temp}°C');
      }

      return match;
    }).toList();

    print('Day forecasts found: ${dayForecasts.length}');

    // If no forecast for selected date and it's today, use current weather
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
    print('Is today: $isToday');
    print('Has current weather: ${currentWeather != null}');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              // Content
              ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                children: [
                  // Header
                  _buildHeader(targetDate, dayForecasts, isToday),
                  SizedBox(height: 24),

                  // Temperature & Weather Icon
                  _buildMainInfo(dayForecasts, isToday),
                  SizedBox(height: 32),

                  // Hourly Temperature Chart
                  _buildTemperatureChart(dayForecasts, isToday),
                  SizedBox(height: 32),

                  // Hourly Humidity Chart
                  _buildHumidityChart(dayForecasts, isToday),
                  SizedBox(height: 32),

                  // Detailed Info Cards
                  _buildDetailCards(dayForecasts, isToday),
                ],
              ),

              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),

              // Drag handle
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    DateTime date,
    List<ForecastItem> forecasts,
    bool isToday,
  ) {
    final dateFormat = DateFormat(
      'EEEE, \'ngày\' dd \'tháng\' MM, yyyy',
      'vi_VN',
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_outlined, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Điều kiện thời tiết',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          dateFormat.format(date),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainInfo(List<ForecastItem> forecasts, bool isToday) {
    double avgTemp = 0;
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    String description = '';
    String icon = '';

    if (isToday && currentWeather != null && forecasts.isEmpty) {
      avgTemp = currentWeather!.temp;
      minTemp = currentWeather!.tempMin;
      maxTemp = currentWeather!.tempMax;
      description = currentWeather!.weatherDescription;
      icon = currentWeather!.weatherIcon;
    } else if (forecasts.isNotEmpty) {
      // Tìm forecast item ở giữa ngày (khoảng 12:00) để lấy nhiệt độ chính xác nhất
      final middayForecast = forecasts.firstWhere(
        (item) => item.dtTxt.contains('12:00:00'),
        orElse: () => forecasts[forecasts.length ~/ 2],
      );

      avgTemp = middayForecast.temp;
      minTemp = forecasts.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
      maxTemp = forecasts.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
      description = middayForecast.weatherDescription;
      icon = middayForecast.weatherIcon;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              '${avgTemp.round()}°',
              style: TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              'Độ C (°C)',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
        if (icon.isNotEmpty)
          Image.network(
            'https://openweathermap.org/img/wn/$icon@4x.png',
            width: 100,
            height: 100,
          ),
      ],
    );
  }

  Widget _buildTemperatureChart(List<ForecastItem> forecasts, bool isToday) {
    if (forecasts.isEmpty && !(isToday && currentWeather != null)) {
      return _buildNoDataCard('Không có dữ liệu nhiệt độ');
    }

    List<FlSpot> spots = [];
    List<String> timeLabels = [];

    if (isToday && currentWeather != null && forecasts.isEmpty) {
      // Use current weather only
      spots = [FlSpot(0, currentWeather!.temp)];
      timeLabels = ['Hiện tại'];
    } else {
      for (int i = 0; i < forecasts.length; i++) {
        final item = forecasts[i];
        spots.add(FlSpot(i.toDouble(), item.temp));
        final time = DateTime.fromMillisecondsSinceEpoch(item.dt * 1000);
        timeLabels.add(DateFormat('HH:mm', 'vi_VN').format(time));
      }
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 3;
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 3;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Nhiệt độ theo giờ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}°',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeLabels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              timeLabels[index],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityChart(List<ForecastItem> forecasts, bool isToday) {
    if (forecasts.isEmpty && !(isToday && currentWeather != null)) {
      return _buildNoDataCard('Không có dữ liệu độ ẩm');
    }

    List<FlSpot> spots = [];
    List<String> timeLabels = [];

    if (isToday && currentWeather != null && forecasts.isEmpty) {
      spots = [FlSpot(0, currentWeather!.humidity.toDouble())];
      timeLabels = ['Hiện tại'];
    } else {
      for (int i = 0; i < forecasts.length; i++) {
        final item = forecasts[i];
        spots.add(FlSpot(i.toDouble(), item.humidity.toDouble()));
        final time = DateTime.fromMillisecondsSinceEpoch(item.dt * 1000);
        timeLabels.add(DateFormat('HH:mm', 'vi_VN').format(time));
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Khả năng có mưa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Khả năng có mưa vào thứ Tư: ${_calculateRainProbability(forecasts, isToday)}%',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeLabels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              timeLabels[index],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.cyan,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyan.withOpacity(0.3),
                          Colors.cyan.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Khả năng có mưa hằng ngày có xu hướng cao hơn khả năng có mưa',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards(List<ForecastItem> forecasts, bool isToday) {
    double avgHumidity = 0;
    double avgWindSpeed = 0;
    int avgPressure = 0;
    int avgClouds = 0;
    double feelsLike = 0;

    if (isToday && currentWeather != null && forecasts.isEmpty) {
      avgHumidity = currentWeather!.humidity.toDouble();
      avgWindSpeed = currentWeather!.windSpeed;
      avgPressure = currentWeather!.pressure;
      avgClouds = currentWeather!.clouds;
      feelsLike = currentWeather!.feelsLike;
    } else if (forecasts.isNotEmpty) {
      avgHumidity =
          forecasts.fold(0, (sum, item) => sum + item.humidity) /
          forecasts.length;
      avgWindSpeed =
          forecasts.fold(0.0, (sum, item) => sum + item.windSpeed) /
          forecasts.length;
      avgPressure =
          (forecasts.fold(0, (sum, item) => sum + item.pressure) /
                  forecasts.length)
              .round();
      avgClouds =
          (forecasts.fold(0, (sum, item) => sum + item.clouds) /
                  forecasts.length)
              .round();
      feelsLike =
          forecasts.fold(0.0, (sum, item) => sum + item.feelsLike) /
          forecasts.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thực tế',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Cảm nhận',
                '${feelsLike.round()}°',
                Icons.thermostat_outlined,
                'Nhiệt độ thực tế.',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Độ ẩm',
                '${avgHumidity.round()}%',
                Icons.water_drop_outlined,
                'Điểm sương là ${(feelsLike - 5).round()}°',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Gió',
                '${(avgWindSpeed * 3.6).round()} km/h',
                Icons.air,
                'Tốc độ gió trung bình',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Áp suất',
                '$avgPressure hPa',
                Icons.speed,
                'Áp suất khí quyển',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    String description,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 16),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }

  int _calculateRainProbability(List<ForecastItem> forecasts, bool isToday) {
    if (forecasts.isEmpty) {
      if (isToday && currentWeather != null) {
        return currentWeather!.humidity > 70 ? 70 : currentWeather!.humidity;
      }
      return 0;
    }

    // Calculate based on humidity and clouds
    double avgHumidity =
        forecasts.fold(0, (sum, item) => sum + item.humidity) /
        forecasts.length;
    double avgClouds =
        forecasts.fold(0, (sum, item) => sum + item.clouds) / forecasts.length;

    // Simple probability based on humidity and cloudiness
    return ((avgHumidity * 0.6 + avgClouds * 0.4)).round();
  }
}
