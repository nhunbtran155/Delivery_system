// lib/screens/shipper/my_order.dart
// Đơn của tôi (Shipper) – chuẩn hóa theo sendAddress/sendLocation

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'shipping_order_detail.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _statusFilter;
  bool _updating = false;

  Stream<QuerySnapshot> _ordersStream() {
    if (_user == null) return const Stream.empty();

    Query q = FirebaseFirestore.instance
        .collection('deli_orders')
        .where('shipperId', isEqualTo: _user!.uid)
        .orderBy('createdAt', descending: true);

    if (_statusFilter != null &&
        ['accepted', 'delivering', 'completed', 'canceled']
            .contains(_statusFilter)) {
      q = q.where('status', isEqualTo: _statusFilter);
    }
    return q.snapshots();
  }

  Color _statusColor(String s) {
    return {
      'accepted': Colors.deepPurpleAccent,
      'delivering': Colors.blueAccent,
      'completed': Colors.green,
      'canceled': Colors.red,
    }[s] ?? Colors.grey;
  }

  String _statusLabel(String s) {
    return {
      'accepted': "Đã nhận",
      'delivering': "Đang giao",
      'completed': "Hoàn thành",
      'canceled': "Đã hủy",
    }[s] ?? s;
  }

  Future<void> _updateStatus(String orderId, String to) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      await FirebaseFirestore.instance
          .collection('deli_orders')
          .doc(orderId)
          .update({
        'status': to,
        if (to == 'delivering') 'startDeliverAt': FieldValue.serverTimestamp(),
        if (to == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _buildFilter(bool isDark) {
    final chips = <String, String?>{
      "Tất cả": null,
      "Đã nhận": "accepted",
      "Đang giao": "delivering",
      "Hoàn thành": "completed",
      "Đã hủy": "canceled",
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: chips.entries.map((e) {
          final selected = _statusFilter == e.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.key),
              selected: selected,
              selectedColor: AppTheme.primaryRed,
              backgroundColor:
              isDark ? AppTheme.darkSurface : Colors.grey.shade200,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.primaryRed),
              onSelected: (_) => setState(() => _statusFilter = e.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionButton(String status, String orderId) {
    if (status == 'accepted') {
      return ElevatedButton(
        onPressed: _updating ? null : () => _updateStatus(orderId, 'delivering'),
        style:
        ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
        child: const Text("Bắt đầu giao"),
      );
    }
    if (status == 'delivering') {
      return ElevatedButton(
        onPressed: _updating ? null : () => _updateStatus(orderId, 'completed'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text("Hoàn thành"),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          border: Border.all(color: _statusColor(status)),
          borderRadius: BorderRadius.circular(20)),
      child: Text(_statusLabel(status),
          style: TextStyle(color: _statusColor(status))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildFilter(isDark),
        Expanded(
          child: StreamBuilder(
            stream: _ordersStream(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryRed));
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Chưa có đơn nào."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final dt = d.data() as Map<String, dynamic>;

                  final receiver = dt["receiverName"] ?? "---";
                  final address = dt["address"] ?? "---";
                  final price = dt["price"]?.toString() ?? "0";
                  final eta = dt["etaText"] ?? "Đang tính ETA...";
                  final status = dt["status"] ?? "accepted";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),

                      // 🔥 FIX GIAO DIỆN: nền trắng cho light mode
                      color: isDark
                          ? AppTheme.darkSurface
                          : Colors.white,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ShippingOrderDetailPage(orderId: d.id)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                            _statusColor(status).withOpacity(0.12),
                            child: Icon(
                              status == "completed"
                                  ? Icons.check_circle
                                  : Icons.delivery_dining,
                              color: _statusColor(status),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    receiver,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "📍 $address",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                  Text(
                                    "💰 $price đ",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent),
                                  ),
                                  Text(
                                    "⏱ $eta",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black45),
                                  ),
                                ],
                              )),
                          _actionButton(status, d.id),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
