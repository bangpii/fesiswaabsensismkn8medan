// lib/services/location_service.dart
//
// 🔥 LOCATION SERVICE — Realtime GPS untuk fitur absensi
//
// Fitur:
//   - Stream lokasi realtime (bergerak smooth saat HP bergerak)
//   - Cek apakah user dalam area sekolah (rectangle zone)
//   - Hitung jarak user ke titik tengah sekolah (dalam meter)
//   - Akurasi GPS, kecepatan, altitude
//   - Request permission otomatis
//   - 🆕 Koordinat sekolah DITARIK DARI BACKEND (tabel lokasis),
//     bukan hardcode lagi. Hardcode di bawah ini cuma FALLBACK
//     kalau API gagal/offline, supaya validasi tetap jalan.
//
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════════════════════
// MODEL LOKASI USER
// ═══════════════════════════════════════════════════════════
class UserLocation {
  final double lat;
  final double lng;
  final double accuracy;       // akurasi dalam meter
  final double? altitude;
  final double? speed;          // m/s
  final double distanceToSchool; // jarak ke pusat sekolah (meter)
  final bool isInsideZone;       // apakah dalam zona absensi
  final DateTime timestamp;

  const UserLocation({
    required this.lat,
    required this.lng,
    required this.accuracy,
    this.altitude,
    this.speed,
    required this.distanceToSchool,
    required this.isInsideZone,
    required this.timestamp,
  });

  // Jarak ke zona (0 jika sudah di dalam)
  double get distanceToZone {
    if (isInsideZone) return 0;
    return math.max(0, distanceToSchool - LocationService.schoolRadiusMeters);
  }

  // Akurasi readable
  String get accuracyReadable {
    if (accuracy <= 5) return '± ${accuracy.toStringAsFixed(0)}m (Sangat Akurat)';
    if (accuracy <= 15) return '± ${accuracy.toStringAsFixed(0)}m (Akurat)';
    if (accuracy <= 30) return '± ${accuracy.toStringAsFixed(0)}m (Cukup)';
    return '± ${accuracy.toStringAsFixed(0)}m (Kurang Akurat)';
  }

  // Kecepatan readable
  String get speedReadable {
    final kmh = (speed ?? 0) * 3.6;
    if (kmh < 1) return 'Diam';
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  // Koordinat formatted
  String get coordReadable =>
      '${lat.toStringAsFixed(6)}° N, ${lng.toStringAsFixed(6)}° E';
}

// ═══════════════════════════════════════════════════════════
// LOCATION SERVICE
// ═══════════════════════════════════════════════════════════
class LocationService {
  // ── Koordinat Area Sekolah ────────────────────────────────
  // 🆕 BUKAN const lagi — ini cuma nilai DEFAULT/FALLBACK
  // (sama persis dengan fallback di AbsensiController.php kalau
  // Lokasi::where('is_active', true)->first() == null).
  // Nilai sebenarnya akan di-override oleh loadSchoolLocation()
  // yang narik dari endpoint GET /lokasi/aktif.
  static double latMin = 3.565500;
  static double latMax = 3.567300;
  static double lngMin = 98.645900;
  static double lngMax = 98.647300;

  static String namaLokasi = 'SMKN 8 Medan';

  // 🆕 Deep link Maps sekolah — sebelumnya hardcode di
  // absensi_service.dart, sekarang ditarik dari backend juga
  // (kolom maps_url di tabel lokasis). Tetap ada fallback.
  static String mapsUrlSekolah = 'https://maps.app.goo.gl/pw9y3zJGtNeo1FG27';

  static bool _lokasiLoaded = false;
  static bool get isLokasiLoaded => _lokasiLoaded;

  // Titik tengah sekolah (dihitung otomatis dari rectangle aktif)
  static double get schoolCenterLat => (latMin + latMax) / 2;
  static double get schoolCenterLng => (lngMin + lngMax) / 2;

  // 🆕 Radius zona DIHITUNG dari rectangle backend yang sebenarnya
  // (sebelumnya hardcode 125.0 meter, sekarang otomatis menyesuaikan
  // kalau admin ganti area sekolah dari database).
  static double get schoolRadiusMeters {
    final lebar = calculateDistance(latMin, lngMin, latMin, lngMax);
    final tinggi = calculateDistance(latMin, lngMin, latMax, lngMin);
    final diagonal = math.sqrt((lebar * lebar) + (tinggi * tinggi));
    return diagonal / 2;
  }

  // ── Stream Controller ────────────────────────────────────
  static StreamController<UserLocation>? _controller;
  static StreamSubscription<Position>? _positionSubscription;
  static UserLocation? _lastLocation;

  // ── Getter ───────────────────────────────────────────────
  static UserLocation? get lastLocation => _lastLocation;

  static Stream<UserLocation>? get locationStream => _controller?.stream;

