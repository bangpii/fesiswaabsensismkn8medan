import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// SECTION AKSI CEPAT — Dengan spacing bottom
// ═══════════════════════════════════════════════════════════
class SectionAksiCepat extends StatelessWidget {
  const SectionAksiCepat({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header Section ─────────────────────────────────
        Row(
          children: [
            Icon(FeatherIcons.zap, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Aksi Cepat',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        // ── Grid dengan offset top ─────────────────────────
        Transform.translate(
          offset: const Offset(0, 20), // Top offset sudah diset
          child: const AksiCepatGrid(),
        ),
        // ── JARAK BOTTOM ───────────────────────────────────
        const SizedBox(height: 16), // ← Tambahkan ini untuk jarak ke bawah
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AKSI CEPAT GRID
// ═══════════════════════════════════════════════════════════
class AksiCepatGrid extends StatelessWidget {
  const AksiCepatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'Absensi',
        'ikon': Boxicons.bx_fingerprint,
        'warna': AppColors.accent,
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Izin',
        'ikon': FeatherIcons.fileText,
        'warna': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Jadwal',
        'ikon': FeatherIcons.calendar,
        'warna': const Color(0xFF0891B2),
        'bg': const Color(0xFFECFEFF),
      },
      {
        'label': 'Nilai',
        'ikon': Boxicons.bx_award,
        'warna': const Color(0xFF16A34A),
        'bg': const Color(0xFFF0FDF4),
      },
      {
        'label': 'Pesan',
        'ikon': Boxicons.bx_message_dots,
        'warna': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'label': 'Tabungan',
        'ikon': Boxicons.bx_wallet,
        'warna': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return AksiCepatItem(
          label: item['label'] as String,
          ikon: item['ikon'] as IconData,
          warna: item['warna'] as Color,
          bg: item['bg'] as Color,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AKSI CEPAT ITEM
// ═══════════════════════════════════════════════════════════
class AksiCepatItem extends StatelessWidget {
  final String label;
  final IconData ikon;
  final Color warna;
  final Color bg;

  const AksiCepatItem({
    super.key,
    required this.label,
    required this.ikon,
    required this.warna,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: warna.withValues(alpha: 0.15), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: warna, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}