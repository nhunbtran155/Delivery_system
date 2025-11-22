// lib/services/shipper_location_service.dart
// Upload định vị Shipper lên Firestore + hỗ trợ realtime cho Customer

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'gps_service.dart';

class ShipperLocationService {
  static final ShipperLocationService _instance =
  ShipperLocationService._internal();

  factory ShipperLocationService() => _instance;

  ShipperLocationService._internal();

  StreamSubscription? _gpsSub;
  Timer? _pushTimer;

  /// Bắt đầu dịch vụ định vị
  Future<void> start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Bắt đầu đọc GPS
    await GpsService().start();

    // Lắng nghe tọa độ từ GPS service
    _gpsSub = GpsService().onLocationChanged.listen((loc) {
      _latestLat = loc["lat"];
      _latestLng = loc["lng"];
    });

    // Cứ 4 giây đẩy lên Firebase 1 lần
    _pushTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pushToFirestore();
    });
  }

  double? _latestLat;
  double? _latestLng;

  /// Đẩy lên Firestore
  Future<void> _pushToFirestore() async {
    if (_latestLat == null || _latestLng == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("deli_shippers")
          .doc(user.uid)
          .update({
        "location": {
          "lat": _latestLat,
          "lng": _latestLng,
          "updatedAt": FieldValue.serverTimestamp(),
        }
      });
    } catch (_) {}

    /// Đồng thời lưu vào đơn đang giao
    final delivering = await FirebaseFirestore.instance
        .collection("deli_orders")
        .where("shipperId", isEqualTo: user.uid)
        .where("status", whereIn: ["accepted", "delivering"])
        .get();

    for (var d in delivering.docs) {
      await d.reference.update({
        "shipperLocation": {
          "lat": _latestLat,
          "lng": _latestLng,
          "updatedAt": FieldValue.serverTimestamp(),
        }
      });
    }
  }

  /// Stop dịch vụ định vị
  Future<void> stop() async {
    await _gpsSub?.cancel();
    _pushTimer?.cancel();
  }
}
