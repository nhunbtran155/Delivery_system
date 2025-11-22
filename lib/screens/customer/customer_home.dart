// lib/screens/customer/customer_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/login_screen.dart';
import '../common/profile_page.dart';
import '../common/settings_page.dart';
import 'create_order_form.dart';
import 'order_list.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  User? user;
  String customerName = "";
  bool loading = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("deli_customers")
          .doc(user!.uid)
          .get();

      customerName = snap.data()?["name"] ?? "Khách hàng";
    } catch (_) {
      customerName = "Khách hàng";
    }
    setState(() => loading = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// ================= TABS ====================
  List<Widget> get screens => [
    const CreateOrderForm(),
    const OrderList(embedded: true),
    const ProfilePage(),
    const SettingsPage(role: "customer"),   // <<< FIX CHUẨN
  ];

  /// ================= TITLE ===================
  String get title {
    switch (_currentIndex) {
      case 0:
        return "Tạo đơn hàng mới";
      case 1:
        return "Đơn hàng của tôi";
      case 2:
        return "Hồ sơ cá nhân";
      case 3:
        return "Cài đặt";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor:
        isDark ? AppTheme.darkBackground : Colors.grey.shade100,

        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          elevation: 1,
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.primaryRed),
            )
          ],
        ),

        body: loading
            ? const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryRed),
        )
            : IndexedStack(
          index: _currentIndex,
          children: screens,
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryRed,
          unselectedItemColor:
          isDark ? Colors.white70 : Colors.black54,
          backgroundColor:
          isDark ? AppTheme.darkSurface : Colors.white,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: "Tạo đơn",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              label: "Đơn hàng",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Cá nhân",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: "Cài đặt",
            ),
          ],
        ),
      ),
    );
  }
}
