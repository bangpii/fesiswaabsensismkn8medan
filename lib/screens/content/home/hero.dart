import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// import '../../../config/app_colors.dart';
import '../../../services/absensi_semester_realtime_service.dart';

// ═══════════════════════════════════════════════════════════
// HERO: Gradient biru gelap + gelombang + konten kaya
// ═══════════════════════════════════════════════════════════
class HeroAbstrak extends StatefulWidget {
  const HeroAbstrak({
    super.key,
    required this.waveController,
  });

  final AnimationController waveController;

  @override
  State<HeroAbstrak> createState() => _HeroAbstrakState();
}

class _HeroAbstrakState extends State<HeroAbstrak> {
  // ── Data semester realtime ──────────────────────────────
  AbsensiSemesterData? semesterData;

 @override
  void initState() {
    super.initState();

    // 🔥 Ambil cache dulu biar tidak blank
    semesterData =
        AbsensiSemesterRealtimeService.latestData;

    // 🔥 Start realtime
    AbsensiSemesterRealtimeService.start();

    // 🔥 Listen realtime
    AbsensiSemesterRealtimeService.stream.listen((data) {

      if (!mounted) return;

      setState(() {
        semesterData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: 232,
      child: Stack(
        children: [
          // Background gradient biru gelap
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1D4ED8),
                    Color(0xFF2563EB),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Gelombang animasi
          Positioned.fill(
            child: AnimatedBuilder(
              animation: widget.waveController,
              builder: (_, __) => CustomPaint(
                painter: WavePainter(
                  animValue: widget.waveController.value,
                  screenWidth: screenWidth,
                ),
              ),
            ),
          ),

          // Lingkaran dekoratif kanan atas
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Lingkaran kecil bawah
          Positioned(
            bottom: -20,
            left: screenWidth * 0.3,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          // ── Konten Hero ─────────────────────────────────
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Baris 1: Tanggal kiri + badge status kanan ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tanggal dengan ikon
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FeatherIcons.calendar,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 5),
                            Text(
                              _getTanggalHariIni(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge hadir hari ini
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color:
                                const Color(0xFF22C55E).withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Hadir Hari Ini',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF86EFAC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Baris 2: Judul kiri + mini stats kanan ──────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Kiri: nama sekolah + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SMKN 8 Medan',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sistem Informasi Absensi Digital',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kanan: mini stats 3 kolom
                      MiniStatsCard(
                        data: semesterData,
                      ),
                    ],
                  ),

                  // ── Baris 3: Progress kehadiran ──────────────────
                  KehadiranProgress(
                    data: semesterData,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTanggalHariIni() {
    final now = DateTime.now();
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month]} ${now.year}';
  }
}

// ─────────────────────────────────────────────────────────
// Mini Stats Card (pojok kanan Hero)
// ─────────────────────────────────────────────────────────
class MiniStatsCard extends StatelessWidget {
  final AbsensiSemesterData? data;

  const MiniStatsCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatItem(
            nilai: '${data?.persentaseHadir ?? 0}%',
            label: 'Hadir',
            warna: const Color(0xFF86EFAC),
          ),
          HeroDivider(),
          StatItem(
            nilai: '${data?.izin ?? 0}',
            label: 'Izin',
            warna: const Color(0xFFFBBF24),
          ),
          HeroDivider(),
          StatItem(
            nilai: '${data?.alpa ?? 0}',
            label: 'Alpha',
            warna: const Color(0xFFF87171),
          ),
        ],
      ),
    );
  }
}

class HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class StatItem extends StatelessWidget {
  final String nilai;
  final String label;
  final Color warna;

  const StatItem({
    super.key,
    required this.nilai,
    required this.label,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nilai,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: warna,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8.5,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Progress Kehadiran Bar
// ─────────────────────────────────────────────────────────
class KehadiranProgress extends StatelessWidget {
  final AbsensiSemesterData? data;

  const KehadiranProgress({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final persen = (data?.persentaseHadir ?? 0) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kehadiran Semester Ini',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '${data?.persentaseHadir ?? 0}% · '
              '${data?.totalMasuk ?? 0}/${data?.totalPertemuan ?? 0} pertemuan',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              // Track
              Container(
                height: 5,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: persen.clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Custom Painter: Gelombang ─────────────────────────────
class WavePainter extends CustomPainter {
  final double animValue;
  final double screenWidth;

  WavePainter({required this.animValue, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    _drawWave(canvas, size, paint1, animValue, 0.6, 40);
    _drawWave(canvas, size, paint2, 1 - animValue, 0.45, 30);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double anim,
      double heightRatio, double amplitude) {
    final path = Path();
    final yBase = size.height * heightRatio;
    path.moveTo(0, yBase);
    for (double x = 0; x <= size.width; x++) {
      final y = yBase +
          math.sin((x / size.width * 2 * math.pi) + (anim * 2 * math.pi)) *
              amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.animValue != animValue;
}