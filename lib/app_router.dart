import 'package:delivery_app/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/customer/customer_home.dart';
import '../screens/shipper/shipper_home.dart';
import '../screens/admin/admin_home.dart';
import '../screens/splash/slpash_screen.dart';// 👈 thêm import này

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash': // 👈 thêm route mới
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/customer':
        return MaterialPageRoute(builder: (_) => const CustomerHome());
      case '/shipper':
        return MaterialPageRoute(builder: (_) => const ShipperHome());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminHome());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - Page not found')),
          ),
        );
    }
  }
}
