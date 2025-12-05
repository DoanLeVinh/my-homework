import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_engine.dart';
import '../providers/weather_provider.dart';
import '../providers/database_provider.dart';
import '../database/app_database.dart';
import '../widgets/weather_background.dart';
import '../widgets/enhanced_text.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyWeatherNotif = false;
  bool _eventReminders = false;
  String _reminderTime = '1hour';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyWeatherNotif = prefs.getBool('daily_weather_notif') ?? false;
      _eventReminders = prefs.getBool('event_reminders') ?? false;
      _reminderTime = prefs.getString('reminder_time') ?? '1hour';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_weather_notif', _dailyWeatherNotif);
    await prefs.setBool('event_reminders', _eventReminders);
    await prefs.setString('reminder_time', _reminderTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final weather = weatherProvider.currentWeather;
          final weatherCondition = weather?.weatherMain ?? 'Clear';
          final currentTime = weather?.currentTime;
          final isNight = weather?.isNightTime ?? false;

          return WeatherBackground(
            weatherCondition: weatherCondition,
            currentTime: currentTime,
            isNight: isNight,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNotificationSettings(),
                                const SizedBox(height: 24),
                                _buildReminderTimeSettings(),
                                const SizedBox(height: 32),
                                _buildTestSection(),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: EnhancedText(
              'Cài đặt Thông báo',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return LiquidGlassCard(
      blurIntensity: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Thông báo thời tiết',
            icon: Icons.notifications_active,
            fontSize: 18,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Thông báo hàng ngày',
            subtitle: 'Nhận dự báo thời tiết mỗi sáng lúc 7:00',
            value: _dailyWeatherNotif,
            onChanged: (value) async {
              setState(() => _dailyWeatherNotif = value);
              await _saveSettings();

              if (value) {
                await NotificationService().scheduleDailyNotification(
                  id: 1,
                  title: '🌞 Thời tiết hôm nay',
                  body: 'Xem dự báo thời tiết và gợi ý trang phục',
                  hour: 7,
                  minute: 0,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã bật thông báo hàng ngày lúc 7:00 sáng'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                await NotificationService().cancelNotification(1);
              }
            },
            icon: Icons.wb_sunny,
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 32),
          _buildSwitchTile(
            title: 'Nhắc nhở sự kiện',
            subtitle: 'Nhận thông báo trước sự kiện có weather alert',
            value: _eventReminders,
            onChanged: (value) async {
              setState(() => _eventReminders = value);
              await _saveSettings();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Đã bật nhắc nhở sự kiện'
                          : 'Đã tắt nhắc nhở sự kiện',
                    ),
                    backgroundColor: value ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            icon: Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: value
                  ? [
                      Colors.blue.withValues(alpha: 0.25),
                      Colors.blue.withValues(alpha: 0.15),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (value ? Colors.blue : Colors.black).withValues(
                  alpha: 0.2,
                ),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: value
                      ? LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade700, Colors.grey.shade800],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (value ? Colors.blue : Colors.grey).withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnhancedText(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EnhancedText(
                      subtitle,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.blue.shade400,
                activeTrackColor: Colors.blue.shade200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderTimeSettings() {
    return LiquidGlassCard(
      blurIntensity: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Thời gian nhắc nhở',
            icon: Icons.access_time,
            fontSize: 18,
          ),
          const SizedBox(height: 20),
          EnhancedText(
            'Chọn thời gian nhắc nhở trước sự kiện:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonFormField<String>(
              value: _reminderTime,
              dropdownColor: Color(0xFF2C3E50),
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: '1hour',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('1 giờ trước'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: '1day',
                  child: Row(
                    children: [
                      Icon(Icons.today, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('1 ngày trước'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: '1week',
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('1 tuần trước'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _reminderTime = value);
                  await _saveSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Đã cập nhật thời gian nhắc nhở'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return LiquidGlassCard(
      tintColor: Colors.green,
      blurIntensity: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.bug_report, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              EnhancedText(
                'Test Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[300],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: LiquidGlassButton(
              onPressed: _testNotificationNow,
              icon: Icons.notifications_active,
              color: Colors.green,
              child: EnhancedText(
                '🔔 Test ngay bây giờ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _testNotificationWithEvent,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              color: Colors.green[300],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            EnhancedText(
                              '📅 Test với event mai',
                              style: TextStyle(
                                color: Colors.green[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotificationNow() async {
    try {
      // Request permissions
      final hasPermission = await NotificationService().requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vui lòng cấp quyền thông báo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current weather
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final weather = weatherProvider.currentWeather;

      if (weather == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không có dữ liệu thời tiết'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate message
      final title = SmartNotificationEngine.generateTitle(null);
      final body = SmartNotificationEngine.generateWeatherMessage(weather);

      // Send notification
      await NotificationService().showInstantNotification(
        id: 999,
        title: title,
        body: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi thông báo test!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testNotificationWithEvent() async {
    try {
      // Request permissions
      final hasPermission = await NotificationService().requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vui lòng cấp quyền thông báo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get weather and simulate event tomorrow
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final weather = weatherProvider.currentWeather;

      if (weather == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không có dữ liệu thời tiết'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Simulate event
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final user = dbProvider.currentUser;

      if (user == null) return;

      // Create fake event for demo using Data class
      final fakeEvent = Event(
        id: -1,
        userId: user.id,
        title: 'Đi chơi công viên',
        description: 'Test event',
        eventDate: DateTime.now().add(Duration(days: 1)),
        eventEndDate: null,
        location: 'Công viên',
        latitude: null,
        longitude: null,
        eventType: 'outdoor',
        needWeatherAlert: true,
        isAllDay: false,
        reminderTime: '1hour',
        color: 'green',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Generate message
      final title = SmartNotificationEngine.generateTitle(fakeEvent);
      final body = SmartNotificationEngine.generateWeatherMessage(
        weather,
        event: fakeEvent,
      );

      // Send notification
      await NotificationService().showInstantNotification(
        id: 998,
        title: title,
        body: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi thông báo test với event!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
