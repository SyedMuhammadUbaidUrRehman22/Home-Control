import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home_app/features/auth/auth_gate.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class ThemeController extends InheritedWidget {
  final bool isDark;
  final Function(bool) toggleTheme;

  const ThemeController({
    super.key,
    required this.isDark,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<ThemeController>();

    if (result == null) {
      throw Exception("ThemeController not found in widget tree");
    }

    return result;
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) =>
      isDark != oldWidget.isDark;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  void toggleTheme(bool value) {
    setState(() => isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      isDark: isDark,
      toggleTheme: toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFF7EF),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        ),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: AuthGate(),      ),
    );
  }
}
