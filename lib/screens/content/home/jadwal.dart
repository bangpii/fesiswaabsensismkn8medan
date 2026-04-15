import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:ui';
import '../../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// KARTU JADWAL
// ═══════════════════════════════════════════════════════════
class KartuJadwal extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  const KartuJadwal({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final status = jadwal['status'] as String;

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'selesai':
        statusColor = AppColors.textMuted;
        statusLabel = 'Selesai';
        break;
      case 'aktif':
        statusColor = AppColors.success;
        statusLabel = 'Berlangsung';
        break;
      default:
        statusColor = AppColors.accent;
        statusLabel = 'Akan Datang';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status == 'aktif'
            ? AppColors.accent.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'aktif'
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(jadwal['icon'] as IconData,
                size: 20, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal['mapel'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: status == 'selesai'
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jadwal['guru'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.clock,
                            size: 10, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          jadwal['jam'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.mapPin,
                            size: 10, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          jadwal['ruang'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KARTU JADWAL MODAL — versi lebih detail untuk modal
// ═══════════════════════════════════════════════════════════
class _KartuJadwalModal extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  final int index;

  const _KartuJadwalModal({required this.jadwal, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = jadwal['status'] as String;

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'selesai':
        statusColor = AppColors.textMuted;
        statusLabel = 'Selesai';
        break;
      case 'aktif':
        statusColor = AppColors.success;
        statusLabel = 'Berlangsung';
        break;
      default:
        statusColor = AppColors.accent;
        statusLabel = 'Akan Datang';
    }

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
          color: status == 'aktif'
              ? AppColors.accent.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: status == 'aktif'
                ? AppColors.accent.withValues(alpha: 0.25)
                : statusColor.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.07),
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
            // ── Nomor urut + ikon ────────────────────────
            Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.15),
                        statusColor.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    jadwal['icon'] as IconData,
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Nomor urut jam
                Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // ── Detail jadwal ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          jadwal['mapel'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: status == 'selesai'
                                ? AppColors.textMuted
                                : const Color(0xFF1E3A5F),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Nama guru
                  Row(
                    children: [
                      Icon(FeatherIcons.user,
                          size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        jadwal['guru'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Divider tipis
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.0),
                          statusColor.withValues(alpha: 0.12),
                          statusColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Jam + Ruang dalam satu row
                  Row(
                    children: [
                      // Jam
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FeatherIcons.clock,
                                size: 10,
                                color: const Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              jadwal['jam'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ruang
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FeatherIcons.mapPin,
                                size: 10, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              jadwal['ruang'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
// MODAL SEMUA JADWAL
// ═══════════════════════════════════════════════════════════
class _ModalSemuaJadwal extends StatelessWidget {
  final List<Map<String, dynamic>> jadwal;

  const _ModalSemuaJadwal({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    // Hitung ringkasan status
    final aktif = jadwal.where((j) => j['status'] == 'aktif').length;
    final selesai = jadwal.where((j) => j['status'] == 'selesai').length;
    final akan = jadwal
        .where((j) => j['status'] != 'aktif' && j['status'] != 'selesai')
        .length;

    return GestureDetector(
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
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.2),
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
                                  FeatherIcons.clock,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jadwal Hari Ini',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E3A5F),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      '${jadwal.length} mata pelajaran',
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

                        // ── Chips ringkasan status ─────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Row(
                            children: [
                              _ChipStatus(
                                label: 'Berlangsung',
                                jumlah: aktif,
                                warna: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              _ChipStatus(
                                label: 'Akan Datang',
                                jumlah: akan,
                                warna: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              _ChipStatus(
                                label: 'Selesai',
                                jumlah: selesai,
                                warna: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),

                        // ── Divider tipis ──────────────────
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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

                        // ── List scroll jadwal ─────────────
                        Flexible(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 28),
                            physics: const BouncingScrollPhysics(),
                            itemCount: jadwal.length,
                            itemBuilder: (context, index) {
                              return _KartuJadwalModal(
                                jadwal: jadwal[index],
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
// CHIP STATUS — ringkasan di header modal
// ═══════════════════════════════════════════════════════════
class _ChipStatus extends StatelessWidget {
  final String label;
  final int jumlah;
  final Color warna;

  const _ChipStatus({
    required this.label,
    required this.jumlah,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: warna.withValues(alpha: 0.2),
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
              color: warna,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$jumlah $label',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: warna,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION JADWAL — dipanggil dari home.dart
// Tampil maks 4, sisanya buka modal
// ═══════════════════════════════════════════════════════════
// ... (kode sebelumnya tetap sama sampai SectionJadwal)

// ═══════════════════════════════════════════════════════════
// SECTION JADWAL — dipanggil dari home.dart
// Tampil maks 4, sisanya buka modal
// ═══════════════════════════════════════════════════════════
class SectionJadwal extends StatelessWidget {
  final List<Map<String, dynamic>> jadwal;

  const SectionJadwal({super.key, required this.jadwal});

  static const int _batasAwal = 4;

  void _bukaModal(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => _ModalSemuaJadwal(jadwal: jadwal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PERBAIKAN: Tampilkan maksimal 4 item
    final tampil = jadwal.take(_batasAwal).toList();
    // ✅ PERBAIKAN: Cek apakah ada lebih dari 4 item
    final adaLebih = jadwal.length > _batasAwal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header section ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(FeatherIcons.clock, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Jadwal Hari Ini',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            // ✅ Button akan muncul jika ada lebih dari 4 jadwal
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
                        color:
                            const Color(0xFF2563EB).withValues(alpha: 0.28),
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
                            '${jadwal.length}',
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
        ...tampil.map((j) => KartuJadwal(jadwal: j)),
      ],
    );
  }
}