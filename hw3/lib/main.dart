import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/components_list_screen.dart';
import 'screens/text_detail_screen.dart';
import 'screens/image_detail_screen.dart';
import 'screens/input_detail_screen.dart';
import 'screens/column_demo_screen.dart';
import 'screens/row_demo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Components Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        ComponentsListScreen.routeName: (_) => const ComponentsListScreen(),
        TextDetailScreen.routeName: (_) => const TextDetailScreen(),
        ImageDetailScreen.routeName: (_) => const ImageDetailScreen(),
        TextFieldScreen.routeName: (_) => const TextFieldScreen(),
        PasswordFieldScreen.routeName: (_) => const PasswordFieldScreen(),
        ColumnDemoScreen.routeName: (_) => const ColumnDemoScreen(),
        RowDemoScreen.routeName: (_) => const RowDemoScreen(),
      },
    );
  }
}
