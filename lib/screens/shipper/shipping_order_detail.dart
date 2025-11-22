// lib/screens/shipper/shipping_order_detail.dart
// Chi tiết đơn (Shipper) – Giao diện đồng bộ Customer + Admin
// Card tối, chip trạng thái, ETA bên cạnh trạng thái, map bo góc 14px

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';

class ShippingOrderDetailPage extends StatefulWidget {
  final String orderId;

  const ShippingOrderDetailPage({super.key, required this.orderId});

  @override
  State<ShippingOrderDetailPage> createState() =>
      _ShippingOrderDetailPageState();
}

class _ShippingOrderDetailPageState extends State<ShippingOrderDetailPage> {
  DocumentSnapshot? _orderDoc;
  bool _loading = true;
  bool _updating = false;

  LatLng? _pickupPos;
  LatLng? _destPos;
  LatLng? _shipperPos;

  String? _etaText;
  bool _etaLoading = false;

  GoogleMapController? _mapCtrl;
  Set<Polyline> _polylines = {};
  LatLngBounds? _bounds;

  static const String _funcUrl =
      "https://us-central1-sos-prj.cloudfunctions.net/apiGetDirections";

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _listenRealtime();
  }

  // ============================================================
  // LOAD ORDER
  // ============================================================
  Future<void> _loadOrder() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(widget.orderId)
          .get();

      if (!snap.exists) {
        setState(() {
          _loading = false;
          _orderDoc = null;
        });
        return;
      }

      _orderDoc = snap;
      final d = snap.data() as Map<String, dynamic>;

      if (d["sendLocation"] != null) {
        _pickupPos = LatLng(
          (d["sendLocation"]["lat"] ?? 0).toDouble(),
          (d["sendLocation"]["lng"] ?? 0).toDouble(),
        );
      }

      if (d["location"] != null) {
        _destPos = LatLng(
          (d["location"]["lat"] ?? 0).toDouble(),
          (d["location"]["lng"] ?? 0).toDouble(),
        );
      }

      if (d["shipperLocation"] != null) {
        _shipperPos = LatLng(
          (d["shipperLocation"]["lat"] ?? 0).toDouble(),
          (d["shipperLocation"]["lng"] ?? 0).toDouble(),
        );
      }

      _etaText = d["etaText"];

      setState(() => _loading = false);

      if (_pickupPos != null && _destPos != null) {
        Future.delayed(const Duration(milliseconds: 200), _fetchRouteAndEta);
      }
    } catch (e) {
      debugPrint("load error: $e");
      setState(() => _loading = false);
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
      final d = snap.data()!;

      if (d["shipperLocation"] != null) {
        _shipperPos = LatLng(
          (d["shipperLocation"]["lat"] ?? 0).toDouble(),
          (d["shipperLocation"]["lng"] ?? 0).toDouble(),
        );
        _fetchRouteAndEta();
      }
    });
  }

  // ============================================================
  // POLYLINE + ETA (Navigation style)
  // ============================================================
  Future<void> _fetchRouteAndEta() async {
    if (_pickupPos == null || _destPos == null) return;

    setState(() => _etaLoading = true);

    final origin = _shipperPos ?? _pickupPos!;

    final uri = Uri.parse(_funcUrl).replace(queryParameters: {
      "origin": "${origin.latitude},${origin.longitude}",
      "destination": "${_destPos!.latitude},${_destPos!.longitude}",
    });

    try {
      final res = await http.get(uri);
      final json = jsonDecode(res.body);

      if (json["status"] == "OK") {
        _etaText = json["durationText"];
        final encoded = json["overviewPolyline"];
        if (encoded != null && encoded is String && encoded.isNotEmpty) {
          _applyPolyline(encoded);
        } else {
          _buildBoundsFromMarkers();
        }
      } else {
        _etaText = _etaText ?? "20 phút";
        _buildBoundsFromMarkers();
      }

      FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(widget.orderId)
          .update({"etaText": _etaText});
    } catch (e) {
      debugPrint("route error: $e");
      _etaText = _etaText ?? "20 phút";
      _buildBoundsFromMarkers();
    }

    if (mounted) setState(() => _etaLoading = false);
  }

  // ============================================================
  // POLYLINE DECODE
  // ============================================================
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> pts = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return pts;
  }

  // ============================================================
  // NEW GOOGLE-STYLE BOUNDS (origin → dest)
  // ============================================================
  LatLngBounds _createBounds(LatLng a, LatLng b) {
    return LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
  }

  // ============================================================
  // APPLY POLYLINE (Navigation)
  // ============================================================
  void _applyPolyline(String encoded) {
    final pts = _decodePolyline(encoded);
    if (pts.isEmpty) {
      _buildBoundsFromMarkers();
      return;
    }

    final origin = _shipperPos ?? _pickupPos;
    if (origin == null || _destPos == null) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: pts,
          width: 6,
          color: Colors.blue, // Navigation blue
        )
      };
    });

    // BOUNDS CHUẨN GOOGLE
    _bounds = _createBounds(origin, _destPos!);
    _fitBounds();
  }

  // fallback bounding
  void _buildBoundsFromMarkers() {
    if (_pickupPos == null || _destPos == null) return;
    _bounds = _createBounds(_pickupPos!, _destPos!);
    _fitBounds();
  }

  // ============================================================
  // FIT BOUNDS (Google recommended)
  // ============================================================
  void _fitBounds() {
    if (_mapCtrl == null || _bounds == null) return;

    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        await _mapCtrl!.animateCamera(
          CameraUpdate.newLatLngBounds(_bounds!, 60),
        );
      } catch (e) {
        // fallback nếu map chưa sẵn sàng
        Future.delayed(const Duration(milliseconds: 300), () {
          _mapCtrl!.animateCamera(
            CameraUpdate.newLatLngZoom(_destPos!, 14),
          );
        });
      }
    });
  }

  // ============================================================
  // STATUS
  // ============================================================
  Color _statusColor(String s) {
    return {
      "pending": Colors.orangeAccent,
      "accepted": Colors.deepPurpleAccent,
      "delivering": Colors.blueAccent,
      "completed": Colors.green,
      "canceled": Colors.redAccent,
    }[s] ??
        Colors.grey;
  }

  String _statusLabel(String s) {
    return {
      "pending": "Chờ nhận",
      "accepted": "Đã nhận",
      "delivering": "Đang giao",
      "completed": "Hoàn thành",
      "canceled": "Đã hủy",
    }[s] ??
        s;
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================
  Future<void> _updateStatus(String newStatus) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      final Map<String, dynamic> update = {"status": newStatus};

      if (newStatus == "delivering") {
        (update as Map<String, dynamic>)["startDeliverAt"] = FieldValue.serverTimestamp();
      } else if (newStatus == "completed") {
        (update as Map<String, dynamic>)["completedAt"] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection("deli_orders")
          .doc(widget.orderId)
          .update(update);

      await _loadOrder();
    } catch (e) {
      debugPrint("update status error: $e");
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _buildActionButton(String status) {
    if (status == "accepted") {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: _updating ? null : () => _updateStatus("delivering"),
        icon: const Icon(Icons.play_arrow),
        label: Text(_updating ? "Đang xử lý..." : "Bắt đầu giao"),
      );
    }

    if (status == "delivering") {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: _updating ? null : () => _updateStatus("completed"),
        icon: const Icon(Icons.check_circle),
        label: Text(_updating ? "Đang xử lý..." : "Hoàn thành đơn"),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      );
    }

    if (_orderDoc == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy đơn hàng")),
      );
    }

    final d = _orderDoc!.data() as Map<String, dynamic>;
    final status = d["status"];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Chi tiết đơn"),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.primaryRed),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= CARD 1: Thông tin đơn =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Thông tin đơn"),
                  _row("Người nhận:", d["receiverName"]),
                  _row("SĐT:", d["receiverPhone"]),
                  _row("Địa chỉ lấy:", d["sendAddress"]),
                  _row("Địa chỉ giao:", d["address"]),
                  _row("Giá:", "${d["price"]} đ"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= CARD 2: Trạng thái + ETA =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Trạng thái & ETA"),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        backgroundColor:
                        _statusColor(status).withOpacity(0.15),
                        label: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _etaLoading
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                        _etaText ?? "Đang tính ETA...",
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildActionButton(status),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= CARD 3: MAP =================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Bản đồ vận chuyển"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 310,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _pickupPos ?? const LatLng(10.8, 106.7),
                          zoom: 13,
                        ),
                        markers: {
                          if (_pickupPos != null)
                            Marker(
                              markerId: const MarkerId("pickup"),
                              position: _pickupPos!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueBlue),
                              infoWindow:
                              const InfoWindow(title: "Điểm lấy hàng"),
                            ),
                          if (_destPos != null)
                            Marker(
                              markerId: const MarkerId("dest"),
                              position: _destPos!,
                              infoWindow:
                              const InfoWindow(title: "Điểm giao"),
                            ),
                        },
                        polylines: _polylines,
                        onMapCreated: (c) {
                          _mapCtrl = c;
                          if (_bounds != null) {
                            _fitBounds();
                          } else {
                            _buildBoundsFromMarkers();
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

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _row(String label, String? value) => Padding(
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
