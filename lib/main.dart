import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';

class AppColors {
  static const bg = Color(0xFF0B0B10);
  static const surface = Color(0xFF15151C);
  static const fieldFill = Color(0xFF1A1A22);
  static const border = Color(0xFF2C2C36);
  static const hint = Color(0xFF8E8E99);
  static const primary = Color(0xFF6C4CF1);
  static const white = Colors.white;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {}

  runApp(const MyGameApp());
}

class MyGameApp extends StatefulWidget {
  const MyGameApp({super.key});

  @override
  State<MyGameApp> createState() => _MyGameAppState();
}

class _MyGameAppState extends State<MyGameApp> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLocked = false;
  bool _biometricEnabled = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFcm();
    _loadBiometricSetting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_lock_enabled') ?? false;
    setState(() {
      _biometricEnabled = enabled;
      _isLocked = enabled;
    });
    if (enabled) _tryUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_biometricEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null && DateTime.now().difference(_pausedAt!) > const Duration(seconds: 5)) {
        setState(() => _isLocked = true);
        _tryUnlock();
      }
    }
  }

  Future<void> _tryUnlock() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        setState(() => _isLocked = false);
        return;
      }
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock MYGame Marketplace',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (didAuth) {
        setState(() => _isLocked = false);
      }
    } catch (e) {
      setState(() => _isLocked = false);
    }
  }

  Future<void> _setupFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        final loggedIn = await ApiService.getToken();
        if (loggedIn != null) {
          await ApiService.saveFcmToken(token);
        }
      }

      messaging.onTokenRefresh.listen((newToken) async {
        final loggedIn = await ApiService.getToken();
        if (loggedIn != null) {
          await ApiService.saveFcmToken(newToken);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final context = navigatorKey.currentContext;
        if (context != null && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.notification!.title}: ${message.notification!.body}'),
              backgroundColor: AppColors.surface,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: Stack(
        children: [
          const SplashScreen(),
          if (_isLocked)
            Positioned.fill(
              child: Container(
                color: AppColors.bg,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint, size: 80, color: AppColors.primary),
                      const SizedBox(height: 24),
                      const Text('App Locked', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _tryUnlock,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Unlock'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
