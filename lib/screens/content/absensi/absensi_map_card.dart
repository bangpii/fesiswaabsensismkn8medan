// lib/screens/content/absensi/absensi_map_card.dart
//
// 🗺️ ABSENSI MAP CARD — Google Maps (real, sesuai Google Cloud API key)
//
// Fitur:
//   ✅ Peta sungguhan Google Maps (sesuai API key di AndroidManifest.xml)
//   ✅ Koordinat sekolah DITARIK DARI BACKEND (LocationService → /lokasi/aktif)
//   ✅ Lokasi user realtime (marker bergerak saat HP bergerak)
//   ✅ Marker sekolah & user ukuran STANDAR (tidak kebesaran)
//   ✅ Zona sekolah digambar PERSEGI PANJANG (Polygon) sesuai
//      lat_min/lat_max/lng_min/lng_max dari database — BUKAN lingkaran radius
//   ✅ Garis rute dari user → sekolah (via OSRM API, gratis)
//   ✅ Jarak & estimasi waktu jalan kaki akurat dari routing
//   ✅ Status "Dalam Zona" / "Luar Zona" otomatis
//   ✅ Fullscreen view
//
// ⚠️ Logika validasi absen (camera/barcode) TIDAK ada di file ini —
//    itu murni ditangani backend (AbsensiController.php) & TIDAK diubah.
//
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'absensi_models.dart';
import '../../../services/location_service.dart';

// ═══════════════════════════════════════════════════════════
// ROUTING RESULT MODEL
// ═══════════════════════════════════════════════════════════
class _RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const _RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceReadable {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get durationReadable {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '~$minutes menit Naik Kendaraan';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return '~$hours jam $rem menit';
  }
}

// ═══════════════════════════════════════════════════════════
// HASIL GENERATE MARKER ICON: bitmap + anchor yang presisi
// ═══════════════════════════════════════════════════════════
class _MarkerIcon {
  final BitmapDescriptor bitmap;
  final Offset anchor; // posisi titik koordinat sebenarnya di dalam gambar (0..1)

  const _MarkerIcon({required this.bitmap, required this.anchor});
}

// ═══════════════════════════════════════════════════════════
// HELPER — Generate marker icon custom (lingkaran kecil + icon + label)
// Ukuran dibuat STANDAR (sebesar pin biasa), tidak kebesaran.
// Anchor dihitung presis di titik tengah lingkaran (bukan tengah
// keseluruhan gambar), supaya posisi pin di peta akurat.
// ═══════════════════════════════════════════════════════════
Future<_MarkerIcon> _buildMarkerBitmap({
  required Color color,
  required IconData icon,
  required String label,
}) async {
  const double circleSize = 56;    // ukuran lingkaran — standar, tidak besar
  const double iconFontSize = circleSize * 0.5;
  const double labelFontSize = 13;
  const double labelPaddingH = 9;
  const double labelPaddingV = 4;
  const double gap = 3; // jarak lingkaran ke label

  // ── Hitung ukuran label dulu ───────────────────────────
  final labelPainter = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: labelFontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    )
    ..layout();

  final labelBoxWidth = labelPainter.width + (labelPaddingH * 2);
  final labelBoxHeight = labelPainter.height + (labelPaddingV * 2);

  final canvasWidth = labelBoxWidth > circleSize ? labelBoxWidth : circleSize;
  final canvasHeight = circleSize + gap + labelBoxHeight;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
  );

  final circleCenter = Offset(canvasWidth / 2, circleSize / 2);
  final circleRadius = (circleSize / 2) - 3;

  // ── Shadow tipis ───────────────────────────────────────
  canvas.drawCircle(
    circleCenter.translate(0, 1.5),
    circleRadius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5),
  );

  // ── Lingkaran utama ────────────────────────────────────
  canvas.drawCircle(circleCenter, circleRadius, Paint()..color = color);

  // ── Border putih tipis ──────────────────────────────────
  canvas.drawCircle(
    circleCenter,
    circleRadius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white,
  );

  // ── Icon di tengah lingkaran ─────────────────────────────
  final iconPainter = TextPainter(textDirection: TextDirection.ltr);
  iconPainter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: iconFontSize,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: Colors.white,
    ),
  );
  iconPainter.layout();
  iconPainter.paint(
    canvas,
    circleCenter - Offset(iconPainter.width / 2, iconPainter.height / 2),
  );

  // ── Label pill di bawah lingkaran ───────────────────────
  final labelRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      (canvasWidth - labelBoxWidth) / 2,
      circleSize + gap,
      labelBoxWidth,
      labelBoxHeight,
    ),
    Radius.circular(labelBoxHeight / 2),
  );
  canvas.drawRRect(labelRect, Paint()..color = color);
  labelPainter.paint(
    canvas,
    Offset(
      (canvasWidth - labelPainter.width) / 2,
      circleSize + gap + labelPaddingV,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasWidth.ceil(), canvasHeight.ceil());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  // 🆕 Anchor presisi: titik koordinat = tengah lingkaran,
  // bukan tengah seluruh gambar (yang sudah termasuk label di bawah).
  final anchor = Offset(0.5, (circleSize / 2) / canvasHeight);

  return _MarkerIcon(
    bitmap: BitmapDescriptor.bytes(byteData!.buffer.asUint8List()),
    anchor: anchor,
  );
}

