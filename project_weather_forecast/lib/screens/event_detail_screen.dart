import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/database_provider.dart';
import '../providers/weather_provider.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_engine.dart';
import '../widgets/weather_background.dart';
import '../widgets/in_app_notification.dart';

class EventDetailScreen extends StatefulWidget {
  final Event? event;
  final DateTime? selectedDate;

  const EventDetailScreen({super.key, this.event, this.selectedDate});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _eventDate = DateTime.now();
  DateTime? _eventEndDate;
  String _eventType = 'personal';
  bool _needWeatherAlert = true;
  bool _isAllDay = false;
  String _reminderTime = '1hour';
  String _color = 'blue';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      // Edit mode
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _eventDate = event.eventDate;
      _eventEndDate = event.eventEndDate;
      _eventType = event.eventType;
      _needWeatherAlert = event.needWeatherAlert;
      _isAllDay = event.isAllDay;
      _reminderTime = event.reminderTime ?? '1hour';
      _color = event.color ?? 'blue';
    } else if (widget.selectedDate != null) {
      // New event with pre-selected date
      _eventDate = widget.selectedDate!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.event != null;

    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          // Lấy thời tiết cho ngày của event
          return FutureBuilder(
            future: weatherProvider.getWeatherForDate(_eventDate),
            builder: (context, snapshot) {
              final weather = snapshot.data;
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
                      _buildHeader(isEditMode),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleField(),
                                const SizedBox(height: 20),
                                _buildDescriptionField(),
                                const SizedBox(height: 20),
                                _buildDateTimeSection(),
                                const SizedBox(height: 20),
                                _buildLocationField(),
                                const SizedBox(height: 20),
                                _buildEventTypeDropdown(),
                                const SizedBox(height: 20),
                                _buildReminderDropdown(),
                                const SizedBox(height: 20),
                                _buildSwitches(),
                                const SizedBox(height: 32),
                                _buildActionButtons(isEditMode),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isEditMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              isEditMode ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện mới',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiêu đề *',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tiêu đề sự kiện',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.title, color: Colors.white60),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tiêu đề';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          style: TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập mô tả chi tiết',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildDateTimePicker(
            label: 'Ngày bắt đầu',
            date: _eventDate,
            onTap: () => _selectDateTime(true),
          ),
          const SizedBox(height: 12),
          _buildDateTimePicker(
            label: 'Ngày kết thúc',
            date: _eventEndDate,
            onTap: () => _selectDateTime(false),
            optional: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? (_isAllDay
                              ? DateFormat('dd/MM/yyyy').format(date)
                              : DateFormat('dd/MM/yyyy HH:mm').format(date))
                        : optional
                        ? 'Không xác định'
                        : 'Chọn ngày giờ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa điểm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập địa điểm',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.location_on, color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại sự kiện',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _eventType,
          dropdownColor: Color(0xFF2C3E50),
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.category, color: Colors.white60),
          ),
          items: [
            DropdownMenuItem(value: 'outdoor', child: Text('🌳 Ngoài trời')),
            DropdownMenuItem(value: 'indoor', child: Text('🏠 Trong nhà')),
            DropdownMenuItem(value: 'work', child: Text('💼 Công việc')),
            DropdownMenuItem(value: 'personal', child: Text('👤 Cá nhân')),
            DropdownMenuItem(value: 'sport', child: Text('⚽ Thể thao')),
            DropdownMenuItem(value: 'travel', child: Text('✈️ Du lịch')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _eventType = value;
                // Auto-enable weather alert for outdoor events
                if (value == 'outdoor' ||
                    value == 'sport' ||
                    value == 'travel') {
                  _needWeatherAlert = true;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildReminderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhắc nhở',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _reminderTime,
          dropdownColor: Color(0xFF2C3E50),
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.notifications, color: Colors.white60),
          ),
          items: [
            DropdownMenuItem(value: '1hour', child: Text('1 giờ trước')),
            DropdownMenuItem(value: '1day', child: Text('1 ngày trước')),
            DropdownMenuItem(value: '1week', child: Text('1 tuần trước')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _reminderTime = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSwitches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Cả ngày',
            subtitle: 'Sự kiện diễn ra cả ngày',
            value: _isAllDay,
            onChanged: (value) => setState(() => _isAllDay = value),
            icon: Icons.calendar_view_day,
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 24),
          _buildSwitchTile(
            title: 'Thông báo thời tiết',
            subtitle: 'Nhận cảnh báo về thời tiết cho sự kiện này',
            value: _needWeatherAlert,
            onChanged: (value) => setState(() => _needWeatherAlert = value),
            icon: Icons.wb_sunny,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white60, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF4A90E2),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isEditMode) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    isEditMode ? 'Cập nhật' : 'Thêm sự kiện',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        if (isEditMode) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteEvent,
              icon: Icon(Icons.delete),
              label: Text('Xóa sự kiện'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDateTime(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _eventDate : (_eventEndDate ?? _eventDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF4A90E2),
              surface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (!mounted) return;

    if (!_isAllDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartDate ? _eventDate : (_eventEndDate ?? _eventDate),
        ),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Color(0xFF4A90E2),
                surface: Color(0xFF2C3E50),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        if (!mounted) return;
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (isStartDate) {
            _eventDate = newDateTime;
          } else {
            _eventEndDate = newDateTime;
          }
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        if (isStartDate) {
          _eventDate = date;
        } else {
          _eventEndDate = date;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final user = dbProvider.currentUser;

      if (user == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final eventData = EventsCompanion(
        userId: drift.Value(user.id),
        title: drift.Value(_titleController.text.trim()),
        description: drift.Value(
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
        eventDate: drift.Value(_eventDate),
        eventEndDate: drift.Value(_eventEndDate),
        location: drift.Value(
          _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        ),
        latitude: drift.Value(null),
        longitude: drift.Value(null),
        eventType: drift.Value(_eventType),
        needWeatherAlert: drift.Value(_needWeatherAlert),
        isAllDay: drift.Value(_isAllDay),
        reminderTime: drift.Value(_reminderTime),
        color: drift.Value(_color),
        updatedAt: drift.Value(DateTime.now()),
      );

      if (widget.event != null) {
        // Update existing event
        await dbProvider.database.updateEvent(
          eventData.copyWith(id: drift.Value(widget.event!.id)),
        );

        // Cancel old notifications and reschedule
        await NotificationService().cancelEventNotification(widget.event!.id);
        await _scheduleEventNotifications(widget.event!.id);
      } else {
        // Insert new event
        final eventId = await dbProvider.database.insertEvent(
          eventData.copyWith(createdAt: drift.Value(DateTime.now())),
        );

        // Schedule notifications for new event
        await _scheduleEventNotifications(eventId);
      }

      if (mounted) {
        // Show beautiful in-app notification instead of SnackBar
        final isNew = widget.event == null;
        NotificationHelper.showSuccess(
          context: context,
          title: isNew ? '✨ Đã tạo sự kiện!' : '✅ Đã cập nhật!',
          message: isNew
              ? 'Sự kiện "${_titleController.text}" vào ${DateFormat('dd/MM/yyyy').format(_eventDate)}'
              : 'Thông tin sự kiện đã được cập nhật',
          onTap: () {
            Navigator.pop(context, true);
          },
        );

        // Delay navigation để user có thể xem notification
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể lưu sự kiện: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.event == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2C3E50),
        title: Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa sự kiện này?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

      // Cancel all notifications for this event
      await NotificationService().cancelEventNotification(widget.event!.id);

      // Delete event from database
      await dbProvider.database.deleteEvent(widget.event!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa sự kiện và thông báo'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Schedule notifications for event
  Future<void> _scheduleEventNotifications(int eventId) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );

      // Get the saved event
      final event = await dbProvider.database.getEventById(eventId);
      if (event == null) return;

      // Only schedule if weather alert is enabled
      if (!event.needWeatherAlert) return;

      final notificationService = NotificationService();
      final engine = SmartNotificationEngine();

      // 1. Send immediate beautiful in-app notification with weather forecast
      if (weatherProvider.currentWeather != null && mounted) {
        final weatherInfo = await engine.analyzeWeather(
          weatherProvider.currentWeather!,
        );

        final message = engine.generateSmartMessage(weatherInfo, event);

        // Show in-app notification
        if (mounted) {
          NotificationHelper.showEventReminder(
            context: context,
            title: '📅 ${event.title}',
            message:
                '${DateFormat('dd/MM/yyyy HH:mm').format(event.eventDate)}\n$message',
            onTap: () {
              // User can tap to view event details or dismiss
            },
          );
        }

        // Also send system notification
        await notificationService.showInstantNotification(
          id: eventId,
          title: '📅 Sự kiện mới: ${event.title}',
          body: message,
        );
      }

      // 2. Schedule notification 1 hour before event
      final oneHourBefore = event.eventDate.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(DateTime.now())) {
        await notificationService.scheduleEventReminder(event, oneHourBefore);
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }
}
