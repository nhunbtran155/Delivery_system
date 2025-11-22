import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  final String role; // 'admin', 'shipper', 'customer'
  const SettingsPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final textColor = isDarkMode ? AppTheme.lightText : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardColor = isDarkMode ? AppTheme.darkSurface : Colors.white;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 400),
      data: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      curve: Curves.easeInOutCubic,
      child: Scaffold(
        backgroundColor:
        isDarkMode ? AppTheme.darkBackground : Colors.grey.shade100,

        // ❌ Bỏ AppBar để không trùng tiêu đề với CustomerHome

        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 12),

              // 🌙 Chế độ tối / sáng
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 5,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chế độ tối',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                  scale: Tween<double>(begin: 0.8, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOutCubic,
                                  )),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                            child: isDarkMode
                                ? const Icon(
                              Icons.dark_mode_rounded,
                              key: ValueKey('dark'),
                              color: Colors.amberAccent,
                            )
                                : const Icon(
                              Icons.light_mode_rounded,
                              key: ValueKey('light'),
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: isDarkMode,
                            onChanged: (val) =>
                                context.read<ThemeProvider>().toggleTheme(val),
                            activeColor: AppTheme.primaryRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 📱 Phiên bản ứng dụng
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppTheme.primaryRed),
                  title: Text(
                    'Phiên bản ứng dụng',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Delivery App v1.0.0',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 💬 Liên hệ hỗ trợ
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.support_agent_rounded,
                      color: AppTheme.primaryRed),
                  title: Text(
                    'Liên hệ hỗ trợ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Email: support@deliveryapp.com',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 👤 Thông tin vai trò người dùng
              Center(
                child: Text(
                  'Tài khoản: ${role[0].toUpperCase()}${role.substring(1)}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
