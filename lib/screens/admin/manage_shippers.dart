import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'admin_home.dart';

class ManageShippersPage extends StatelessWidget {
  const ManageShippersPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.darkBackground : Colors.grey.shade100;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;

    final shippersRef = FirebaseFirestore.instance.collection('deli_shippers');

    final content = StreamBuilder<QuerySnapshot>(
      stream: shippersRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Chưa có shipper nào.',
              style: TextStyle(color: subText, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '---';
            final email = data['email'] ?? '---';
            final phone = data['phone'] ?? '---';
            final approved = data['approved'] ?? false;
            final avgRating =
            (data['averageRating'] ?? 0).toDouble().toStringAsFixed(1);

            return Card(
              color: cardColor,
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        approved
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                        color:
                        approved ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        '⭐ $avgRating',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text('📧 $email', style: TextStyle(color: subText)),
                    Text('📞 $phone', style: TextStyle(color: subText)),
                    Divider(color: isDark ? Colors.white24 : Colors.black12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!approved)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Phê duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _approveShipper(context, doc.id),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side:
                            const BorderSide(color: AppTheme.primaryRed),
                            foregroundColor: AppTheme.primaryRed,
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Chi tiết'),
                          onPressed: () =>
                              _showDetailDialog(context, data, name, isDark),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded,
                              color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, doc.id, isDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (embedded) {
      return Container(color: bgColor, child: content);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        centerTitle: true,
        elevation: 1,
        title: Text(
          'Quản lý Shipper',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryRed),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHome()),
          ),
        ),
      ),
      body: SafeArea(child: content),
    );
  }

  // 🔹 Phê duyệt Shipper
  Future<void> _approveShipper(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('deli_shippers')
          .doc(id)
          .update({'approved': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã phê duyệt shipper!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('⚠️ Lỗi: $e')));
    }
  }

  // 🔹 Hiển thị chi tiết
  void _showDetailDialog(
      BuildContext context, Map<String, dynamic> data, String name, bool isDark) {
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thông tin shipper: $name',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Họ tên', data['name'], subText),
            _infoRow('Email', data['email'], subText),
            _infoRow('Số điện thoại', data['phone'], subText),
            _infoRow('Biển số xe', data['vehicleNumber'], subText),
            _infoRow('Ngày tạo', _formatDate(data['createdAt']), subText),
            _infoRow('Trạng thái',
                (data['approved'] ?? false) ? 'Đã duyệt' : 'Chờ duyệt', subText),
            _infoRow('Đánh giá TB',
                (data['averageRating'] ?? 0).toStringAsFixed(1), subText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text('$label: ${value ?? '---'}',
        style: TextStyle(color: color, fontSize: 15)),
  );

  // 🔹 Xóa Shipper
  Future<void> _confirmDelete(
      BuildContext context, String id, bool isDark) async {
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xóa shipper',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa shipper này không?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.primaryRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) _deleteShipper(context, id);
  }

  Future<void> _deleteShipper(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('deli_shippers')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('🗑️ Đã xóa shipper')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('⚠️ Lỗi: $e')));
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '---';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
