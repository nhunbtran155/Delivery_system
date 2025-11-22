// lib/screens/shipper/shipper_order_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'shipping_order_detail.dart';

class ShipperOrderListPage extends StatefulWidget {
  const ShipperOrderListPage({super.key});

  @override
  State<ShipperOrderListPage> createState() => _ShipperOrderListPageState();
}

class _ShipperOrderListPageState extends State<ShipperOrderListPage> {
  User? shipper;
  String _filter = "pending"; // mặc định là chờ nhận

  @override
  void initState() {
    super.initState();
    shipper = FirebaseAuth.instance.currentUser;
  }

  // ======================================================
  // 🔥 STREAM CHUẨN — KHÔNG ORDERBY
  // ======================================================
  Stream<QuerySnapshot> _orderStream() {
    final uid = shipper?.uid;
    if (uid == null) return const Stream.empty();

    Query q = FirebaseFirestore.instance.collection("deli_orders");

    if (_filter == "pending") {
      q = q.where("status", isEqualTo: "pending");
    } else {
      q = q.where("shipperId", isEqualTo: uid);
      q = q.where("status", isEqualTo: _filter);
    }

    return q.snapshots();
  }

  // ======================================================
  // 🔥 UI STATUS
  // ======================================================
  Color _color(String s) {
    return switch (s) {
      "pending" => Colors.orangeAccent,
      "accepted" => Colors.deepPurpleAccent,
      "delivering" => Colors.blueAccent,
      "completed" => Colors.green,
      "canceled" => Colors.red,
      _ => Colors.grey,
    };
  }

  String _label(String s) {
    return switch (s) {
      "pending" => "Chờ nhận",
      "accepted" => "Đã nhận",
      "delivering" => "Đang giao",
      "completed" => "Hoàn thành",
      "canceled" => "Đã hủy",
      _ => "Không rõ",
    };
  }

  IconData _icon(String s) {
    return switch (s) {
      "pending" => Icons.hourglass_bottom,
      "accepted" => Icons.assignment_turned_in,
      "delivering" => Icons.delivery_dining,
      "completed" => Icons.check_circle,
      "canceled" => Icons.cancel,
      _ => Icons.help_outline,
    };
  }

  // ======================================================
  // 🔥 FILTER BUTTON (ĐỒNG BỘ STYLE VỚI CUSTOMER)
  // ======================================================
  Widget _filterBtn(String value, String label, Color color, bool isDark) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: Icon(
          _icon(value),
          size: 18,
          color: selected ? Colors.white : color,
        ),
        selectedColor: color,
        backgroundColor:
        isDark ? AppTheme.darkSurface : Colors.grey.shade200,
        labelStyle: TextStyle(color: selected ? Colors.white : color),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  // ======================================================
  // 🔥 BUILD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : Colors.grey.shade100,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          "Đơn hàng của tôi",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryRed),
      ),

      body: Column(
        children: [
          // -------- Filter ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterBtn("pending", "Chờ nhận", Colors.orangeAccent, isDark),
                _filterBtn("accepted", "Đã nhận", Colors.deepPurpleAccent, isDark),
                _filterBtn("delivering", "Đang giao", Colors.blueAccent, isDark),
                _filterBtn("completed", "Hoàn thành", Colors.green, isDark),
                _filterBtn("canceled", "Đã hủy", Colors.red, isDark),
              ],
            ),
          ),

          // -------- LIST -------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _orderStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(color: AppTheme.primaryRed),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Lỗi tải dữ liệu"));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("Không có đơn nào"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final id = docs[i].id;
                    final data = docs[i].data() as Map<String, dynamic>;

                    final status = (data["status"] ?? "pending").toString();
                    final color = _color(status);
                    final eta =
                    (data["etaText"] ?? "Đang tính ETA...").toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            color: color.withOpacity(0.2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(
                              _icon(status),
                              color: color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ------ TAP TO DETAIL ------
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShippingOrderDetailPage(
                                      orderId: id,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["receiverName"] ?? "---",
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "📍 ${data["address"] ?? "---"}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "💰 ${data["price"] ?? 0} đ",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "⏱ $eta",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Column(
                            children: [
                              Chip(
                                backgroundColor: color.withOpacity(0.15),
                                label: Text(
                                  _label(status),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildActionButton(status, id),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // ======================================================
  // 🔥 BUTTON CHO SHIPPER
  // ======================================================
  Widget _buildActionButton(String status, String id) {
    if (status == "pending") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShippingOrderDetailPage(orderId: id),
            ),
          );
        },
        child: const Text("Nhận đơn"),
      );
    }

    if (status == "delivering" || status == "accepted") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShippingOrderDetailPage(orderId: id),
            ),
          );
        },
        child: const Text("Xử lý"),
      );
    }

    if (status == "completed") {
      return const Text(
        "Đã hoàn thành",
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      );
    }

    return const SizedBox.shrink();
  }
}
