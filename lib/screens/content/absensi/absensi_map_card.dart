// lib/screens/content/absensi/absensi_map_card.dart
//
// 🗺️ ABSENSI MAP CARD — Real Map (OpenStreetMap) + Routing OSRM
//
// Fitur:
//   ✅ Peta sungguhan OpenStreetMap (ada jalan, nama tempat, bangunan)
//   ✅ Lokasi user realtime (marker bergerak saat HP bergerak)
//   ✅ Marker sekolah tetap di koordinat backend
//   ✅ Garis rute dari user → sekolah (via OSRM API, gratis)
//   ✅ Jarak & estimasi waktu jalan kaki akurat dari routing
//   ✅ Status "Dalam Zona" / "Luar Zona" otomatis
//   ✅ Fullscreen view
//
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
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
    if (minutes < 60) return '~$minutes menit jalan kaki';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return '~$hours jam $rem menit';
  }
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
  late MapController _mapController;
  bool _mapReady = false;

  // ── Subscription ─────────────────────────────────────────
  StreamSubscription<UserLocation>? _locationSub;

  // Koordinat sekolah (dari backend)
  static const LatLng _schoolLatLng = LatLng(
    LocationService.schoolCenterLat,
    LocationService.schoolCenterLng,
  );

  // ── Animasi status badge ──────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _startLocationTracking();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _locationSub?.cancel();
    LocationService.stopTracking();
    super.dispose();
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

    // Pindah kamera peta ke posisi user (pertama kali)
    if (_mapReady && !_isFetchingRoute) {
      try {
        _mapController.move(
          LatLng(location.lat, location.lng),
          _mapController.camera.zoom,
        );
      } catch (_) {}
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
        onClose: () => Navigator.of(context).pop(),
        onRetry: _startLocationTracking,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD UTAMA — HANYA SATU METHOD BUILD DI SINI!
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
                    children: const [
                      Text(
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
                        'SMKN 8 Medan, Sumatera Utara',
                        style: TextStyle(
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
      icon = '🚶';
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

  // ── Peta sungguhan OpenStreetMap ──────────────────────────
  Widget _buildRealMap() {
    final userLoc = _userLocation;
    final initialCenter = userLoc != null
        ? LatLng(userLoc.lat, userLoc.lng)
        : _schoolLatLng;

    // Zoom: kalau dalam zona tampilkan lebih dekat, kalau jauh zoom out
    double initialZoom = 16.5;
    if (userLoc != null && userLoc.distanceToSchool > 500) {
      initialZoom = 14.0;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 10,
        maxZoom: 19,
        onMapReady: () => setState(() => _mapReady = true),
      ),
      children: [
        // ── Tile OpenStreetMap ──────────────────────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smkn8medan.absensi',
          tileProvider: CancellableNetworkTileProvider(),
        ),

        // ── Polyline rute user → sekolah ───────────────
        if (_routeResult != null && _routeResult!.points.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeResult!.points,
                color: const Color(0xFF1D4ED8),
                strokeWidth: 4.0,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),

        // ── Lingkaran zona sekolah ─────────────────────
        CircleLayer(
          circles: [
            CircleMarker(
              point: _schoolLatLng,
              radius: 100,
              useRadiusInMeter: true,
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
              borderColor: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),

        // ── Marker sekolah + user ──────────────────────
        MarkerLayer(
          markers: [
            // Marker Sekolah
            Marker(
              point: _schoolLatLng,
              width: 60,
              height: 70,
              alignment: Alignment.topCenter,
              child: const _SchoolMarker(),
            ),

            // Marker User (kalau lokasi tersedia)
            if (userLoc != null)
              Marker(
                point: LatLng(userLoc.lat, userLoc.lng),
                width: 56,
                height: 66,
                alignment: Alignment.topCenter,
                child: _UserMarker(isInsideZone: userLoc.isInsideZone),
              ),
          ],
        ),
      ],
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
  final VoidCallback onClose;
  final VoidCallback onRetry;

  const _FullscreenMapView({
    required this.userLocation,
    required this.routeResult,
    required this.schoolLatLng,
    required this.onClose,
    required this.onRetry,
  });

  @override
  State<_FullscreenMapView> createState() => _FullscreenMapViewState();
}

class _FullscreenMapViewState extends State<_FullscreenMapView> {
  late MapController _mapCtrl;
  StreamSubscription<UserLocation>? _sub;
  UserLocation? _loc;
  _RouteResult? _route;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _loc = widget.userLocation;
    _route = widget.routeResult;

    _sub = LocationService.locationStream?.listen((loc) {
      if (mounted) {
        setState(() => _loc = loc);
        try {
          _mapCtrl.move(LatLng(loc.lat, loc.lng), _mapCtrl.camera.zoom);
        } catch (_) {}
        if (!loc.isInsideZone) _fetchRoute(loc.lat, loc.lng);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loc = _loc;
    final initialCenter = loc != null
        ? LatLng(loc.lat, loc.lng)
        : widget.schoolLatLng;

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
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 16.5,
                  minZoom: 10,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smkn8medan.absensi',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (_route != null && _route!.points.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route!.points,
                          color: const Color(0xFF1D4ED8),
                          strokeWidth: 5.0,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: widget.schoolLatLng,
                        radius: 100,
                        useRadiusInMeter: true,
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                        borderColor: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.schoolLatLng,
                        width: 70,
                        height: 80,
                        alignment: Alignment.topCenter,
                        child: const _SchoolMarker(large: true),
                      ),
                      if (loc != null)
                        Marker(
                          point: LatLng(loc.lat, loc.lng),
                          width: 64,
                          height: 74,
                          alignment: Alignment.topCenter,
                          child: _UserMarker(
                            isInsideZone: loc.isInsideZone,
                            large: true,
                          ),
                        ),
                    ],
                  ),
                ],
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi Absensi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'SMKN 8 Medan, Sumatera Utara',
                                  style: TextStyle(
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
// MARKER WIDGETS
// ═══════════════════════════════════════════════════════════

class _SchoolMarker extends StatelessWidget {
  final bool large;
  const _SchoolMarker({this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 50.0 : 36.0;
    final iconSize = large ? 28.0 : 20.0;
    final fontSize = large ? 9.0 : 7.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
                blurRadius: large ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.school_rounded, color: Colors.white, size: iconSize),
        ),
        const SizedBox(height: 2),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 6,
            vertical: large ? 4 : 2,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'SMKN 8',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMarker extends StatelessWidget {
  final bool isInsideZone;
  final bool large;
  const _UserMarker({required this.isInsideZone, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 44.0 : 32.0;
    final iconSize = large ? 24.0 : 18.0;
    final fontSize = large ? 8.5 : 7.0;
    final color = isInsideZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: large ? 16 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.person_rounded, color: Colors.white, size: iconSize),
        ),
        const SizedBox(height: 2),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 8 : 5,
            vertical: large ? 3 : 2,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            'Kamu',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
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