import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/weather_provider.dart';
import 'providers/database_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
  }

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found. Using default values.');
  }

  // Initialize Vietnamese locale for date formatting
  await initializeDateFormatting('vi_VN', null);

  // Initialize notification service
  try {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Notification service error: $e');
  }

  // Set status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProxyProvider<DatabaseProvider, WeatherProvider>(
          create: (context) =>
              WeatherProvider(context.read<DatabaseProvider>()),
          update: (context, dbProvider, previous) =>
              previous ?? WeatherProvider(dbProvider),
        ),
        ChangeNotifierProxyProvider<DatabaseProvider, AuthProvider>(
          create: (context) => AuthProvider(
            database: context.read<DatabaseProvider>().database,
            databaseProvider: context.read<DatabaseProvider>(),
          ),
          update: (context, dbProvider, previous) =>
              previous ??
              AuthProvider(
                database: dbProvider.database,
                databaseProvider: dbProvider,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Dự báo Thời tiết',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
