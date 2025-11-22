import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../customer/customer_home.dart';
import '../shipper/shipper_home.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userType; // 'customer' hoặc 'shipper'
  const ProfileSetupPage({super.key, required this.userType});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final vehicleController = TextEditingController();

  bool isLoading = false;

  Future<void> saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'email': user.email,
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.userType == 'customer') {
        userData['address'] = addressController.text.trim();
        await FirebaseFirestore.instance
            .collection('deli_customers')
            .doc(user.uid)
            .set(userData);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
              (route) => false,
        );
      } else {
        userData['vehicleNumber'] = vehicleController.text.trim();
        await FirebaseFirestore.instance
            .collection('deli_shippers')
            .doc(user.uid)
            .set(userData);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ShipperHome()),
              (route) => false,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thông tin thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu thông tin: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.userType == 'customer';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 1.5,
        centerTitle: true,
        title: const Text(
          'Thiết lập hồ sơ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),

        // ✅ Nút Back hợp lý — chỉ quay về trang trước, không thay đổi logic gốc
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Nếu mở trực tiếp mà không có route trước (tránh crash)
              if (widget.userType == 'shipper') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ShipperHome()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHome()),
                );
              }
            }
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // 🧭 Icon minh họa
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: AppTheme.primaryRed,
                  size: 80,
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Hoàn tất hồ sơ của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 30),

              // 🗂️ Form chính
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 👤 Họ tên
                      _buildDarkInput(
                        controller: nameController,
                        label: 'Họ và tên',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 18),

                      // 📞 Số điện thoại
                      _buildDarkInput(
                        controller: phoneController,
                        label: 'Số điện thoại',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),

                      // 🏠 Địa chỉ (customer)
                      if (isCustomer)
                        _buildDarkInput(
                          controller: addressController,
                          label: 'Địa chỉ giao hàng',
                          icon: Icons.home_outlined,
                        ),

                      // 🚲 Biển số xe (shipper)
                      if (!isCustomer)
                        _buildDarkInput(
                          controller: vehicleController,
                          label: 'Biển số xe',
                          icon: Icons.directions_bike_outlined,
                        ),

                      const SizedBox(height: 30),

                      // 🔘 Nút lưu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : saveUserInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Lưu thông tin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                'Thông tin này giúp chúng tôi phục vụ bạn tốt hơn 💬',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧩 Input field UI đồng bộ style login/register
  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: AppTheme.darkField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.2),
        ),
      ),
      validator: (value) =>
      value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    vehicleController.dispose();
    super.dispose();
  }
}
