import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import 'dart:ui';
import '../../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// KARTU PENGUMUMAN
// ═══════════════════════════════════════════════════════════
class KartuPengumuman extends StatelessWidget {
  final Map<String, dynamic> data;
  const KartuPengumuman({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final warna = data['warna'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data['icon'] as IconData, size: 18, color: warna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['judul'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['waktu'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  data['isi'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KARTU PENGUMUMAN MODAL — versi lebih lebar untuk modal
// ═══════════════════════════════════════════════════════════
class _KartuPengumumanModal extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _KartuPengumumanModal({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final warna = data['warna'] as Color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: warna.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: warna.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon dengan gradient background
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    warna.withValues(alpha: 0.15),
                    warna.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: warna.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(data['icon'] as IconData, size: 20, color: warna),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data['judul'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A5F),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['waktu'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: warna,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['isi'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF4B6080),
                      height: 1.55,
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

// ═══════════════════════════════════════════════════════════
// MODAL SEMUA PENGUMUMAN
// ═══════════════════════════════════════════════════════════
class _ModalSemuaPengumuman extends StatelessWidget {
  final List<Map<String, dynamic>> pengumuman;

  const _ModalSemuaPengumuman({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tutup modal saat tap di luar
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Backdrop blur + gelap ─────────────────────
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: const Color(0xFF0D1B2E).withValues(alpha: 0.55),
                ),
              ),
            ),

            // ── Bottom sheet modal ────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                // Cegah tap di dalam modal menutup
                onTap: () {},
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 60 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.82,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Handle bar ────────────────────
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ── Header modal ──────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1D4ED8),
                                      Color(0xFF2563EB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Boxicons.bx_bell,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Semua Pengumuman',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E3A5F),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      '${pengumuman.length} pengumuman aktif',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B8CAE),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ── Tombol close elegan ───────
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    FeatherIcons.x,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Divider tipis ──────────────────
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB).withValues(alpha: 0.0),
                                const Color(0xFF2563EB).withValues(alpha: 0.15),
                                const Color(0xFF2563EB).withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // ── List scroll pengumuman ─────────
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                            physics: const BouncingScrollPhysics(),
                            itemCount: pengumuman.length,
                            itemBuilder: (context, index) {
                              return _KartuPengumumanModal(
                                data: pengumuman[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION PENGUMUMAN — dipanggil dari home.dart
// Tampil maks 4, sisanya buka modal
// ═══════════════════════════════════════════════════════════
class SectionPengumuman extends StatelessWidget {
  final List<Map<String, dynamic>> pengumuman;

  const SectionPengumuman({super.key, required this.pengumuman});

  static const int _batasAwal = 4;

  void _bukaModal(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => _ModalSemuaPengumuman(
          pengumuman: pengumuman,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tampil = pengumuman.length > _batasAwal
        ? pengumuman.sublist(0, _batasAwal)
        : pengumuman;
    final adaLebih = pengumuman.length > _batasAwal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Boxicons.bx_bell, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Pengumuman',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            if (adaLebih)
              GestureDetector(
                onTap: () => _bukaModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${pengumuman.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...tampil.map((p) => KartuPengumuman(data: p)),
      ],
    );
  }
}