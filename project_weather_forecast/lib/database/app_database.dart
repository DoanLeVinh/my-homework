import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Users table - Thông tin người dùng
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()(); // Hashed password
  TextColumn get displayName => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get uid => text().unique()(); // For Firebase UID later
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  TextColumn get sessionToken => text().nullable()(); // Session token
  DateTimeColumn get sessionExpiry =>
      dateTime().nullable()(); // Session expiry (30 days)
}

// Favorite Cities table - Các thành phố yêu thích
class FavoriteCities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get cityName => text()();
  TextColumn get countryCode => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0))(); // Thứ tự hiển thị
  BoolColumn get isPrimary =>
      boolean().withDefault(const Constant(false))(); // Thành phố chính
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastViewed => dateTime().nullable()(); // Lần cuối xem
}

// Search History table - Lịch sử tìm kiếm
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get searchQuery => text()();
  TextColumn get cityName => text().nullable()();
  TextColumn get countryCode => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get searchedAt => dateTime().withDefault(currentDateAndTime)();
}

// User Settings table - Cài đặt người dùng
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade).unique()();
  TextColumn get temperatureUnit =>
      text().withDefault(const Constant('celsius'))(); // celsius, fahrenheit
  TextColumn get windSpeedUnit =>
      text().withDefault(const Constant('km/h'))(); // km/h, m/s, mph
  TextColumn get pressureUnit =>
      text().withDefault(const Constant('hPa'))(); // hPa, inHg
  TextColumn get timeFormat =>
      text().withDefault(const Constant('24h'))(); // 24h, 12h
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get weatherAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get locationServicesEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get theme =>
      text().withDefault(const Constant('system'))(); // light, dark, system
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Weather Cache table - Cache dữ liệu thời tiết để giảm API calls
class WeatherCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cityName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get weatherData => text()(); // JSON string của weather data
  TextColumn get forecastData =>
      text().nullable()(); // JSON string của forecast data
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()(); // Thời gian hết hạn cache
}

