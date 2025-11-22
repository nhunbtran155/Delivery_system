import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

/// ❌ KHÔNG được import trực tiếp (gây lỗi dart:ui_web)
/// import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'core/services/firebase_messaging_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/splash/slpash_screen.dart';

/// 📌 Hàm này chỉ chạy trên Web → tách riêng để Android không load
void configureWebUrlStrategy() {
  if (kIsWeb) {
    // ignore: avoid_web_libraries_in_flutter
    importWebUrlStrategy();
  }
}

/// 📌 Tách logic import url_strategy ra khỏi flow chính
/// để Flutter không cố load dart:ui_web trên Android
void importWebUrlStrategy() {
  // Tránh lỗi compilation → dùng lệnh gọi gián tiếp (dynamic)
  try {
    final flutterWebPluginsLibrary = "package:flutter_web_plugins/flutter_web_plugins.dart";

    // ignore: avoid_dynamic_calls
    final setUrlStrategy = Function.apply(
          () {},
      [],
    );

    // Bạn có thể giữ nguyên logic HashUrlStrategy ở đây
    // Nhưng để an toàn trên Flutter 3.35+, ta để Web auto handle URL
    // Vì HashUrlStrategy đã thay đổi API
  } catch (e) {
    if (kDebugMode) {
      print("⚠️ Web URL Strategy không thể load: $e");
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) print('🔕 [BG] FCM message: ${message.messageId}');
  await FirebaseMessagingHandler.showLocalNotification(message);
}

Future<void> _setupFCM() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(FirebaseMessagingHandler.showLocalNotification);
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessagingHandler.initLocalNotifications();
  await _setupFCM();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();

  /// 🌐 Chỉ cấu hình URL strategy nếu chạy Web
  configureWebUrlStrategy();

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runZonedGuarded(() async {
    runApp(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const DeliveryApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) print('🔥 Uncaught zone error: $error\n$stack');
  });
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnimatedTheme(
      data: themeProvider.isDarkMode
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      child: MaterialApp(
        title: 'Delivery System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,

        // Splash vẫn là màn đầu tiên
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          if (settings.name == '/splash') {
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
          return AppRouter.generateRoute(settings);
        },

        // Ép Splash & Login luôn dark mode
        builder: (context, child) {
          final routeName = ModalRoute.of(context)?.settings.name ?? '';
          final isAuthScreen =
              routeName.contains('splash') || routeName.contains('login');

          final theme = isAuthScreen
              ? AppTheme.darkTheme
              : (themeProvider.isDarkMode
              ? AppTheme.darkTheme
              : AppTheme.lightTheme);

          return Theme(
            data: theme,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
