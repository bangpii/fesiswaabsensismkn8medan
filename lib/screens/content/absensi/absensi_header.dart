import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'absensi_models.dart';
import '../../../services/absensi_realtime_service.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI HEADER — Realtime Clock + Backend Status + GPS
// ═══════════════════════════════════════════════════════════

class AbsensiHeader extends StatefulWidget {
  final StatusAbsensi statusHariIni;

  const AbsensiHeader({super.key, required this.statusHariIni});

  @override
  State<AbsensiHeader> createState() => _AbsensiHeaderState();
}

class _AbsensiHeaderState extends State<AbsensiHeader>
    with SingleTickerProviderStateMixin {
  // ── Animasi ─────────────────────────────────────────────
  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  // ── Timer jam & detik ───────────────────────────────────
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // ── Lokasi GPS ──────────────────────────────────────────
  bool _isLocationActive = false;
  StreamSubscription<ServiceStatus>? _locationStatusSub;

  // ── Status dari backend (realtime) ──────────────────────
  StreamSubscription<AbsensiRealtimeState>? _realtimeSub;
  String _statusLabel = '...';
  Color _statusColor = const Color(0xFF22C55E);

  // ── Waktu & Sesi ────────────────────────────────────────
  String get _jam =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

  String get _detik => _now.second.toString().padLeft(2, '0');

  String get _tanggal {
    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    const hari = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return '${hari[_now.weekday]}, ${_now.day} ${bulan[_now.month]} ${_now.year}';
  }

  /// Menentukan zona waktu Indonesia berdasarkan UTC offset device.
  /// WIB  = UTC+7  (Sumatera, Jawa, Kalimantan Barat/Tengah)
  /// WITA = UTC+8  (Kalimantan Timur, Sulawesi, Bali, NTB, NTT)
  /// WIT  = UTC+9  (Maluku, Papua)
  String get _zonaWaktu {
    final offset = _now.timeZoneOffset.inHours;
    if (offset == 7) return 'WIB';
    if (offset == 8) return 'WITA';
    if (offset == 9) return 'WIT';
    return 'UTC${offset >= 0 ? '+' : ''}$offset';
  }

  /// Sesi berdasarkan jam device.
  String get _sesiWaktu {
    final h = _now.hour;
    if (h >= 5 && h < 12) return 'Pagi';
    if (h >= 12 && h < 15) return 'Siang';
    if (h >= 15 && h < 18) return 'Sore';
    if (h >= 18 && h < 21) return 'Malam';
    return 'Dini Hari';
  }

  IconData get _sesiIcon {
    final h = _now.hour;
    if (h >= 5 && h < 12) return Icons.wb_sunny_rounded;
    if (h >= 12 && h < 15) return Icons.light_mode_rounded;
    if (h >= 15 && h < 18) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  // ════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startClock();
    _listenLocationStatus();
    _listenRealtimeStatus();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeOutCubic),
    );
    _animController!.forward();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  /// Cek status GPS service (bukan permission, tapi apakah GPS hidup/mati).
  Future<void> _listenLocationStatus() async {
    // cek awal
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) setState(() => _isLocationActive = isEnabled);

    // listen perubahan
    _locationStatusSub =
        Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        setState(
            () => _isLocationActive = status == ServiceStatus.enabled);
      }
    });
  }

  /// Listen status absensi dari AbsensiRealtimeService.
  void _listenRealtimeStatus() {
    _realtimeSub = AbsensiRealtimeService.stream.listen((state) {
      if (mounted) {
        setState(() {
          _statusLabel = state.statusText;
          // Semua warna hijau sesuai permintaan backend (color sudah #22C55E)
          // Kalau mau ikut warna dari backend bisa uncomment baris bawah:
          // _statusColor = Color(int.parse(
          //   (state.raw?['status_ui']?['color'] ?? '#22C55E')
          //       .replaceFirst('#', '0xFF')));
        });
      }
    });

    // Seed awal dari prop statusHariIni sambil nunggu stream
    _statusLabel = widget.statusHariIni.label;
  }

  @override
  void didUpdateWidget(covariant AbsensiHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update label jika prop berubah dari luar (sebelum stream pertama)
    if (widget.statusHariIni.label != oldWidget.statusHariIni.label) {
      setState(() => _statusLabel = widget.statusHariIni.label);
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _clockTimer?.cancel();
    _locationStatusSub?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    if (_animController == null || _fadeAnim == null || _slideAnim == null) {
      return _buildSkeleton(isSmall);
    }

    return FadeTransition(
      opacity: _fadeAnim!,
      child: SlideTransition(
        position: _slideAnim!,
        child: _buildCard(context, isSmall),
      ),
    );
  }

  // ── Skeleton saat animasi belum init ───────────────────
  Widget _buildSkeleton(bool isSmall) {
    return Container(
      width: double.infinity,
      height: isSmall ? 200 : 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  // ── Card utama ──────────────────────────────────────────
  Widget _buildCard(BuildContext context, bool isSmall) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Dekorasi background ──────────────────────
            _buildBgCircle(top: -50, right: -30, size: 150, opacity: 0.03),
            _buildBgCircle(bottom: -30, left: -40, size: 180, opacity: 0.02),
            _buildFloatingDot(
              top: 40,
              right: MediaQuery.of(context).size.width * 0.15,
              size: 8,
              opacity: 0.4,
            ),
            _buildFloatingDot(
              top: 80,
              right: MediaQuery.of(context).size.width * 0.25,
              size: 5,
              opacity: 0.25,
            ),
            _buildFloatingDot(
              bottom: 60,
              left: MediaQuery.of(context).size.width * 0.1,
              size: 6,
              opacity: 0.3,
            ),

            // ── Konten ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmall ? 16 : 24,
                isSmall ? 20 : 28,
                isSmall ? 16 : 24,
                isSmall ? 24 : 32,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(),
                    SizedBox(height: isSmall ? 16 : 20),
                    _buildDigitalClock(isSmall),
                    SizedBox(height: isSmall ? 6 : 8),
                    Text(
                      _tanggal,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isSmall ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmall ? 16 : 20),
                    _buildInfoBar(isSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dekorasi helpers ────────────────────────────────────
  Widget _buildBgCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildFloatingDot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STATUS BADGE — dari backend realtime
  // ════════════════════════════════════════════════════════
  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _statusColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indikator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _statusLabel,
              key: ValueKey(_statusLabel),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // DIGITAL CLOCK — jam + detik dari device user
  // ════════════════════════════════════════════════════════
  Widget _buildDigitalClock(bool isSmall) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _jam,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 44 : 60,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              fontFamily: 'Poppins',
              height: 1,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              _detik,
              key: ValueKey(_detik),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isSmall ? 20 : 26,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // INFO BAR — Zona Waktu + Sesi + Status Lokasi GPS
  // ════════════════════════════════════════════════════════
  Widget _buildInfoBar(bool isSmall) {
    final locColor = _isLocationActive
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final locLabel =
        _isLocationActive ? 'Lokasi Aktif' : 'Lokasi Nonaktif';
    final locIcon = _isLocationActive
        ? Icons.location_on_rounded
        : Icons.location_off_rounded;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Zona waktu + sesi ──────────────────────
            Icon(
              _sesiIcon,
              color: Colors.white.withOpacity(0.75),
              size: isSmall ? 13 : 15,
            ),
            const SizedBox(width: 5),
            Text(
              '$_sesiWaktu • $_zonaWaktu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),

            // ── Divider ────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 10,
              color: Colors.white.withOpacity(0.3),
            ),

            // ── Status lokasi GPS ──────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Row(
                key: ValueKey(_isLocationActive),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    locIcon,
                    color: locColor,
                    size: isSmall ? 13 : 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locLabel,
                    style: TextStyle(
                      color: locColor,
                      fontSize: isSmall ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
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
}