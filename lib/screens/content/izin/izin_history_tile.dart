import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'izin_models.dart';

// ═══════════════════════════════════════════════════════════
// IZIN HISTORY SECTION — Riwayat izin max 5 tile scroll internal
// ═══════════════════════════════════════════════════════════

class IzinHistorySection extends StatelessWidget {
  final List<RiwayatIzin> riwayat;
  final bool isLoading;

  const IzinHistorySection({
    super.key,
    required this.riwayat,
    this.isLoading = false,
  });

  // ═══════════════════════════════════════════════════════════
  // FIX #1: Naikkan tinggi tile dari 82 → 88
  // Biar ada ruang ekstra untuk konten di dalamnya
  // ═══════════════════════════════════════════════════════════
  static const double _tileHeight = 88.0;
  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final hasMore = riwayat.length > _maxVisible;
    final containerHeight = hasMore
        ? _tileHeight * _maxVisible + 8
        : null; // null = wrap content

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ─────────────────────────────
          Row(
            children: [
              Text(
                'Riwayat Izin',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${riwayat.length} izin',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Isi ───────────────────────────────────────
          if (isLoading)
            _LoadingState()
          else if (riwayat.isEmpty)
            _EmptyRiwayat()
          else
            SizedBox(
              height: containerHeight,
              child: ListView.builder(
                physics: hasMore
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                shrinkWrap: !hasMore,
                itemCount: riwayat.length,
                itemBuilder: (_, i) => _IzinTile(item: riwayat[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          height: 74,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Shimmer(width: 38, height: 40, radius: 9),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Shimmer(width: 100, height: 10, radius: 4),
                      const SizedBox(height: 6),
                      _Shimmer(width: 160, height: 9, radius: 4),
                      const SizedBox(height: 5),
                      _Shimmer(width: 80, height: 8, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────

class _EmptyRiwayat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FeatherIcons.inbox,
              size: 22,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Riwayat Izin',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tekan "Buat Izin" untuk mengajukan izin',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tile riwayat — SUDAH DIPERBAIKI
// ─────────────────────────────────────────────────────────

class _IzinTile extends StatelessWidget {
  final RiwayatIzin item;

  const _IzinTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorStatus(item.status);
    final statusBg = statusColor.withOpacity(0.09);
    final bulanPendek = _bulanPendek(item.tanggalIzin.month);

    return Container(
      height: IzinHistorySection._tileHeight, // 88px (FIX #1)
      margin: const EdgeInsets.only(bottom: 8),
      // ═══════════════════════════════════════════════════════════
      // FIX #2: Kurangi padding vertical 10 → 8
      // Biar ruang untuk konten lebih lega
      // ═══════════════════════════════════════════════════════════
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ═══════════════════════════════════════════════════════════
      // FIX #5: Clip behavior — safety net anti overflow
      // ═══════════════════════════════════════════════════════════
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // ── Tanggal block ─────────────────────────
          Container(
            width: 38,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.tanggalIzin.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                    height: 1.0,
                  ),
                ),
                Text(
                  bulanPendek,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB).withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Info ──────────────────────────────────
          // ═══════════════════════════════════════════════════════════
          // FIX #4: Ganti Expanded → Flexible + fit: tight
          // Expanded terlalu "memaksa", Flexible lebih "santai" tapi tetap mengisi
          // ═══════════════════════════════════════════════════════════
          Flexible(
            fit: FlexFit.tight,
            // ═══════════════════════════════════════════════════════════
            // FIX #3: Column pakai mainAxisSize: min + alignment: start
            // Biar Column tidak memaksakan diri memenuhi ruang kosong
            // ═══════════════════════════════════════════════════════════
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start, // ← ganti dari center
              mainAxisSize: MainAxisSize.min, // ← TAMBAHAN PENTING
              children: [
                // Jenis + Status badge
                Row(
                children: [
                  Expanded(
                    child: Text(
                      item.jenisIzin.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // 🔥 STATUS PINDAH KE KANAN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.status.label,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 2),

                // Keterangan
                Text(
                  item.keterangan?.isNotEmpty == true
                      ? item.keterangan!
                      : 'Tidak ada keterangan',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Tanggal disetujui / dibuat
                Row(
                  children: [
                    Icon(
                      item.status == StatusIzin.disetujui
                          ? FeatherIcons.checkCircle
                          : item.status == StatusIzin.ditolak
                              ? FeatherIcons.xCircle
                              : FeatherIcons.clock,
                      size: 9,
                      color: statusColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.status == StatusIzin.disetujui &&
                              item.disetujuiPada != null
                          ? 'Disetujui ${_formatTanggal(item.disetujuiPada!)}'
                          : item.status == StatusIzin.ditolak &&
                                  item.disetujuiPada != null
                              ? 'Ditolak ${_formatTanggal(item.disetujuiPada!)}'
                              : 'Belum Disetujui',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: statusColor.withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorStatus(StatusIzin status) {
    switch (status) {
      case StatusIzin.menunggu:
        return const Color(0xFFD97706);
      case StatusIzin.disetujui:
        return const Color(0xFF059669);
      case StatusIzin.ditolak:
        return const Color(0xFFDC2626);
    }
  }

  String _bulanPendek(int b) {
    const n = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return n[b - 1];
  }

  String _formatTanggal(DateTime d) {
    const n = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${n[d.month - 1]} ${d.year}';
  }
}