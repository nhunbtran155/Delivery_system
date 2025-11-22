// lib/screens/customer/order_detail.dart
// Chi tiết đơn hàng (Customer) – ETA realtime + Polyline + Bounding + Rating

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  DocumentSnapshot? orderData;
  bool loading = true;

  LatLng? shipperPos;
  LatLng? destPos;

  String? etaText;
  bool etaLoading = false;

  String? shipperName;
  String? shipperPhone;

  GoogleMapController? mapCtrl;

  Set<Polyline> _polylines = {};
  LatLngBounds? _bounds;

  double? _customerRating;
  String? _customerReview;

  static const String _functionDirectionsUrl =
      "https://us-central1-sos-prj.cloudfunctions.net/apiGetDirections";

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _listenRealtime();
  }

  // ============================================================
  // LOAD ORDER (lần đầu)
  // ============================================================
  Future<void> _loadOrder() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(widget.orderId)
          .get(const GetOptions(source: Source.server));

      if (!snap.exists) {
        setState(() {
          loading = false;
          orderData = null;
        });
        return;
      }

      orderData = snap;
      final data = snap.data() as Map<String, dynamic>;

      if (data["location"] != null) {
        final loc = data["location"] as Map<String, dynamic>;
        destPos = LatLng(
          (loc["lat"] ?? 0) * 1.0,
          (loc["lng"] ?? 0) * 1.0,
        );
      }

      if (data["shipperLocation"] != null) {
        final loc = data["shipperLocation"] as Map<String, dynamic>;
        shipperPos = LatLng(
          (loc["lat"] ?? 0) * 1.0,
          (loc["lng"] ?? 0) * 1.0,
        );
      }

      etaText = data["etaText"];

      _customerRating = (data["customerRating"] is num)
          ? (data["customerRating"] as num).toDouble()
          : null;
      _customerReview = data["customerReview"];

      await _loadShipperInfo(data["shipperId"]);

      setState(() => loading = false);

      if (shipperPos != null && destPos != null) {
        Future.delayed(const Duration(milliseconds: 300), _fetchRouteAndEta);
      }
    } catch (e) {
      debugPrint("Error load order: $e");
      setState(() => loading = false);
    }
  }

  // ============================================================
  // REALTIME shipperLocation
  // ============================================================
  void _listenRealtime() {
    FirebaseFirestore.instance
        .collection("deli_orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data["shipperLocation"] != null) {
        final loc = data["shipperLocation"] as Map<String, dynamic>;
        shipperPos = LatLng(
          (loc["lat"] ?? 0) * 1.0,
          (loc["lng"] ?? 0) * 1.0,
        );
        _fetchRouteAndEta();
      }
    });
  }

  // ============================================================
  // LẤY THÔNG TIN SHIPPER
  // ============================================================
  Future<void> _loadShipperInfo(String? shipperId) async {
    if (shipperId == null || shipperId.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("deli_shippers")
          .doc(shipperId)
          .get();
      if (snap.exists) {
        final s = snap.data()!;
        shipperName = s["name"] ?? s["email"] ?? "Shipper";
        shipperPhone = s["phone"];
      }
    } catch (_) {}
  }

  // ============================================================
  // POLYLINE + ETA REALTIME
  // ============================================================
  Future<void> _fetchRouteAndEta() async {
    if (shipperPos == null || destPos == null) return;

    setState(() => etaLoading = true);

    try {
      final uri = Uri.parse(_functionDirectionsUrl).replace(queryParameters: {
        "origin": "${shipperPos!.latitude},${shipperPos!.longitude}",
        "destination": "${destPos!.latitude},${destPos!.longitude}",
      });

      final res = await http.get(uri);
      final json = jsonDecode(res.body);

      if (json["status"] == "OK") {
        etaText = json["durationText"];

        final encoded = json["overviewPolyline"];
        if (encoded is String && encoded.isNotEmpty) {
          _applyPolyline(encoded);
        }

        // ✅ CHỈ update Firestore khi thành công
        await FirebaseFirestore.instance
            .collection("deli_orders")
            .doc(widget.orderId)
            .update({"etaText": etaText});
      } else {
        // ❌ lỗi directions – dùng fallback 20p cho màn chi tiết
        etaText = etaText ?? "20 phút";
      }
    } catch (e) {
      debugPrint("ETA error: $e");
      // ❌ lỗi network – không ghi Firestore, chỉ hiển thị 20 phút ở đây
      etaText = etaText ?? "20 phút";
    }

    if (mounted) setState(() => etaLoading = false);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> pts = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return pts;
  }

  LatLngBounds _boundsFrom(List<LatLng> pts) {
    double minLat = pts.first.latitude,
        maxLat = pts.first.latitude,
        minLng = pts.first.longitude,
        maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _applyPolyline(String encoded) {
    final pts = _decodePolyline(encoded);
    if (pts.isEmpty) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: pts,
          width: 6,
          color: Colors.blueAccent,
        )
      };
      _bounds = _boundsFrom(pts);
    });

    if (mapCtrl != null && _bounds != null) {
      Future.microtask(() {
        mapCtrl!.animateCamera(
          CameraUpdate.newLatLngBounds(_bounds!, 60),
        );
      });
    }
  }

  // ============================================================
  // ĐÁNH GIÁ ĐƠN HÀNG
  // ============================================================
  Future<void> _rateOrder() async {
    double rating = _customerRating ?? 5.0;
    final controller = TextEditingController(text: _customerReview ?? "");

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đánh giá đơn hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chọn số sao:"),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (ctx, setSt) => Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toStringAsFixed(1),
                onChanged: (v) => setSt(() => rating = v),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Nhận xét (tuỳ chọn)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Gửi đánh giá"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(widget.orderId)
          .update({
        "customerRating": rating,
        "customerReview": controller.text.trim(),
      });

      setState(() {
        _customerRating = rating;
        _customerReview = controller.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cảm ơn bạn đã đánh giá!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi lưu đánh giá: $e")),
        );
      }
    }
  }

  // ============================================================
  // STATUS COLOR (UI ONLY)
  // ============================================================
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

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    if (orderData == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy đơn")),
      );
    }

    final data = orderData!.data() as Map<String, dynamic>;
    final status = (data["status"] ?? "").toString();
    final serviceType = (data["serviceType"] ?? "Tiêu chuẩn").toString();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          "Chi tiết đơn hàng",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryRed),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== CARD: THÔNG TIN ĐƠN + SHIPPER =====
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Thông tin đơn"),
                  _row("Người nhận:", data["receiverName"]),
                  _row("SĐT:", data["receiverPhone"]),
                  _row("Địa chỉ giao:", data["address"]),
                  _row("Gói giao:", serviceType),
                  _row("Giá:", "${data["price"]} đ"),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  _title("Shipper phụ trách"),
                  _row("Tên shipper:", shipperName ?? "Đang tìm shipper"),
                  _row("SĐT shipper:", shipperPhone ?? "---"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== CARD: TRẠNG THÁI + ETA + RATING =====
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Trạng thái & ETA"),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        backgroundColor: statusColor.withOpacity(0.15),
                      ),
                      const Spacer(),
                      if (etaLoading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              etaText ?? "Đang tính ETA...",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (status == "completed")
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star_rate_rounded),
                        onPressed: _rateOrder,
                        label: Text(
                          _customerRating == null
                              ? "Đánh giá đơn hàng"
                              : "Sửa đánh giá (${_customerRating!.toStringAsFixed(1)}★)",
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== CARD: MAP =====
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Vị trí vận chuyển"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: destPos ?? const LatLng(10.8, 106.7),
                          zoom: 13,
                        ),
                        markers: {
                          if (destPos != null)
                            Marker(
                              markerId: const MarkerId("dest"),
                              position: destPos!,
                              infoWindow:
                              const InfoWindow(title: "Điểm giao"),
                            ),
                          if (shipperPos != null)
                            Marker(
                              markerId: const MarkerId("shipper"),
                              position: shipperPos!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueBlue),
                              infoWindow:
                              const InfoWindow(title: "Vị trí shipper"),
                            ),
                        },
                        polylines: _polylines,
                        onMapCreated: (c) {
                          mapCtrl = c;
                          if (_bounds != null) {
                            Future.microtask(() {
                              mapCtrl!.animateCamera(
                                CameraUpdate.newLatLngBounds(
                                    _bounds!, 60),
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? "---")),
        ],
      ),
    );
  }
}
