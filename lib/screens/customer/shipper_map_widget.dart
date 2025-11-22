import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Widget hiển thị bản đồ Shipper + ETA + tuyến đường
class ShipperMapWidget extends StatefulWidget {
  final String shipperId;
  final LatLng? destination; // điểm giao hàng

  const ShipperMapWidget({
    super.key,
    required this.shipperId,
    this.destination,
  });

  @override
  State<ShipperMapWidget> createState() => _ShipperMapWidgetState();
}

class _ShipperMapWidgetState extends State<ShipperMapWidget> {
  LatLng? _shipperPosition;
  StreamSubscription<DatabaseEvent>? _locationSub;
  GoogleMapController? _mapController;

  Set<Polyline> _polylines = {};
  String? _eta;
  String? _weatherDesc;
  bool _loadingEta = false;

  // ============================
  // API KEY
  // ============================
  static const String GOOGLE_MAPS_API_KEY =''

  static const String OPENWEATHER_KEY =""


  @override
  void initState() {
    super.initState();
    _listenRealtimeLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ===================================================
  // 🔥 Lắng nghe vị trí realtime từ Realtime Database
  // ===================================================
  void _listenRealtimeLocation() {
    final ref = FirebaseDatabase.instance
        .ref("deli_shipperLocations/${widget.shipperId}");

    _locationSub = ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      try {
        final lat = double.tryParse(data["lat"].toString());
        final lng = double.tryParse(data["lng"].toString());

        if (lat == null || lng == null) return;

        final newPos = LatLng(lat, lng);

        setState(() => _shipperPosition = newPos);

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newPos, zoom: 15),
            ),
          );
        }

        // Shipper moving => update ETA + route
        if (widget.destination != null) {
          _calculateRouteAndETA(newPos, widget.destination!);
        }
      } catch (_) {}
    });
  }

  // ===================================================
  // 🔥 Hàm tính ETA + Polyline (FIXED)
  // ===================================================
  Future<void> _calculateRouteAndETA(LatLng from, LatLng to) async {
    try {
      setState(() => _loadingEta = true);

      final url =
          "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=${from.latitude},${from.longitude}"
          "&destination=${to.latitude},${to.longitude}"
          "&mode=driving&region=VN&language=vi"
          "&key=$GOOGLE_MAPS_API_KEY";

      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        setState(() {
          _eta = "Không tính được ETA (lỗi API)";
          _loadingEta = false;
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data["routes"] == null ||
          data["routes"].isEmpty ||
          data["routes"][0]["legs"].isEmpty) {
        setState(() {
          _eta = "Không tìm thấy lộ trình";
          _loadingEta = false;
        });
        return;
      }

      // Lấy thông tin tuyến đường
      final leg = data["routes"][0]["legs"][0];
      final durationSec = leg["duration"]?["value"] ?? 0;
      final points = data["routes"][0]["overview_polyline"]["points"];

      // Decode polyline
      final polylineCoords = _decodePolyline(points);

      // Weather API
      final weatherRes = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather"
            "?lat=${to.latitude}&lon=${to.longitude}"
            "&appid=$OPENWEATHER_KEY&units=metric&lang=vi",
      ));

      int delayMinutes = 0;
      String weatherDescription = "Trời quang";

      if (weatherRes.statusCode == 200) {
        final w = jsonDecode(weatherRes.body);
        final main = (w["weather"][0]["main"] ?? "").toLowerCase();
        weatherDescription =
            (w["weather"][0]["description"] ?? "").toString();

        if (main.contains("rain")) delayMinutes = 10;
        if (main.contains("thunderstorm")) delayMinutes = 20;
        if (main.contains("fog")) delayMinutes = 8;
      }

      final etaMinutes = (durationSec / 60).round() + delayMinutes;

      setState(() {
        _eta = "~ $etaMinutes phút";
        _weatherDesc = delayMinutes > 0
            ? "+${delayMinutes} phút ($weatherDescription)"
            : weatherDescription;

        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            width: 5,
            color: Colors.blueAccent,
            points: polylineCoords,
          ),
        };
      });

      // Auto zoom map
      if (_mapController != null && polylineCoords.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromPolyline(polylineCoords),
            70,
          ),
        );
      }
    } catch (e) {
      setState(() => _eta = "Không tính được ETA");
    } finally {
      setState(() => _loadingEta = false);
    }
  }

  // ===================================================
  // 🔍 Decode Polyline
  // ===================================================
  List<LatLng> _decodePolyline(String poly) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < poly.length) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _boundsFromPolyline(List<LatLng> list) {
    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (final p in list) {
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

  // ===================================================
  // UI
  // ===================================================
  @override
  Widget build(BuildContext context) {
    final target = _shipperPosition ?? widget.destination;

    if (target == null) {
      return const Center(child: Text("⏳ Đang tải bản đồ..."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: GoogleMap(
              initialCameraPosition:
              CameraPosition(target: target, zoom: 14),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: false,
              markers: {
                if (widget.destination != null)
                  Marker(
                    markerId: const MarkerId("destination"),
                    position: widget.destination!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                  ),
                if (_shipperPosition != null)
                  Marker(
                    markerId: const MarkerId("shipper"),
                    position: _shipperPosition!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                  ),
              },
              polylines: _polylines,
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (_loadingEta)
          const Text("🔄 Đang tính ETA...",
              style: TextStyle(color: Colors.white70))
        else if (_eta != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🕓 ETA: $_eta",
                style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              if (_weatherDesc != null)
                Text(
                  "🌦 $_weatherDesc",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
            ],
          ),
      ],
    );
  }
}