  // ═══════════════════════════════════════════════════════════
  // 🆕 AMBIL KOORDINAT SEKOLAH DARI BACKEND
  // GET /lokasi/aktif → { success, data: { lat_min, lat_max,
  //                        lng_min, lng_max, nama_lokasi, maps_url } }
  //
  // Kalau gagal (offline / endpoint belum ada / error apapun),
  // tetap pakai nilai default di atas — TIDAK akan crash app
  // dan validasi absen tetap berjalan seperti biasa.
  // ═══════════════════════════════════════════════════════════
  static Future<bool> loadSchoolLocation() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.get('/lokasi/aktif');
      final raw = response.data;

      if (raw is Map && raw['success'] == true && raw['data'] != null) {
        final d = raw['data'] as Map;

        final newLatMin = double.tryParse(d['lat_min'].toString());
        final newLatMax = double.tryParse(d['lat_max'].toString());
        final newLngMin = double.tryParse(d['lng_min'].toString());
        final newLngMax = double.tryParse(d['lng_max'].toString());

        // Validasi data sebelum dipakai — jangan sampai
        // override dengan nilai null/NaN
        if (newLatMin != null && newLatMax != null &&
            newLngMin != null && newLngMax != null) {
          latMin = newLatMin;
          latMax = newLatMax;
          lngMin = newLngMin;
          lngMax = newLngMax;

          if (d['nama_lokasi'] != null) {
            namaLokasi = d['nama_lokasi'].toString();
          }
          if (d['maps_url'] != null && d['maps_url'].toString().isNotEmpty) {
            mapsUrlSekolah = d['maps_url'].toString();
          }

          _lokasiLoaded = true;
          return true;
        }
      }
    } catch (_) {
      // Diam saja — fallback ke koordinat default di atas.
      // Validasi backend (AbsensiController) tetap jadi sumber
      // kebenaran utama saat absen beneran dikirim ke server.
    }
    return false;
  }

  // ── Request Permission ───────────────────────────────────
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false; // GPS dimatikan
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ── Cek Permission Status ─────────────────────────────────
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) return LocationPermissionStatus.denied;
    if (permission == LocationPermission.deniedForever) return LocationPermissionStatus.deniedForever;

    return LocationPermissionStatus.granted;
  }

  // ── Mulai Stream Lokasi Realtime ─────────────────────────
  // interval: seberapa sering update (default 1 detik)
  // distanceFilter: minimal jarak bergerak sebelum update (meter)
  static Future<bool> startTracking({
    int intervalMs = 1000,
    double distanceFilter = 2.0,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return false;

    await stopTracking();

    _controller = StreamController<UserLocation>.broadcast();

    // ✅ geolocator v12 pakai AndroidSettings / AppleSettings
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter.toInt(),
      intervalDuration: Duration(milliseconds: intervalMs),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Mengaktifkan lokasi untuk absensi...",
        notificationTitle: "Lokasi Aktif",
        enableWakeLock: true,
      ),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final userLocation = _buildUserLocation(position);
        _lastLocation = userLocation;

        if (!(_controller?.isClosed ?? true)) {
          _controller!.add(userLocation);
        }
      },
      onError: (error) {
        if (!(_controller?.isClosed ?? true)) {
          _controller!.addError(error);
        }
      },
    );

    return true;
  }

  // ── Ambil Posisi Sekali ──────────────────────────────────
  static Future<UserLocation?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      // ✅ geolocator v12: getCurrentPosition tanpa LocationSettings
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _buildUserLocation(position);
    } catch (e) {
      return null;
    }
  }

  // ── Stop Tracking ────────────────────────────────────────
  static Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await _controller?.close();
    _controller = null;
  }

  // ── Hitung Jarak ke Pusat Sekolah (Haversine Formula) ────
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // radius bumi dalam meter
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // ── Cek Dalam Area Rectangle Sekolah ─────────────────────
  // Sinkron 100% dengan backend PHP (sekarang sumber datanya
  // juga sama-sama dari tabel lokasis)
  static bool isInsideSchoolArea(double lat, double lng) {
    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
  }

  // ── Format Jarak ke Sekolah ───────────────────────────────
  static String formatDistance(double meters) {
    if (meters < 1) return 'Di titik absensi';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  // ── Build UserLocation dari Position ─────────────────────
  static UserLocation _buildUserLocation(Position position) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      schoolCenterLat,
      schoolCenterLng,
    );

    final inside = isInsideSchoolArea(position.latitude, position.longitude);

    return UserLocation(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed >= 0 ? position.speed : 0,
      distanceToSchool: distance,
      isInsideZone: inside,
      timestamp: position.timestamp,
    );
  }

  static double _toRad(double degree) => degree * (math.pi / 180);

  // ── Buka Pengaturan Lokasi ────────────────────────────────
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// ═══════════════════════════════════════════════════════════
// ENUM STATUS PERMISSION
// ═══════════════════════════════════════════════════════════
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}