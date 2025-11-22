// lib/screens/shipper/order_history.dart
// LỊCH SỬ ĐƠN HÀNG (SHIPPER) – chỉ đơn của shipper hiện tại

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'shipping_order_detail.dart';

class OrderHistory extends StatelessWidget {
  const OrderHistory({super.key});

  Stream<QuerySnapshot> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    // ✅ Chỉ lấy lịch sử đơn của đúng shipper đang đăng nhập
    return FirebaseFirestore.instance
        .collection("deli_orders")
        .where("shipperId", isEqualTo: user.uid)
        .where("status", whereIn: ["completed", "canceled"])
        .orderBy("completedAt", descending: true)
        .snapshots();
  }

  Color _statusColor(String s) {
    switch (s) {
      case "completed":
        return Colors.green;
      case "canceled":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "completed":
        return "Hoàn thành";
      case "canceled":
        return "Đã hủy";
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _historyStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    "Chưa có lịch sử đơn hàng.",
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
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  final id = d.id;

                  final receiver = data["receiverName"] ?? "---";
                  final address = data["address"] ?? "---";
                  final price = (data["price"] ?? 0).toString();
                  final eta = (data["etaText"] ?? "Không tính được ETA").toString();
                  final status = (data["status"] ?? "").toString();

                  final ratingNum = (data["customerRating"] is num)
                      ? (data["customerRating"] as num).toDouble()
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                          _statusColor(status).withOpacity(0.15),
                          child: Icon(
                            status == "completed"
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _statusColor(status),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShippingOrderDetailPage(orderId: id),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receiver,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "📍 $address",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "💰 $price đ",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "⏱ $eta",
                                  style: TextStyle(
                                    color: eta.contains("Không")
                                        ? Colors.redAccent
                                        : (isDark
                                        ? Colors.white70
                                        : Colors.black54),
                                  ),
                                ),
                                if (ratingNum != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rate_rounded,
                                        size: 18,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ratingNum.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "(Đánh giá từ khách)",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(status),
                                ),
                              ),
                              backgroundColor:
                              _statusColor(status).withOpacity(0.12),
                            ),
                          ],
                        ),
                      ],
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
