import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail.dart';

class OrderListDark extends StatefulWidget {
  final String? statusFilter;

  const OrderListDark({super.key, this.statusFilter});

  @override
  State<OrderListDark> createState() => _OrderListDarkState();
}

class _OrderListDarkState extends State<OrderListDark> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.statusFilter;
  }

  Stream<QuerySnapshot> _orderStream() {
    if (user == null) return const Stream.empty();

    Query base = FirebaseFirestore.instance
        .collection('deli_orders')
        .where('customerId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true);

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      base = base.where('status', isEqualTo: _statusFilter);
    }
    return base.snapshots();
  }

  // màu chip trạng thái
  Map<String, Color> statusColors = {
    'pending': Colors.amberAccent,
    'delivering': Colors.lightBlueAccent,
    'completed': Colors.greenAccent,
    'canceled': Colors.redAccent,
  };

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Chờ nhận';
      case 'delivering':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'canceled':
        return 'Đã hủy';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1C),
        elevation: 6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF2A0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildOrderSummary(),
            const SizedBox(height: 8),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _orderStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Colors.redAccent,
                    ));
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('⚠️ Lỗi tải dữ liệu',
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  final orders = snapshot.data?.docs ?? [];
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có đơn hàng nào',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final doc = orders[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final receiver = data['receiverName'] ?? 'Khách hàng';
                      final address = data['address'] ?? 'Không có địa chỉ';
                      final price = (data['price'] ?? 0).toString();
                      final status = (data['status'] ?? 'unknown').toString();

                      final statusColor =
                          statusColors[status] ?? Colors.white70;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor,
                            child: const Icon(Icons.local_shipping_rounded,
                                color: Colors.black),
                          ),
                          title: Text(
                            receiver,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('📍 $address',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text('💰 $price đ',
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.8),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailPage(orderId: doc.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Bộ lọc chip trạng thái
  Widget _buildFilterChips() {
    final items = [
      {'label': 'Tất cả', 'value': null},
      {'label': 'Chờ nhận', 'value': 'pending'},
      {'label': 'Đang giao', 'value': 'delivering'},
      {'label': 'Hoàn thành', 'value': 'completed'},
      {'label': 'Đã hủy', 'value': 'canceled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                selected: _statusFilter == item['value'],
                label: Text(item['label']!),
                selectedColor: Colors.redAccent,
                backgroundColor: Colors.grey[850],
                labelStyle: TextStyle(
                  color: _statusFilter == item['value']
                      ? Colors.white
                      : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    setState(() => _statusFilter = item['value']),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Tổng quan đơn hàng (thanh đếm)
  Widget _buildOrderSummary() {
    final List<Map<String, dynamic>> summaries = [
      {'label': 'Tổng đơn', 'icon': Icons.list_alt, 'color': Colors.redAccent},
      {'label': 'Đang giao', 'icon': Icons.local_shipping, 'color': Colors.blue},
      {'label': 'Hoàn thành', 'icon': Icons.check_circle, 'color': Colors.green},
      {'label': 'Đã hủy', 'icon': Icons.cancel, 'color': Colors.grey},
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deli_orders')
          .where('customerId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final delivering =
            docs.where((d) => d['status'] == 'delivering').length;
        final completed =
            docs.where((d) => d['status'] == 'completed').length;
        final canceled = docs.where((d) => d['status'] == 'canceled').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _summaryBox('Tổng đơn', total, Colors.redAccent),
            _summaryBox('Đang giao', delivering, Colors.blueAccent),
            _summaryBox('Hoàn thành', completed, Colors.greenAccent),
            _summaryBox('Đã hủy', canceled, Colors.grey),
          ],
        );
      },
    );
  }

  Widget _summaryBox(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
