// lib/screens/customer/order_list.dart
// FULL — Customer xem toàn bộ đơn theo customerId, đồng bộ chuẩn sendAddress/sendLocation

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'order_detail.dart';
import '../../core/theme/app_theme.dart';

class OrderList extends StatefulWidget {
  final String? statusFilter;
  final bool embedded;

  const OrderList({super.key, this.statusFilter, this.embedded = true});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  final Set<String> _cancelingIds = {};
  User? _user;
  String? _chipFilter;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _chipFilter = widget.statusFilter;
  }

  // =====================================================
  // 🔥 STREAM ĐƠN HÀNG CỦA CUSTOMER (KHÔNG BAO GIỜ MẤT ĐƠN)
  // =====================================================
  Stream<QuerySnapshot> _orderStream() {
    if (_user == null) return const Stream.empty();

    Query q = FirebaseFirestore.instance
        .collection('deli_orders')
        .where('customerId', isEqualTo: _user!.uid)
        .orderBy('createdAt', descending: true);

    if (_chipFilter != null &&
        ['pending', 'accepted', 'delivering', 'completed', 'canceled']
            .contains(_chipFilter)) {
      q = q.where('status', isEqualTo: _chipFilter);
    }

    return q.snapshots();
  }

  // =====================================================
  // 🔥 HỦY ĐƠN
  // =====================================================
  Future<void> _cancelOrder(String orderId) async {
    final reason = await _askReason(context);
    if (reason == null) return;

    setState(() => _cancelingIds.add(orderId));

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref =
        FirebaseFirestore.instance.collection('deli_orders').doc(orderId);

        final snap = await tx.get(ref);
        if (!snap.exists) throw "Không tìm thấy đơn";

        final data = snap.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();

        if (status != 'pending') {
          throw "Chỉ hủy được đơn CHỜ NHẬN";
        }

        tx.update(ref, {
          'status': 'canceled',
          'canceledAt': FieldValue.serverTimestamp(),
          'canceledBy': 'customer',
          'canceledReason': reason,
          'shipperId': null,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("🗑️ Đã hủy đơn")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ $e")));
    } finally {
      if (mounted) setState(() => _cancelingIds.remove(orderId));
    }
  }

  Future<String?> _askReason(BuildContext ctx) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Hủy đơn hàng"),
        content: TextField(
          controller: controller,
          decoration:
          const InputDecoration(labelText: "Lý do (không bắt buộc)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Không")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Xác nhận")),
        ],
      ),
    );

    return ok == true ? controller.text.trim() : null;
  }

  // =====================================================
  // 🔥 STATUS COLOR, LABEL, ICON
  // =====================================================
  Color _statusColor(String s) {
    return {
      'pending': Colors.orangeAccent,
      'accepted': Colors.deepPurpleAccent,
      'delivering': Colors.blueAccent,
      'completed': Colors.green,
      'canceled': Colors.red,
    }[s] ?? Colors.grey;
  }

  String _statusLabel(String s) {
    return {
      'pending': "Chờ nhận",
      'accepted': "Đã nhận",
      'delivering': "Đang giao",
      'completed': "Hoàn thành",
      'canceled': "Đã hủy",
    }[s] ?? s;
  }

  IconData _statusIcon(String s) {
    return {
      'pending': Icons.hourglass_empty,
      'accepted': Icons.assignment_turned_in,
      'delivering': Icons.delivery_dining,
      'completed': Icons.check_circle,
      'canceled': Icons.cancel,
    }[s] ?? Icons.help_outline;
  }

  // =====================================================
  // 🔥 UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = Column(
      children: [
        const SizedBox(height: 8),
        _buildFilterChips(isDark),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _orderStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                  CircularProgressIndicator(color: AppTheme.primaryRed),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    "Không có đơn nào.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;

                  final status = (data['status'] ?? 'pending').toString();

                  return _orderCard(
                    id: id,
                    data: data,
                    isDark: isDark,
                    status: status,
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        centerTitle: true,
        title: Text(
          "Đơn hàng",
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryRed),
      ),
      body: body,
    );
  }

  Widget _orderCard({
    required String id,
    required Map<String, dynamic> data,
    required bool isDark,
    required String status,
  }) {
    final color = _statusColor(status);
    final eta = (data["etaText"] ?? "Đang tính ETA...").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(_statusIcon(status), color: color, size: 26),
          ),
          const SizedBox(width: 12),

          // ================== TAP TO VIEW DETAIL ==================
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailPage(orderId: id),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['receiverName'] ?? "---",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "📍 ${data['address'] ?? '---'}",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    "💰 ${(data['price'] ?? 0)} đ",
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "⏱ $eta",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              Chip(
                label: Text(
                  _statusLabel(status),
                  style: TextStyle(color: color),
                ),
                backgroundColor: color.withOpacity(0.15),
              ),

              if (status == 'pending')
                OutlinedButton(
                  onPressed: _cancelingIds.contains(id)
                      ? null
                      : () => _cancelOrder(id),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  child: _cancelingIds.contains(id)
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  // =====================================================
  // FILTER CHIPS
  // =====================================================
  Widget _buildFilterChips(bool isDark) {
    final chips = <String, String?>{
      "Tất cả": null,
      "Chờ nhận": "pending",
      "Đã nhận": "accepted",
      "Đang giao": "delivering",
      "Hoàn thành": "completed",
      "Đã hủy": "canceled",
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: chips.entries.map((e) {
          final selected = _chipFilter == e.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.key),
              selected: selected,
              selectedColor: AppTheme.primaryRed,
              backgroundColor:
              isDark ? AppTheme.darkSurface : Colors.grey.shade200,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.primaryRed,
              ),
              onSelected: (_) {
                setState(() => _chipFilter = e.value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
