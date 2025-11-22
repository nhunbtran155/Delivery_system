import 'package:delivery_app/screens/auth/setup_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscure = true;
  bool loading = false;

  static const String webVapidKey =
      'BJYaeZ246HDeNX8TGwzzPJh2rAB4rZTia2HoxuVG806rfdpytVn_lHhWBblZPpfnQEvDWo9QQvgsnmw_Hs59pxA';

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw FirebaseAuthException(
          code: 'timeout',
          message: 'Kết nối chậm. Vui lòng thử lại.',
        );
      });

      final uid = cred.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('deli_users')
          .doc(uid)
          .get();
      final role = (userDoc.data()?['role'] ?? 'customer') as String;

      final customerSnap = await FirebaseFirestore.instance
          .collection('deli_customers')
          .doc(uid)
          .get();
      final shipperSnap = await FirebaseFirestore.instance
          .collection('deli_shippers')
          .doc(uid)
          .get();

      if (!customerSnap.exists && !shipperSnap.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileSetupPage(userType: role)),
        );
        return;
      }

      // 🔔 Lấy token FCM
      String? token;
      final messaging = FirebaseMessaging.instance;
      if (kIsWeb) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
        token = await messaging.getToken(vapidKey: webVapidKey);
      } else {
        token = await messaging.getToken();
      }

      debugPrint('🔔 FCM Token: $token');

      if (role == 'customer') {
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('deli_customers')
              .doc(uid)
              .update({'fcmToken': token});
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/customer');
      } else if (role == 'shipper') {
        if (!(shipperSnap.data()?['approved'] == true)) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản shipper đang chờ phê duyệt.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('deli_shippers')
              .doc(uid)
              .update({'fcmToken': token});
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/shipper');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ Login error → ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Lỗi đăng nhập')),
        );
      }
    } catch (e) {
      debugPrint('🔥 Login unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF565656), // 🌫 Nền xám nhẹ Deliverzler-style
      body: Stack(
        children: [
          // 🖼 Nền họa tiết login_background.png
          Positioned.fill(
            child: Image.asset(
              'assets/imagesnhung/login/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              opacity: const AlwaysStoppedAnimation(0.25),
            ),
          ),

          // 🌟 Nội dung chính
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🛵 Logo / minh họa
                  Image.asset(
                    'assets/imagesnhung/core/app_logo.png',
                    height: 180,
                  ),
                  const SizedBox(height: 20),

                  // 🚀 Tên ứng dụng
                  const Text(
                    'Delivery',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF2F2F2),
                      fontFamily: 'Poppins',
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 👋 Chào mừng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Chào mừng bạn trở lại ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Image.asset(
                        'assets/imagesnhung/login/hi_hand.png',
                        height: 60, // 👋 To hơn chữ
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ✉️ Email
                  _buildInputField(
                    controller: emailCtrl,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // 🔒 Password
                  _buildInputField(
                    controller: passCtrl,
                    hint: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    obscure: obscure,
                    suffix: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔁 Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ForgotPasswordDialog(),
                        );
                      },
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔘 Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCA4746),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // 🟢 bo góc iOS style
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🟢 Google Sign-in
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/imagesnhung/login/google.png',
                      height: 22,
                      width: 22,
                    ),
                    label: const Text(
                      'Đăng nhập bằng Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      backgroundColor: const Color(0xFF2A2A2C),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 👤 Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(
                            color: Color(0xFFCA4746),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📦 Custom input field builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF38383A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffix,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// 🧩 Forgot Password Dialog
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> resetPassword() async {
    if (emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi email khôi phục mật khẩu!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Lỗi gửi email khôi phục')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2C),
      title: const Text(
        'Khôi phục mật khẩu',
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'Nhập email đăng ký',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFCA4746)),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: loading ? null : resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCA4746),
          ),
          child: loading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Gửi'),
        ),
      ],
    );
  }
}
