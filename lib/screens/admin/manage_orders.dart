// lib/screens/admin/manage_orders.dart
// BẢN ĐÃ SỬA FULL – KHÔNG RÚT GỌN

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'admin_home.dart';
import '../customer/order_detail.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  String selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : Colors.grey.shade100;
    final card = isDark ? AppTheme.darkSurface : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white70 : Colors.black54;

    Query q = FirebaseFirestore.instance.collection("deli_orders");
    if (selectedStatus != 'all') {
      q = q.where("status", isEqualTo: selectedStatus);
    }

    final content = Column(
      children: [
        const SizedBox(height: 10),
        _filterChips(isDark),
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        Expanded(child: _orderList(q, isDark, card, text, sub)),
      ],
    );

    if (widget.embedded) {
      return Container(color: bg, child: content);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Quản lý đơn hàng',
          style: TextStyle(
              color: text, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryRed),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHome()),
            );
          },
        ),
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _filterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip("Tất cả", "all", isDark),
          _chip("Chờ xử lý", "pending", isDark),
          _chip("Đang giao", "delivering", isDark),
          _chip("Hoàn thành", "completed", isDark),
          _chip("Đã hủy", "canceled", isDark),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final selected = selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppTheme.primaryRed,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => selectedStatus = value),
      ),
    );
  }

  Widget _orderList(
      Query q, bool isDark, Color card, Color text, Color sub) {
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed));
        }

        var docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Không có đơn hàng nào.',
              style: TextStyle(color: sub, fontSize: 16),
            ),
          );
        }

        // 🔥 SORT MANUAL, AN TOÀN VỚI createdAt NULL HOẶC KHÔNG TỒN TẠI
        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final ta = da['createdAt'] as Timestamp?;
          final tb = db['createdAt'] as Timestamp?;

          if (ta == null && tb == null) return 0;
          if (ta == null) return 1; // đơn cũ không có createdAt cho xuống dưới
          if (tb == null) return -1;
          return tb.compareTo(ta); // mới → cũ
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final id = d.id;

            final receiver = data["receiverName"] ?? "---";
            final address = data["address"] ?? "---";
            final price = (data["price"] ?? 0).toDouble();
            final status = (data["status"] ?? "pending").toString();

            return Card(
              color: card,
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            color: AppTheme.primaryRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Mã đơn: $id",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: text,
                                fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("👤 $receiver", style: TextStyle(color: sub)),
                    Text("📍 $address", style: TextStyle(color: sub)),
                    Text("💰 ${price.toStringAsFixed(0)} đ",
                        style: TextStyle(color: text)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("Trạng thái:",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: text)),
                        const SizedBox(width: 6),
                        if (status == "canceled")
                          Chip(
                            label: const Text("Đã hủy"),
                            backgroundColor: isDark
                                ? Colors.red.shade900
                                : const Color(0xFFFFE5E5),
                            labelStyle: TextStyle(
                                color: isDark ? Colors.white : Colors.red,
                                fontWeight: FontWeight.bold),
                          )
                        else
                          DropdownButton<String>(
                            value: _statusValid(status),
                            dropdownColor: isDark
                                ? AppTheme.darkField
                                : Colors.white,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                  value: "pending",
                                  child: Text("Chờ xử lý")),
                              DropdownMenuItem(
                                  value: "delivering",
                                  child: Text("Đang giao")),
                              DropdownMenuItem(
                                  value: "completed",
                                  child: Text("Hoàn thành")),
                            ],
                            onChanged: (v) {
                              if (v != null && v != status) {
                                _updateStatus(id, v);
                              }
                            },
                          ),
                      ],
                    ),
                    Divider(
                        color: isDark ? Colors.white24 : Colors.black12,
                        height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(
                              (data["createdAt"] as Timestamp?)),
                          style: TextStyle(color: sub),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppTheme.primaryRed),
                                foregroundColor: AppTheme.primaryRed,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailPage(orderId: id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text("Chi tiết"),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDelete(id, isDark),
                            ),
                          ],
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
  }

  String _statusValid(String s) {
    if (["pending", "delivering", "completed"].contains(s)) return s;
    return "pending";
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(id)
          .update({"status": newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã cập nhật trạng thái: $newStatus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("⚠️ Lỗi: $e")));
      }
    }
  }

  Future<void> _confirmDelete(String id, bool isDark) async {
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white70 : Colors.black54;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Xóa đơn",
            style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        content: Text(
          "Bạn có chắc muốn xóa đơn này? Không thể hoàn tác.",
          style: TextStyle(color: sub),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy",
                  style: TextStyle(color: AppTheme.primaryRed))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Đã xóa đơn thành công")),
        );
      }
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "---";
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return "$dd/$mm/${d.year} $hh:$mi";
  }
}
