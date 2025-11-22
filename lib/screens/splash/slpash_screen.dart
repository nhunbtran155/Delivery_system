import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _fadeController;
  late final AnimationController _shineController;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Xe chạy vào
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Hiệu ứng fade
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Ánh sáng quét qua chữ
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _animController.forward();
    await Future.delayed(const Duration(seconds: 2));
    await _fadeController.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _fadeController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF565656), // 🌫 Nền xám đậm
      body: Stack(
        children: [
          // Viền đỏ cong bên trái
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: size.width * 0.20, // Giữ mảnh như hình 1
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.elliptical(220, 500),
                  bottomRight: Radius.elliptical(220, 500),
                ),
              ),
            ),
          ),

          // Viền đỏ cong bên phải
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: size.width * 0.20,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(220, 500),
                  bottomLeft: Radius.elliptical(220, 500),
                ),
              ),
            ),
          ),

          // Xe + điện thoại animation
          Center(
            child: SlideTransition(
              position: _slideAnim,
              child: Lottie.asset(
                'assets/imagesnhung/core/custom_splash_animation.json',
                width: size.width * 0.55, // 📱🚚 To hơn một chút
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Tiêu đề Delivery với ánh sáng quét
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(_fadeController),
            child: Align(
              alignment: const Alignment(0, 0.65),
              child: AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      final gradientPosition =
                          _shineController.value * bounds.width * 2;
                      return LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white,
                          Colors.white.withOpacity(0.1)
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(-1 - gradientPosition, 0),
                        end: Alignment(1 - gradientPosition, 0),
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: const Text(
                      'Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