// Events table - Lịch và sự kiện
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()(); // Tiêu đề sự kiện
  TextColumn get description => text().nullable()(); // Mô tả chi tiết
  DateTimeColumn get eventDate => dateTime()(); // Ngày giờ sự kiện
  DateTimeColumn get eventEndDate =>
      dateTime().nullable()(); // Ngày giờ kết thúc (cho sự kiện dài ngày)
  TextColumn get location => text().nullable()(); // Địa điểm
  RealColumn get latitude => real().nullable()(); // Tọa độ địa điểm
  RealColumn get longitude => real().nullable()();
  TextColumn get eventType =>
      text()(); // outdoor, indoor, work, personal, sport, travel
  BoolColumn get needWeatherAlert => boolean().withDefault(
    const Constant(true),
  )(); // Có cần thông báo thời tiết
  BoolColumn get isAllDay =>
      boolean().withDefault(const Constant(false))(); // Sự kiện cả ngày
  TextColumn get reminderTime =>
      text().nullable()(); // Thời gian nhắc nhở: '1hour', '1day', '1week'
  TextColumn get color => text().nullable()(); // Màu sắc tag cho event
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Users,
    FavoriteCities,
    SearchHistory,
    UserSettings,
    WeatherCache,
    Events,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add new columns for session management with proper defaults
          await m.issueCustomQuery(
            'ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ""',
          );
          await m.issueCustomQuery(
            'ALTER TABLE users ADD COLUMN phone_number TEXT',
          );
          await m.issueCustomQuery(
            'ALTER TABLE users ADD COLUMN session_token TEXT',
          );
          await m.issueCustomQuery(
            'ALTER TABLE users ADD COLUMN session_expiry INTEGER',
          );
        }

        if (from < 3) {
          // Add Events table for calendar feature
          await m.createTable(events);
        }
      },
    );
  }

  // ===== USERS DAO =====

  Future<User?> getUserByEmail(String email) {
    return (select(
      users,
    )..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Future<User?> getUserByUid(String uid) {
    return (select(users)..where((u) => u.uid.equals(uid))).getSingleOrNull();
  }

  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  Future<bool> updateUser(UsersCompanion user) {
    return update(users).replace(user);
  }

  Future<int> updateLastLogin(int userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(lastLogin: Value(DateTime.now())),
    );
  }

  // Update user profile
  Future<int> updateUserProfile({
    required int userId,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        displayName: displayName != null
            ? Value(displayName)
            : const Value.absent(),
        phoneNumber: phoneNumber != null
            ? Value(phoneNumber)
            : const Value.absent(),
        photoUrl: photoUrl != null ? Value(photoUrl) : const Value.absent(),
      ),
    );
  }

  // Create/Update session token
  Future<int> createSession(int userId, String token) {
    final expiry = DateTime.now().add(const Duration(days: 30));
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        sessionToken: Value(token),
        sessionExpiry: Value(expiry),
        lastLogin: Value(DateTime.now()),
      ),
    );
  }

  // Validate session
  Future<User?> getUserBySession(String token) async {
    final user = await (select(
      users,
    )..where((u) => u.sessionToken.equals(token))).getSingleOrNull();

    if (user != null && user.sessionExpiry != null) {
      // Check if session is still valid
      if (user.sessionExpiry!.isAfter(DateTime.now())) {
        return user;
      } else {
        // Session expired - clear it
        await clearSession(user.id);
        return null;
      }
    }

    return null;
  }

  // Clear session (logout)
  Future<int> clearSession(int userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      const UsersCompanion(
        sessionToken: Value(null),
        sessionExpiry: Value(null),
      ),
    );
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // ===== FAVORITE CITIES DAO =====

  // Lấy tất cả thành phố yêu thích của user, sắp xếp theo displayOrder
  Future<List<FavoriteCity>> getFavoriteCities(int userId) {
    return (select(favoriteCities)
          ..where((c) => c.userId.equals(userId))
          ..orderBy([(c) => OrderingTerm(expression: c.displayOrder)]))
        .get();
  }

  // Lấy thành phố chính (isPrimary = true)
  Future<FavoriteCity?> getPrimaryCity(int userId) {
    return (select(favoriteCities)
          ..where((c) => c.userId.equals(userId) & c.isPrimary.equals(true)))
        .getSingleOrNull();
  }

  // Thêm thành phố yêu thích
  Future<int> addFavoriteCity(FavoriteCitiesCompanion city) async {
    // Nếu là primary city, bỏ primary của các city khác
    if (city.isPrimary.value == true) {
      await (update(favoriteCities)
            ..where((c) => c.userId.equals(city.userId.value)))
          .write(const FavoriteCitiesCompanion(isPrimary: Value(false)));
    }
    return into(favoriteCities).insert(city);
  }

  // Cập nhật thành phố yêu thích
  Future<bool> updateFavoriteCity(FavoriteCitiesCompanion city) async {
    // Nếu set làm primary, bỏ primary của các city khác
    if (city.isPrimary.value == true) {
      await (update(favoriteCities)..where(
            (c) =>
                c.userId.equals(city.userId.value) &
                c.id.equals(city.id.value).not(),
          ))
          .write(const FavoriteCitiesCompanion(isPrimary: Value(false)));
    }
    return update(favoriteCities).replace(city);
  }

  // Xóa thành phố yêu thích
  Future<int> deleteFavoriteCity(int cityId) {
    return (delete(favoriteCities)..where((c) => c.id.equals(cityId))).go();
  }

  // Cập nhật thứ tự hiển thị
  Future<int> updateCityOrder(int cityId, int newOrder) {
    return (update(favoriteCities)..where((c) => c.id.equals(cityId))).write(
      FavoriteCitiesCompanion(displayOrder: Value(newOrder)),
    );
  }

  // Cập nhật lastViewed
  Future<int> updateCityLastViewed(int cityId) {
    return (update(favoriteCities)..where((c) => c.id.equals(cityId))).write(
      FavoriteCitiesCompanion(lastViewed: Value(DateTime.now())),
    );
  }

  // Kiểm tra xem city đã được lưu chưa
  Future<bool> isCityFavorited(int userId, double lat, double lon) async {
    final result =
        await (select(favoriteCities)..where(
              (c) =>
                  c.userId.equals(userId) &
                  c.latitude.equals(lat) &
                  c.longitude.equals(lon),
            ))
            .getSingleOrNull();
    return result != null;
  }

  // ===== SEARCH HISTORY DAO =====

  // Lấy lịch sử tìm kiếm gần đây (limit 20)
  Future<List<SearchHistoryData>> getRecentSearches(
    int userId, {
    int limit = 20,
  }) {
    return (select(searchHistory)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.searchedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  // Thêm lịch sử tìm kiếm
  Future<int> addSearchHistory(SearchHistoryCompanion search) {
    return into(searchHistory).insert(search);
  }

  // Xóa lịch sử tìm kiếm
  Future<int> deleteSearchHistory(int searchId) {
    return (delete(searchHistory)..where((s) => s.id.equals(searchId))).go();
  }

  // Xóa toàn bộ lịch sử của user
  Future<int> clearSearchHistory(int userId) {
    return (delete(searchHistory)..where((s) => s.userId.equals(userId))).go();
  }

  // Xóa lịch sử cũ hơn X ngày
  Future<int> deleteOldSearchHistory(int userId, int daysOld) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(searchHistory)..where(
          (s) =>
              s.userId.equals(userId) &
              s.searchedAt.isSmallerThanValue(cutoffDate),
        ))
        .go();
  }

  // ===== USER SETTINGS DAO =====

  // Lấy settings của user
  Future<UserSetting?> getUserSettings(int userId) {
    return (select(
      userSettings,
    )..where((s) => s.userId.equals(userId))).getSingleOrNull();
  }

  // Tạo settings mặc định cho user mới
  Future<int> createDefaultSettings(int userId) {
    return into(userSettings).insert(
      UserSettingsCompanion(
        userId: Value(userId),
        temperatureUnit: const Value('celsius'),
        windSpeedUnit: const Value('km/h'),
        pressureUnit: const Value('hPa'),
        timeFormat: const Value('24h'),
        notificationsEnabled: const Value(true),
        weatherAlertsEnabled: const Value(true),
        locationServicesEnabled: const Value(true),
        theme: const Value('system'),
      ),
    );
  }

  // Cập nhật settings
  Future<bool> updateUserSettings(UserSettingsCompanion settings) {
    return update(userSettings).replace(settings);
  }

  // Update specific setting
  Future<int> updateSetting(int userId, UserSettingsCompanion setting) {
    return (update(
      userSettings,
    )..where((s) => s.userId.equals(userId))).write(setting);
  }

  // ===== WEATHER CACHE DAO =====

  // Lấy cache weather data (nếu chưa hết hạn)
  Future<WeatherCacheData?> getCachedWeather(String cityName) async {
    final now = DateTime.now();
    final result =
        await (select(weatherCache)..where(
              (c) =>
                  c.cityName.equals(cityName) &
                  c.expiresAt.isBiggerThanValue(now),
            ))
            .getSingleOrNull();
    return result;
  }

  // Lấy cache theo coordinates
  Future<WeatherCacheData?> getCachedWeatherByCoords(
    double lat,
    double lon,
  ) async {
    final now = DateTime.now();
    final result =
        await (select(weatherCache)..where(
              (c) =>
                  c.latitude.equals(lat) &
                  c.longitude.equals(lon) &
                  c.expiresAt.isBiggerThanValue(now),
            ))
            .getSingleOrNull();
    return result;
  }

  // Lưu cache weather data (cache 10 phút)
  Future<int> cacheWeatherData(WeatherCacheCompanion cache) async {
    // Xóa cache cũ của city này
    await (delete(weatherCache)..where(
          (c) =>
              c.cityName.equals(cache.cityName.value) |
              (c.latitude.equals(cache.latitude.value) &
                  c.longitude.equals(cache.longitude.value)),
        ))
        .go();

    return into(weatherCache).insert(cache);
  }

  // Xóa cache hết hạn
  Future<int> deleteExpiredCache() {
    final now = DateTime.now();
    return (delete(
      weatherCache,
    )..where((c) => c.expiresAt.isSmallerThanValue(now))).go();
  }

  // Xóa toàn bộ cache
  Future<int> clearAllCache() {
    return delete(weatherCache).go();
  }

  // ===== EVENTS DAO =====

  // Lấy tất cả events của user
  Future<List<Event>> getUserEvents(int userId) {
    return (select(events)
          ..where((e) => e.userId.equals(userId))
          ..orderBy([(e) => OrderingTerm(expression: e.eventDate)]))
        .get();
  }

  // Lấy events theo tháng
  Future<List<Event>> getEventsByMonth(int userId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(events)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.eventDate.isBiggerOrEqualValue(startOfMonth) &
                e.eventDate.isSmallerOrEqualValue(endOfMonth),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.eventDate)]))
        .get();
  }

  // Lấy events theo ngày
  Future<List<Event>> getEventsByDate(int userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (select(events)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.eventDate.isBiggerOrEqualValue(startOfDay) &
                e.eventDate.isSmallerOrEqualValue(endOfDay),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.eventDate)]))
        .get();
  }

  // Lấy events sắp tới (upcoming)
  Future<List<Event>> getUpcomingEvents(int userId, {int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return (select(events)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.eventDate.isBiggerOrEqualValue(now) &
                e.eventDate.isSmallerOrEqualValue(future),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.eventDate)]))
        .get();
  }

  // Lấy events outdoor sắp tới (cần thông báo thời tiết)
  Future<List<Event>> getOutdoorEventsForWeatherAlert(
    int userId, {
    int days = 3,
  }) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return (select(events)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.eventDate.isBiggerOrEqualValue(now) &
                e.eventDate.isSmallerOrEqualValue(future) &
                e.needWeatherAlert.equals(true) &
                e.eventType.equals('outdoor'),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.eventDate)]))
        .get();
  }

  // Lấy event theo ID
  Future<Event?> getEventById(int eventId) {
    return (select(
      events,
    )..where((e) => e.id.equals(eventId))).getSingleOrNull();
  }

  // Thêm event mới
  Future<int> insertEvent(EventsCompanion event) {
    return into(events).insert(event);
  }

  // Cập nhật event
  Future<bool> updateEvent(EventsCompanion event) {
    return update(events).replace(event);
  }

  // Xóa event
  Future<int> deleteEvent(int eventId) {
    return (delete(events)..where((e) => e.id.equals(eventId))).go();
  }

  // Đếm số events trong tháng
  Future<int> countEventsInMonth(int userId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final count = countAll();
    final query = selectOnly(events)
      ..addColumns([count])
      ..where(
        events.userId.equals(userId) &
            events.eventDate.isBiggerOrEqualValue(startOfMonth) &
            events.eventDate.isSmallerOrEqualValue(endOfMonth),
      );

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Tìm kiếm events
  Future<List<Event>> searchEvents(int userId, String query) {
    return (select(events)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                (e.title.contains(query) |
                    e.description.contains(query) |
                    e.location.contains(query)),
          )
          ..orderBy([
            (e) =>
                OrderingTerm(expression: e.eventDate, mode: OrderingMode.desc),
          ]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'weather_app.db'));
    return NativeDatabase(file);
  });
}
