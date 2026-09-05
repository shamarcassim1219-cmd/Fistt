import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// ===== App-wide dark design tokens =====
class AppColors {
  static const bg = Color(0xFF0B0B10);
  static const surface = Color(0xFF15151C);
  static const fieldFill = Color(0xFF1A1A22);
  static const border = Color(0xFF2C2C36);
  static const hint = Color(0xFF8E8E99);
  static const primary = Color(0xFF6C4CF1);
  static const white = Colors.white;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    initError = e.toString();
  }

  runApp(MyGameApp(initError: initError));
}

class MyGameApp extends StatelessWidget {
  final String? initError;
  const MyGameApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYGame Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.25),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldFill,
          hintStyle: const TextStyle(color: AppColors.hint),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white54),
          ),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.hint,
          textColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.hint),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: initError != null
          ? Scaffold(
              backgroundColor: AppColors.bg,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Firebase Init Error:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        initError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.hint),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SplashScreen(),
    );
  }
}
