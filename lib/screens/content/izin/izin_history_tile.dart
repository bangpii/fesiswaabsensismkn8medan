import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'izin_models.dart';

// ═══════════════════════════════════════════════════════════
// IZIN HISTORY TILE — Tile riwayat izin + Section header
// ═══════════════════════════════════════════════════════════

class IzinHistorySection extends StatelessWidget {
  final List<RiwayatIzin> riwayat;

  const IzinHistorySection({super.key, required this.riwayat});

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${riwayat.length} izin',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Daftar Riwayat ─────────────────────────────
          if (riwayat.isEmpty)
            _EmptyRiwayat()
          else
            ...riwayat.map((item) => _IzinTile(item: item)),
        ],
      ),
    );
  }
}

class _EmptyRiwayat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(FeatherIcons.inbox, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'Belum ada riwayat izin',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _IzinTile extends StatelessWidget {
  final RiwayatIzin item;

  const _IzinTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _warnStatus(item.status);
    final statusBg = statusColor.withOpacity(0.1);
    final bulan = _namaBulan(item.tanggal.month);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Tanggal block
          Container(
            width: 38,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.tanggal.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    height: 1.1,
                  ),
                ),
                Text(
                  bulan,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.jenis.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.status.label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.keterangan,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(FeatherIcons.user, size: 9, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      item.namaPenerima,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMuted,
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

  Color _warnStatus(StatusIzin status) {
    switch (status) {
      case StatusIzin.menunggu:
        return const Color(0xFFD97706);
      case StatusIzin.disetujui:
        return const Color(0xFF059669);
      case StatusIzin.ditolak:
        return const Color(0xFFDC2626);
    }
  }

  String _namaBulan(int bulan) {
    const nama = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return nama[bulan - 1];
  }
}