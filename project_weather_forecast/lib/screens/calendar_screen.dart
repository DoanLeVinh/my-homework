import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';
import '../database/app_database.dart';
import '../widgets/weather_background.dart';
import 'login_screen.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final user = dbProvider.currentUser;

    if (user != null) {
      // Load events cho tháng hiện tại
      final events = await dbProvider.database.getEventsByMonth(
        user.id,
        _focusedDay,
      );

      // Group events by date
      final Map<DateTime, List<Event>> eventMap = {};
      for (var event in events) {
        final dateKey = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        if (eventMap[dateKey] == null) {
          eventMap[dateKey] = [];
        }
        eventMap[dateKey]!.add(event);
      }

      setState(() {
        _events = eventMap;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<DatabaseProvider, AuthProvider, WeatherProvider>(
        builder: (context, dbProvider, authProvider, weatherProvider, child) {
          final user = dbProvider.currentUser;

          if (user == null) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2C3E50),
                    Color(0xFF34495E),
                    Color(0xFF3D566E),
                    Color(0xFF4A5F7F),
                  ],
                ),
              ),
              child: SafeArea(child: _buildLoginPrompt()),
            );
          }

          // Lấy thời tiết cho ngày được chọn
          return FutureBuilder(
            future: weatherProvider.getWeatherForDate(
              _selectedDay ?? DateTime.now(),
            ),
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
                      // Header
                      _buildHeader(),

                      // Calendar
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Table Calendar
                                    _buildCalendar(),

                                    // Events list for selected day
                                    _buildEventsList(),
                                  ],
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
      floatingActionButton: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          if (dbProvider.currentUser == null) return SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _addNewEvent(),
            backgroundColor: Color(0xFF4A90E2),
            icon: Icon(Icons.add),
            label: Text('Thêm sự kiện'),
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
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Lịch & Sự kiện',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadEvents();
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF4A90E2),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white70),
          todayTextStyle: TextStyle(color: Colors.white),
          selectedTextStyle: TextStyle(color: Colors.white),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white70),
          weekendStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) return SizedBox.shrink();

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              'Không có sự kiện nào',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDay!),
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Sự kiện ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...events.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final Color eventColor = _getEventColor(event.eventType);
    final IconData eventIcon = _getEventIcon(event.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: eventColor.withOpacity(0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewEventDetail(event),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(eventIcon, color: eventColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.isAllDay
                                ? 'Cả ngày'
                                : DateFormat('HH:mm').format(event.eventDate),
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          if (event.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.white38),
            const SizedBox(height: 24),
            Text(
              'Cần đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đăng nhập để sử dụng tính năng lịch và sự kiện',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (result == true && mounted) {
                  _loadEvents();
                }
              },
              icon: Icon(Icons.login),
              label: Text('Đăng nhập'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'outdoor':
        return Colors.green;
      case 'indoor':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      case 'personal':
        return Colors.purple;
      case 'sport':
        return Colors.red;
      case 'travel':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'outdoor':
        return Icons.park;
      case 'indoor':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'sport':
        return Icons.sports_soccer;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.event;
    }
  }

  Future<void> _addNewEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(selectedDate: _selectedDay),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _viewEventDetail(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );

    if (result == true) {
      _loadEvents();
    }
  }
}
