import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';
import 'profile_models.dart';

// ═══════════════════════════════════════════════════════════
// SECTION KEHADIRAN BULAN
// Judul + Minggu ke + 3 card: Hadir, Izin, Terlambat
// ═══════════════════════════════════════════════════════════

class SectionKehadiranBulan extends StatelessWidget {
  final DataKehadiranBulan data;

  const SectionKehadiranBulan({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                'Kehadiran Bulan ke-${data.bulan}',
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

          // ── Sub label: bulan + minggu ──────────────────
          Text(
            '${data.namaBulan} ${data.tahun}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 6),

          // ── Minggu Badge ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              'Minggu ke-${data.mingguKe}',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── 3 Cards ───────────────────────────────────
          Row(
            children: [
              Expanded(
  child: _KehadiranCard(
    label: 'Hadir',
    nilai: data.totalHadir,
    total: data.totalHariEfektif,
    ikon: Boxicons.bx_check_circle,
    warna: const Color(0xFF16A34A),        // Hijau (tetap)
    bgWarna: const Color(0xFFF0FDF4),
    borderWarna: const Color(0xFFBBF7D0),
  ),
),
const SizedBox(width: 10),
Expanded(
  child: _KehadiranCard(
    label: 'Izin',
    nilai: data.totalIzin,
    total: data.totalHariEfektif,
    ikon: FeatherIcons.fileText,
    warna: const Color(0xFF3B82F6),        // Biru Accent
    bgWarna: const Color(0xFFDBEAFE),    // Background biru muda
    borderWarna: const Color(0xFF93C5FD), // Border biru
  ),
),
const SizedBox(width: 10),
Expanded(
  child: _KehadiranCard(
    label: 'Terlambat',
    nilai: data.totalTerlambat,
    total: data.totalHariEfektif,
    ikon: Boxicons.bx_time_five,
    warna: const Color(0xFFDC2626),        // Merah
    bgWarna: const Color(0xFFFEF2F2),      // Background merah muda
    borderWarna: const Color(0xFFFCA5A5),  // Border merah
  ),
),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              value: total > 0 ? nilai / total : 0.0,
              backgroundColor: warna.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(warna),
              minHeight: 3.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'dari $total hari',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: warna.withOpacity(0.65),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}