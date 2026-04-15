import 'package:flutter/material.dart';
import 'absensi_models.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI HEADER — Modern Elegant & Responsive (FIXED CENTER)
// Clean design: Waktu Real-time, Tanggal, Status Absensi
// ═══════════════════════════════════════════════════════════

class AbsensiHeader extends StatefulWidget {
  final StatusAbsensi statusHariIni;

  const AbsensiHeader({super.key, required this.statusHariIni});

  @override
  State<AbsensiHeader> createState() => _AbsensiHeaderState();
}

class _AbsensiHeaderState extends State<AbsensiHeader>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  String get _jamSekarang {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String get _detikSekarang {
    final now = DateTime.now();
    return now.second.toString().padLeft(2, '0');
  }

  String get _tanggalSekarang {
    final now = DateTime.now();
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const hari = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${hari[now.weekday]}, ${now.day} ${bulan[now.month]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startClockTimer();
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

  void _startClockTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() {});
      return mounted;
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    if (_animController == null || _fadeAnim == null || _slideAnim == null) {
      return _buildPlaceholderHeader(isSmallScreen);
    }

    return FadeTransition(
      opacity: _fadeAnim!,
      child: SlideTransition(
        position: _slideAnim!,
        child: _buildHeaderContent(context, isSmallScreen),
      ),
    );
  }

  Widget _buildPlaceholderHeader(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 180 : 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context, bool isSmallScreen) {
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
            // ── Dekorasi Background Abstrak ─────────────────────
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: MediaQuery.of(context).size.width * 0.15,
              child: _buildFloatingDot(8, 0.4),
            ),
            Positioned(
              top: 80,
              right: MediaQuery.of(context).size.width * 0.25,
              child: _buildFloatingDot(5, 0.25),
            ),
            Positioned(
              bottom: 60,
              left: MediaQuery.of(context).size.width * 0.1,
              child: _buildFloatingDot(6, 0.3),
            ),

            // ── Konten Utama CENTER ───────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 24,
                isSmallScreen ? 20 : 28,
                isSmallScreen ? 16 : 24,
                isSmallScreen ? 24 : 32,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    _buildDigitalClock(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    Text(
                      _tanggalSekarang,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    _buildInfoSummary(isSmallScreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingDot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.statusHariIni.warna.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: widget.statusHariIni.warna.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.statusHariIni.warna,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.statusHariIni.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalClock(bool isSmallScreen) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _jamSekarang,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 44 : 60,
            fontWeight: FontWeight.w600,        // Ditebalkan dari w300 ke w600
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
        Text(
          _detikSekarang,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isSmallScreen ? 20 : 26,
            fontWeight: FontWeight.w500,        // Disesuaikan dari w400 ke w500
            fontFamily: 'Poppins',
            height: 1,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInfoSummary(bool isSmallScreen) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
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
            Icon(
              Icons.access_time_rounded,
              color: Colors.white.withOpacity(0.7),
              size: isSmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Waktu Server • WIB',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 10,
              color: Colors.white.withOpacity(0.3),
            ),
            Icon(
              Icons.location_on_outlined,
              color: Colors.white.withOpacity(0.7),
              size: isSmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Lokasi Aktif',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}