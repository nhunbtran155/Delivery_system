// lib/screens/common/profile_page.dart
// Hồ sơ dùng chung – phân biệt theo role: customer / shipper

import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfilePage extends StatefulWidget {
  final String role; // 'customer' | 'shipper'

  const ProfilePage({super.key, this.role = "customer"});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool loading = true;

  File? _selectedImage;
  Uint8List? _webImageBytes;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      // ✅ phân biệt collection theo role
      final collection =
      widget.role == "shipper" ? "deli_shippers" : "deli_customers";

      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .get();

      if (snap.exists) {
        userData = snap.data();
      } else {
        userData = {
          "name": user.email ?? "User",
          "email": user.email,
        };
      }
    } catch (e) {
      debugPrint("Load profile error: $e");
    }

    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      _webImageBytes = await picked.readAsBytes();
    } else {
      _selectedImage = File(picked.path);
    }
    setState(() {});
  }

  Future<void> _saveAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_selectedImage == null && _webImageBytes == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("avatars")
          .child("${user.uid}.jpg");

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(_webImageBytes!);
      } else {
        uploadTask = ref.putFile(_selectedImage!);
      }

      await uploadTask;
      final url = await ref.getDownloadURL();

      final collection =
      widget.role == "shipper" ? "deli_shippers" : "deli_customers";

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .update({"avatarUrl": url});

      userData?["avatarUrl"] = url;
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật ảnh đại diện")),
        );
      }
    } catch (e) {
      debugPrint("Save avatar error: $e");
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    final name = (userData?["name"] ?? "Người dùng").toString();
    final email = (userData?["email"] ?? "").toString();
    final phone = (userData?["phone"] ?? "").toString();
    final plate = (userData?["vehiclePlate"] ?? "").toString();
    final avatarUrl = userData?["avatarUrl"] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : null,
                child: (avatarUrl == null && _selectedImage == null)
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryRed,
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          const SizedBox(height: 12),
          if (_selectedImage != null || _webImageBytes != null)
            ElevatedButton(
              onPressed: _saveAvatar,
              child: const Text("Lưu ảnh đại diện"),
            ),
          const SizedBox(height: 16),

          // thông tin thêm
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _infoRow("Số điện thoại", phone),
                if (widget.role == "shipper") _infoRow("Biển số xe", plate),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value.isEmpty ? "---" : value),
        ],
      ),
    );
  }
}
