import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import 'admin_home.dart';

class AdminDashboard extends StatefulWidget {
  final bool embedded;
  const AdminDashboard({super.key, this.embedded = false});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int ordersCount = 0;
  int customersCount = 0;
  int shippersCount = 0;
  double totalRevenue = 0;
  Map<String, int> statusCount = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final orders = await FirebaseFirestore.instance.collection('deli_orders').get();
    final customers = await FirebaseFirestore.instance.collection('deli_customers').get();
    final shippers = await FirebaseFirestore.instance.collection('deli_shippers').get();

    double total = 0;
    final statusMap = <String, int>{};

    for (var doc in orders.docs) {
      final order = doc.data();
      final price = (order['price'] ?? 0).toDouble();
      total += price;

      final status = order['status'] ?? 'unknown';
      statusMap[status] = (statusMap[status] ?? 0) + 1;
    }

    setState(() {
      ordersCount = orders.size;
      customersCount = customers.size;
      shippersCount = shippers.size;
      totalRevenue = total.toDouble();
      statusCount = statusMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.darkBackground : Colors.grey.shade100;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _statCard('📦 Đơn hàng', '$ordersCount', cardColor, textColor, subText),
            _statCard('👤 Khách hàng', '$customersCount', cardColor, textColor, subText),
            _statCard('🚚 Shipper', '$shippersCount', cardColor, textColor, subText),
            _statCard('💰 Doanh thu', '${totalRevenue.toStringAsFixed(0)} đ', cardColor, textColor, subText),

            const SizedBox(height: 32),
            Text(
              'Thống kê đơn hàng theo trạng thái',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (statusCount.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
            else
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                height: 300,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 45,
                    borderData: FlBorderData(show: false),
                    sections: statusCount.entries.map((e) {
                      final color = _statusColor(e.key);
                      final value = e.value.toDouble();
                      final percent = (value /
                          (statusCount.values.fold(0, (a, b) => a + b))) *
                          100;
                      return PieChartSectionData(
                        color: color,
                        value: value,
                        title:
                        '${_statusLabel(e.key)}\n${percent.toStringAsFixed(1)}%',
                        radius: 70,
                        titleStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: bgColor, child: content);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Bảng điều khiển',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
      body: content,
    );
  }

  // 🔹 Thẻ thống kê từng chỉ số (theme-aware)
  Widget _statCard(
      String label, String value, Color cardColor, Color textColor, Color subText) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(color: subText, fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔹 Màu trạng thái
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'delivering':
        return Colors.lightBlueAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'canceled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // 🔹 Nhãn hiển thị trạng thái
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'delivering':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'canceled':
        return 'Đã hủy';
      default:
        return 'Khác';
    }
  }
}
