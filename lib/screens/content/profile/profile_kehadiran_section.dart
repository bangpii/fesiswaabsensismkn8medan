import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';
import '../../../services/absensi_semester_realtime_service.dart';

// ═══════════════════════════════════════════════════════════
// SECTION KEHADIRAN SEMESTER (StatefulWidget - Realtime)
// ═══════════════════════════════════════════════════════════

class SectionKehadiranBulan extends StatefulWidget {
  const SectionKehadiranBulan({super.key});

  @override
  State<SectionKehadiranBulan> createState() => _SectionKehadiranBulanState();
}

class _SectionKehadiranBulanState extends State<SectionKehadiranBulan> {
  AbsensiSemesterData? semesterData;

  @override
  void initState() {
    super.initState();

    // Ambil data cache jika sudah ada (instant, no flicker)
    semesterData = AbsensiSemesterRealtimeService.latestData;

    // Start realtime service
    AbsensiSemesterRealtimeService.start();

    // Listen stream update
    AbsensiSemesterRealtimeService.stream.listen((data) {
      if (!mounted) return;
      setState(() {
        semesterData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final semester = semesterData?.semester ?? 0;
    final tahunAjaran = semesterData?.tahunAjaran ?? '-';

    final totalPertemuan = semesterData?.totalPertemuan ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Label ──────────────────────────────
          Row(
            children: [
              Icon(
                FeatherIcons.barChart2,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                semester > 0
                    ? 'Kehadiran Semester $semester'
                    : 'Kehadiran Semester',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Sub label: tahun ajaran ────────────────────
          Text(
            tahunAjaran,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 14),

          // ── 4 Cards (horizontal scroll, 3 terlihat) ───
          SizedBox(
            height: 158,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              children: [
                // HADIR
                _KehadiranCard(
                  label: 'Hadir',
                  nilai: semesterData?.hadir ?? 0,
                  total: totalPertemuan,
                  ikon: Boxicons.bx_check_circle,
                  warna: const Color(0xFF16A34A),
                  bgWarna: const Color(0xFFF0FDF4),
                  borderWarna: const Color(0xFFBBF7D0),
                ),
                const SizedBox(width: 10),

                // IZIN
                _KehadiranCard(
                  label: 'Izin',
                  nilai: semesterData?.izin ?? 0,
                  total: totalPertemuan,
                  ikon: FeatherIcons.fileText,
                  warna: const Color(0xFF3B82F6),
                  bgWarna: const Color(0xFFDBEAFE),
                  borderWarna: const Color(0xFF93C5FD),
                ),
                const SizedBox(width: 10),

                // TERLAMBAT — kuning
                _KehadiranCard(
                  label: 'Terlambat',
                  nilai: semesterData?.terlambat ?? 0,
                  total: totalPertemuan,
                  ikon: Boxicons.bx_time_five,
                  warna: const Color(0xFFD97706),
                  bgWarna: const Color(0xFFFFFBEB),
                  borderWarna: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: 10),

                // ALPA — merah (scroll kanan untuk lihat)
                _KehadiranCard(
                  label: 'Alpa',
                  nilai: semesterData?.alpa ?? 0,
                  total: totalPertemuan,
                  ikon: Boxicons.bx_x_circle,
                  warna: const Color(0xFFDC2626),
                  bgWarna: const Color(0xFFFEF2F2),
                  borderWarna: const Color(0xFFFCA5A5),
                ),
                // Sedikit padding di ujung kanan
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Kehadiran Card Item
// ─────────────────────────────────────────────────────────

class _KehadiranCard extends StatelessWidget {
  final String label;
  final int nilai;
  final int total;
  final IconData ikon;
  final Color warna;
  final Color bgWarna;
  final Color borderWarna;

  const _KehadiranCard({
    required this.label,
    required this.nilai,
    required this.total,
    required this.ikon,
    required this.warna,
    required this.bgWarna,
    required this.borderWarna,
  });

  @override
  Widget build(BuildContext context) {
    // Lebar card: (screen - 20*2 - 10*2) / 3 agar tepat 3 terlihat
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 40 - 20) / 3;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bgWarna,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderWarna, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: warna.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: warna.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon, size: 16, color: warna),
            ),

            const SizedBox(height: 10),

            // Nilai (angka besar)
            Text(
              '$nilai',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: warna,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 2),

            // Label
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: warna.withOpacity(0.85),
              ),
            ),

            const SizedBox(height: 6),

            // Progress bar mini
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: total > 0 ? (nilai / total).clamp(0.0, 1.0) : 0.0,
                backgroundColor: warna.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(warna),
                minHeight: 3.5,
              ),
            ),

            const SizedBox(height: 4),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  physics: const NeverScrollableScrollPhysics(),
  child: Text(
    '$total Pertemuan',
    maxLines: 1,
    overflow: TextOverflow.fade,
    softWrap: false,
    style: GoogleFonts.poppins(
      fontSize: 8,
      color: warna.withOpacity(0.60),
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}