// lib/screens/admin/admin_home.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/login_screen.dart';
import '../common/settings_page.dart';
import 'manage_orders.dart';
import 'manage_customers.dart';
import 'manage_shippers.dart';
import 'admin_dashboard.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  late final String _adminName;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email ?? 'admin@app.com';
    _adminName = email.split('@').first;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  /// 🏷️ Tiêu đề AppBar theo tab hiện tại
  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'Quản lý đơn hàng';
      case 1:
        return 'Quản lý khách hàng';
      case 2:
        return 'Quản lý shipper';
      case 3:
        return 'Bảng điều khiển';
      case 4:
        return 'Cài đặt';
      default:
        return 'Xin chào, $_adminName 👋';
    }
  }

  /// 📱 Danh sách các tab (embed = true để không tạo Scaffold lồng)
  List<Widget> get _tabs => const [
    ManageOrdersPage(embedded: true),
    ManageCustomersPage(embedded: true),
    ManageShippersPage(embedded: true),
    AdminDashboard(embedded: true),
    SettingsPage(role: 'admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 400),
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      curve: Curves.easeInOutCubic,
      child: Scaffold(
        backgroundColor:
        isDark ? AppTheme.darkBackground : Colors.grey.shade100,

        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          automaticallyImplyLeading: false,
          elevation: 1,
          centerTitle: true,
          title: Text(
            _title,
            style: TextStyle(
              color: isDark ? AppTheme.lightText : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: _logout,
              icon: const Icon(
                Icons.logout_rounded,
                color: AppTheme.primaryRed,
              ),
            ),
          ],
        ),

        /// === BODY: giữ state từng tab bằng IndexedStack ===
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          color: isDark ? AppTheme.darkBackground : Colors.grey.shade50,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IndexedStack(
              index: _selectedIndex,
              children: _tabs,
            ),
          ),
        ),

        // === ⚙️ Thanh điều hướng dưới cùng ===
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            selectedItemColor: AppTheme.primaryRed,
            unselectedItemColor:
            isDark ? Colors.white70 : Colors.black54,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Đơn hàng',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                activeIcon: Icon(Icons.people_alt_rounded),
                label: 'Khách hàng',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping_rounded),
                label: 'Shipper',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
