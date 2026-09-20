import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/app_version_service.dart';
import 'screens/force_update_screen.dart';
import 'widgets/no_internet_overlay.dart';
import 'screens/purchase_detail_screen.dart';
import 'screens/sale_detail_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/admin_chat_screen.dart';

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

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'mygame_notifications',
  'MYGame Notifications',
  description: 'Notifications for orders, offers, and account activity',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppLocalizations.loadSavedLanguage();
  } catch (e, st) {
    debugPrint('STARTUP_LANGUAGE_ERROR: $e');
    debugPrintStack(stackTrace: st);
  }

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final localNotifications = FlutterLocalNotificationsPlugin();
      await localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await localNotifications.initialize(const InitializationSettings(android: androidInit));
    } catch (e) {}
  }

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
  bool _unlocking = false;
  DateTime? _pausedAt;
  AppVersionInfo? _forceUpdateInfo;
  bool _versionCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _setupFcm();
      _loadBiometricSetting();
      _checkAppVersion();
    } else {
      _versionCheckDone = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = await AppVersionService.checkVersion();

      if (!mounted) return;

      if (info != null && currentBuild < info.minimumVersionCode) {
        setState(() {
          _forceUpdateInfo = info;
          _versionCheckDone = true;
        });
      } else {
        setState(() {
          _versionCheckDone = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _versionCheckDone = true;
        });
      }
    }
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
      if (!_isLocked) {
        setState(() => _isLocked = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        _pausedAt = null; // consume it — don't re-trigger on later spurious resumes
        _tryUnlock();
      }
    }
  }

  // Fingerprint is mandatory when enabled — the app stays locked on any failure,
  // cancellation, or missing biometric hardware. The only way in is a successful
  // scan or turning the setting off from within an already-unlocked session.
  Future<void> _tryUnlock() async {
    if (_unlocking) return;
    _unlocking = true;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        // No biometric hardware available — keep the app locked and let the
        // user know, rather than silently letting them in.
        _unlocking = false;
        return;
      }
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock MYGame Marketplace',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (didAuth) {
        setState(() => _isLocked = false);
      }
      // If didAuth is false (cancelled/failed), stay locked — no fallback unlock.
    } catch (e) {
      // Any plugin/platform error also keeps the app locked.
    } finally {
      _unlocking = false;
    }
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;
    final relatedIdStr = data['relatedId'] as String?;
    final relatedId = int.tryParse(relatedIdStr ?? '');
    final nav = navigatorKey.currentState;
    if (nav == null || type == null) return;

    const orderTypes = {
      'order_completed', 'sale_paid', 'dispute_resolved', 'dispute_raised', 'credentials_shared'
    };
    const offerTypes = {'offer_received', 'offer_accepted', 'offer_rejected', 'outbid'};

    try {
      if (orderTypes.contains(type) && relatedId != null) {
        // Try to find this order among purchases first, then sales.
        try {
          final purchases = await ApiService.getMyPurchases();
          final match = purchases.firstWhere(
            (o) => o['id'] == relatedId,
            orElse: () => null,
          );
          if (match != null) {
            nav.push(MaterialPageRoute(builder: (_) => PurchaseDetailScreen(order: match)));
            return;
          }
        } catch (_) {}
        try {
          final sales = await ApiService.getMySales();
          final match = sales.firstWhere(
            (o) => o['id'] == relatedId,
            orElse: () => null,
          );
          if (match != null) {
            nav.push(MaterialPageRoute(builder: (_) => SaleDetailScreen(order: match)));
            return;
          }
        } catch (_) {}
        nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        return;
      }

      if (offerTypes.contains(type)) {
        nav.push(MaterialPageRoute(builder: (_) => const OffersScreen()));
        return;
      }

      if (type == 'admin_message' && relatedId != null) {
        nav.push(MaterialPageRoute(builder: (_) => AdminChatScreen(orderId: relatedId)));
        return;
      }

      // new_message, promotion, and anything unrecognized falls back here.
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    } catch (_) {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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
                onPressed: () => _handleNotificationTap(message),
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => NoInternetOverlay(child: child ?? const SizedBox.shrink()),
      title: 'MyGame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
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
      home: !_versionCheckDone
          ? const SplashScreen()
          : _forceUpdateInfo != null
              ? ForceUpdateScreen(info: _forceUpdateInfo!)
              : Stack(
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
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Verify your fingerprint or face to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.hint, fontSize: 13),
                        ),
                      ),
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