// ═══════════════════════════════════════════════════════════
// ABSENSI MAP CARD (Widget utama)
// ═══════════════════════════════════════════════════════════
class AbsensiMapCard extends StatefulWidget {
  final StatusAbsensi statusHariIni;

  const AbsensiMapCard({super.key, required this.statusHariIni});

  @override
  State<AbsensiMapCard> createState() => _AbsensiMapCardState();
}

class _AbsensiMapCardState extends State<AbsensiMapCard>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────
  UserLocation? _userLocation;
  bool _isLoading = true;
  String? _errorMessage;

  // Rute dari user ke sekolah
  _RouteResult? _routeResult;
  bool _isFetchingRoute = false;

  // ── Map Controller ────────────────────────────────────────
  GoogleMapController? _mapController;
  bool _mapReady = false;

  // ── Subscription ─────────────────────────────────────────
  StreamSubscription<UserLocation>? _locationSub;

  // ── Marker icon custom (di-generate sekali, async) ────────
  _MarkerIcon? _schoolIcon;
  _MarkerIcon? _userIconInside;
  _MarkerIcon? _userIconOutside;

  // 🆕 Koordinat sekolah SEKARANG dari LocationService,
  // yang sudah ditarik dari backend lewat loadSchoolLocation().
  LatLng get _schoolLatLng => LatLng(
        LocationService.schoolCenterLat,
        LocationService.schoolCenterLng,
      );

  // ── Animasi status badge ──────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _generateMarkerIcons();
    _initLokasiDanTracking();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _locationSub?.cancel();
    LocationService.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Generate marker icon custom sekali di awal ────────────
  Future<void> _generateMarkerIcons() async {
    final school = await _buildMarkerBitmap(
      color: const Color(0xFF1D4ED8),
      icon: Icons.school_rounded,
      label: 'SEKOLAH',
    );
    final userIn = await _buildMarkerBitmap(
      color: const Color(0xFF16A34A),
      icon: Icons.person_rounded,
      label: 'KAMU',
    );
    final userOut = await _buildMarkerBitmap(
      color: const Color(0xFFDC2626),
      icon: Icons.person_rounded,
      label: 'KAMU',
    );

    if (!mounted) return;
    setState(() {
      _schoolIcon = school;
      _userIconInside = userIn;
      _userIconOutside = userOut;
    });
  }

  // 🆕 Ambil koordinat sekolah dari backend dulu,
  // baru mulai tracking lokasi user
  Future<void> _initLokasiDanTracking() async {
    await LocationService.loadSchoolLocation();
    if (!mounted) return;

    // Refresh kamera ke posisi sekolah yang benar (kalau beda
    // dari default) setelah data backend masuk
    setState(() {});
    if (_mapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_schoolLatLng, 16.5),
      );
    }

    await _startLocationTracking();
  }

  // ── Mulai tracking lokasi ─────────────────────────────────
  Future<void> _startLocationTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = await LocationService.checkPermissionStatus();

    if (status == LocationPermissionStatus.serviceDisabled) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'GPS dimatikan. Aktifkan lokasi di pengaturan.';
      });
      return;
    }

    if (status == LocationPermissionStatus.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.';
      });
      return;
    }

    // Ambil posisi awal sekali
    final initial = await LocationService.getCurrentLocation();
    if (initial != null && mounted) {
      _updateLocation(initial);
    }

    // Mulai stream
    final started = await LocationService.startTracking(
      intervalMs: 2000,
      distanceFilter: 3.0,
    );

    if (!started && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mendapatkan izin lokasi.';
      });
      return;
    }

    _locationSub = LocationService.locationStream?.listen(
      (location) {
        if (mounted) _updateLocation(location);
      },
      onError: (e) {
        // Abaikan error — lokasi awal sudah didapat
      },
    );

    setState(() => _isLoading = false);
  }

  // ── Update lokasi + fetch rute ────────────────────────────
  void _updateLocation(UserLocation location) {
    setState(() => _userLocation = location);

    // Pindah kamera peta ke posisi user (smooth)
    if (_mapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(location.lat, location.lng)),
      );
    }

    // Fetch rute kalau user di luar zona
    if (!location.isInsideZone) {
      _fetchRoute(location.lat, location.lng);
    } else {
      setState(() => _routeResult = null);
    }
  }

  // ── Fetch routing OSRM (gratis, open source) ─────────────
  Future<void> _fetchRoute(double userLat, double userLng) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '$userLng,$userLat;${_schoolLatLng.longitude},${_schoolLatLng.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();
          final coords = route['geometry']['coordinates'] as List;

          final points = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          if (mounted) {
            setState(() {
              _routeResult = _RouteResult(
                points: points,
                distanceMeters: distance,
                durationSeconds: duration,
              );
            });
          }
        }
      }
    } catch (_) {
      // Kalau OSRM gagal, cukup diam — jarak Haversine tetap tampil
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  // ── Bangun markers untuk GoogleMap ────────────────────────
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('sekolah'),
        position: _schoolLatLng,
        icon: _schoolIcon?.bitmap ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: _schoolIcon?.anchor ?? const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: LocationService.namaLokasi),
      ),
    };

    final loc = _userLocation;
    if (loc != null) {
      final icon = loc.isInsideZone ? _userIconInside : _userIconOutside;
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(loc.lat, loc.lng),
          anchor: icon?.anchor ?? const Offset(0.5, 0.5),
          icon: icon?.bitmap ??
              BitmapDescriptor.defaultMarkerWithHue(
                loc.isInsideZone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
              ),
          infoWindow: const InfoWindow(title: 'Kamu'),
        ),
      );
    }

    return markers;
  }

  // 🆕 Zona sekolah digambar sebagai PERSEGI PANJANG (Polygon),
  // titik sudutnya PERSIS dari lat_min/lat_max/lng_min/lng_max
  // di tabel lokasis — bukan lingkaran radius meter.
  Set<Polygon> _buildZonePolygon() {
    return {
      Polygon(
        polygonId: const PolygonId('zona_sekolah'),
        points: [
          LatLng(LocationService.latMin, LocationService.lngMin),
          LatLng(LocationService.latMin, LocationService.lngMax),
          LatLng(LocationService.latMax, LocationService.lngMax),
          LatLng(LocationService.latMax, LocationService.lngMin),
        ],
        fillColor: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
        strokeColor: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
        strokeWidth: 2,
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (_routeResult == null || _routeResult!.points.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('rute_ke_sekolah'),
        points: _routeResult!.points,
        color: const Color(0xFF1D4ED8),
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    };
  }

  // ── Warna zona ────────────────────────────────────────────
  Color get _zoneColor =>
      (_userLocation?.isInsideZone ?? false)
          ? const Color(0xFF16A34A)
          : const Color(0xFFDC2626);

  Color get _zoneBgColor =>
      (_userLocation?.isInsideZone ?? false)
          ? const Color(0xFFF0FDF4)
          : const Color(0xFFFEF2F2);

  // ── Show Fullscreen ───────────────────────────────────────
  void _showFullscreenMap() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => _FullscreenMapView(
        userLocation: _userLocation,
        routeResult: _routeResult,
        schoolLatLng: _schoolLatLng,
        schoolIcon: _schoolIcon,
        userIconInside: _userIconInside,
        userIconOutside: _userIconOutside,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Absensi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        LocationService.namaLokasi,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  _buildLoadingBadge()
                else if (_errorMessage != null)
                  _buildErrorBadge()
                else
                  _buildZoneBadge(),
              ],
            ),
          ),

          // ── Info rute / jarak ─────────────────────────────
          if (!_isLoading && _errorMessage == null && _userLocation != null)
            _buildInfoBanner(),

          // ── Map Area ──────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: 220,
              child: _isLoading
                  ? _buildLoadingMap()
                  : _errorMessage != null
                      ? _buildErrorMap()
                      : _buildMapWithOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading badge ─────────────────────────────────────────
  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Mencari...',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBadge() {
    return GestureDetector(
      onTap: _startLocationTracking,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 10, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Retry',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneBadge() {
    final inside = _userLocation?.isInsideZone ?? false;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _zoneBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _zoneColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _zoneColor.withValues(alpha: _pulseAnim.value),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                inside ? 'Dalam Zona' : 'Luar Zona',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _zoneColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Banner info jarak / rute ─────────────────────────────
  Widget _buildInfoBanner() {
    final loc = _userLocation!;
    final inside = loc.isInsideZone;

    String distanceText;
    String icon;
    Color bannerColor;
    Color borderColor;
    Color textColor;

    if (inside) {
      distanceText = 'Anda sudah berada di dalam zona absensi ✅';
      bannerColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF16A34A).withValues(alpha: 0.2);
      textColor = const Color(0xFF166534);
      icon = '✅';
    } else if (_routeResult != null) {
      distanceText = '${_routeResult!.distanceReadable} • ${_routeResult!.durationReadable}';
      bannerColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      textColor = const Color(0xFF92400E);
      icon = '🚗';
    } else {
      final dist = LocationService.formatDistance(loc.distanceToZone);
      distanceText = '$dist lagi ke zona sekolah';
      bannerColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      textColor = const Color(0xFF92400E);
      icon = '📍';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              distanceText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          if (_isFetchingRoute)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFF59E0B),
              ),
            ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '±${loc.accuracy.toStringAsFixed(0)}m',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: const Color(0xFFE8F4FD),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF1D4ED8),
            ),
            SizedBox(height: 12),
            Text(
              'Mengaktifkan GPS & Peta...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMap() {
    return Container(
      color: const Color(0xFFFEF2F2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFFDC2626)),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'GPS tidak tersedia',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F1D1D),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                if (_errorMessage?.contains('pengaturan') ?? false) {
                  await LocationService.openLocationSettings();
                } else {
                  _startLocationTracking();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Google Maps utama (preview, di dalam card) ────────────
  Widget _buildRealMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _userLocation != null
            ? LatLng(_userLocation!.lat, _userLocation!.lng)
            : _schoolLatLng,
        zoom: 16.5,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _mapReady = true;
      },
      markers: _buildMarkers(),
      polygons: _buildZonePolygon(),
      polylines: _buildPolylines(),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: false,
    );
  }

  // ── Stack overlay di atas peta (tombol view + koordinat) ─
  Widget _buildMapWithOverlay() {
    return Stack(
      children: [
        _buildRealMap(),

        // Tombol View Fullscreen
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _showFullscreenMap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Live indicator
        Positioned(
          bottom: 10,
          left: 10,
          child: _RealtimeIndicator(isTracking: _userLocation != null),
        ),

        // Koordinat
        if (_userLocation != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                '${_userLocation!.lat.toStringAsFixed(5)}°N\n'
                '${_userLocation!.lng.toStringAsFixed(5)}°E',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FULLSCREEN MAP VIEW
// ═══════════════════════════════════════════════════════════
class _FullscreenMapView extends StatefulWidget {
  final UserLocation? userLocation;
  final _RouteResult? routeResult;
  final LatLng schoolLatLng;
  final _MarkerIcon? schoolIcon;
  final _MarkerIcon? userIconInside;
  final _MarkerIcon? userIconOutside;
  final VoidCallback onClose;

  const _FullscreenMapView({
    required this.userLocation,
    required this.routeResult,
    required this.schoolLatLng,
    required this.schoolIcon,
    required this.userIconInside,
    required this.userIconOutside,
    required this.onClose,
  });

  @override
  State<_FullscreenMapView> createState() => _FullscreenMapViewState();
}

class _FullscreenMapViewState extends State<_FullscreenMapView> {
  GoogleMapController? _mapController;
  StreamSubscription<UserLocation>? _sub;
  UserLocation? _loc;
  _RouteResult? _route;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _loc = widget.userLocation;
    _route = widget.routeResult;

    _sub = LocationService.locationStream?.listen((loc) {
      if (!mounted) return;
      setState(() => _loc = loc);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
      if (!loc.isInsideZone) _fetchRoute(loc.lat, loc.lng);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute(double userLat, double userLng) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '$userLng,$userLat;${widget.schoolLatLng.longitude},${widget.schoolLatLng.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _route = _RouteResult(
                points: points,
                distanceMeters: (route['distance'] as num).toDouble(),
                durationSeconds: (route['duration'] as num).toDouble(),
              );
            });
          }
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  Color get _zoneColor =>
      (_loc?.isInsideZone ?? false) ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('sekolah'),
        position: widget.schoolLatLng,
        icon: widget.schoolIcon?.bitmap ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: widget.schoolIcon?.anchor ?? const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: LocationService.namaLokasi),
      ),
    };
    if (_loc != null) {
      final icon = _loc!.isInsideZone ? widget.userIconInside : widget.userIconOutside;
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_loc!.lat, _loc!.lng),
          anchor: icon?.anchor ?? const Offset(0.5, 0.5),
          icon: icon?.bitmap ??
              BitmapDescriptor.defaultMarkerWithHue(
                _loc!.isInsideZone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
              ),
          infoWindow: const InfoWindow(title: 'Kamu'),
        ),
      );
    }
    return markers;
  }

  // 🆕 Sama seperti preview card: zona digambar PERSEGI PANJANG
  // dari lat_min/lat_max/lng_min/lng_max — bukan lingkaran.
  Set<Polygon> _buildZonePolygon() {
    return {
      Polygon(
        polygonId: const PolygonId('zona_sekolah'),
        points: [
          LatLng(LocationService.latMin, LocationService.lngMin),
          LatLng(LocationService.latMin, LocationService.lngMax),
          LatLng(LocationService.latMax, LocationService.lngMax),
          LatLng(LocationService.latMax, LocationService.lngMin),
        ],
        fillColor: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
        strokeColor: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
        strokeWidth: 2,
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (_route == null || _route!.points.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('rute_ke_sekolah'),
        points: _route!.points,
        color: const Color(0xFF1D4ED8),
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loc = _loc;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // ── Peta fullscreen ────────────────────────────
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: loc != null
                      ? LatLng(loc.lat, loc.lng)
                      : widget.schoolLatLng,
                  zoom: 16.5,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _buildMarkers(),
                polygons: _buildZonePolygon(),
                polylines: _buildPolylines(),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
            ),

            // ── Header Card ───────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Absensi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  LocationService.namaLokasi,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Zone badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (loc?.isInsideZone ?? false)
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _zoneColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              (loc?.isInsideZone ?? false) ? 'Dalam Zona' : 'Luar Zona',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _zoneColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Jarak realtime
                      if (loc != null) ...[
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: loc.isInsideZone
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: loc.isInsideZone
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                loc.isInsideZone ? '✅' : '🚶',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: loc.isInsideZone
                                    ? const Text(
                                        'Anda berada di dalam zona absensi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF166534),
                                          fontFamily: 'Poppins',
                                        ),
                                      )
                                    : Text(
                                        _route != null
                                            ? '${_route!.distanceReadable} • ${_route!.durationReadable}'
                                            : '${LocationService.formatDistance(loc.distanceToZone)} ke zona sekolah',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF92400E),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                              ),
                              if (_isFetchingRoute)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Info ────────────────────────────────
            if (loc != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.location_on_rounded,
                            label: 'Koordinat',
                            value:
                                '${loc.lat.toStringAsFixed(6)}°N\n${loc.lng.toStringAsFixed(6)}°E',
                          ),
                        ),
                        _divider(),
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.gps_fixed_rounded,
                            label: 'Akurasi GPS',
                            value: '± ${loc.accuracy.toStringAsFixed(0)} m',
                          ),
                        ),
                        _divider(),
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.social_distance_rounded,
                            label: 'Jarak Rute',
                            value: _route != null
                                ? _route!.distanceReadable
                                : loc.isInsideZone
                                    ? 'Di Zona ✅'
                                    : LocationService.formatDistance(loc.distanceToZone),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Realtime indicator ─────────────────────────
            Positioned(
              bottom: 96,
              right: 24,
              child: _RealtimeIndicator(isTracking: loc != null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFFE2E8F0),
      );
}

// ═══════════════════════════════════════════════════════════
// REALTIME INDICATOR
// ═══════════════════════════════════════════════════════════
class _RealtimeIndicator extends StatefulWidget {
  final bool isTracking;
  const _RealtimeIndicator({required this.isTracking});

  @override
  State<_RealtimeIndicator> createState() => _RealtimeIndicatorState();
}

class _RealtimeIndicatorState extends State<_RealtimeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isTracking
                    ? Color.lerp(
                        const Color(0xFF16A34A),
                        const Color(0xFF86EFAC),
                        _ctrl.value,
                      )!
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.isTracking ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: widget.isTracking
                  ? const Color(0xFF166534)
                  : const Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INFO ITEM (bottom bar fullscreen)
// ═══════════════════════════════════════════════════════════
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF94A3B8),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            fontFamily: 'Poppins',
            height: 1.4,
          ),
        ),
      ],
    );
  }
}