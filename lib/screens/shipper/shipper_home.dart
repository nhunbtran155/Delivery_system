// lib/screens/shipper/shipper_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/login_screen.dart';
import '../common/profile_page.dart';
import '../common/settings_page.dart';

import '../shipper/available_order.dart';
import '../shipper/my_order.dart';

class ShipperHome extends StatefulWidget {
  const ShipperHome({super.key});

  @override
  State<ShipperHome> createState() => _ShipperHomeState();
}

class _ShipperHomeState extends State<ShipperHome> {
  String shipperName = "";
  bool loading = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShipperData();
  }

  // ===========================================================
  // 🔥 TẢI THÔNG TIN SHIPPER
  // ===========================================================
  Future<void> _loadShipperData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("deli_shippers")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        shipperName = doc.data()?["name"] ?? "Tài xế";
      }
    } catch (e) {
      debugPrint("Lỗi load shipper: $e");
    }

    setState(() => loading = false);
  }

  // ===========================================================
  // 🔥 ĐĂNG XUẤT
  // ===========================================================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ===========================================================
  // 🔥 TAB VIEWS
  // ===========================================================
  Widget _tabPage() {
    switch (selectedIndex) {
      case 0:
        return const AvailableOrders();
      case 1:
        return const MyOrdersPage();
      case 2:
        return const ProfilePage(role: "shipper");
      case 3:
        return const SettingsPage(role: "shipper");
      default:
        return const AvailableOrders();
    }
  }

  String get _title {
    switch (selectedIndex) {
      case 0:
        return "Xin chào, $shipperName 👋";
      case 1:
        return "Đơn của tôi";
      case 2:
        return "Hồ sơ";
      case 3:
        return "Cài đặt";
      default:
        return "";
    }
  }

  // ===========================================================
  // 🔥 UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          _title,
          style: TextStyle(
            color: isDark ? AppTheme.lightText : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Đăng xuất",
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppTheme.primaryRed),
          )
        ],
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      )
          : _tabPage(),

      // ❌ BOTTOM NAV BAR – ĐÃ BỎ TAB "LỊCH SỬ"
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
        onTap: (i) => setState(() => selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: "Đơn mới",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: "Đơn của tôi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Cá nhân",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "Cài đặt",
          ),
        ],
      ),
    );
  }
}
