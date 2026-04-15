import 'package:flutter/material.dart';
import 'absensi_models.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI HISTORY — Horizontal Scroll Card Grid (6 Hari)
// Tema: Putih, Biru, Hitam | No Overflow | UX Text
// ═══════════════════════════════════════════════════════════

class AbsensiHistorySection extends StatelessWidget {
  final List<RiwayatAbsensi> riwayat;

  const AbsensiHistorySection({
    super.key,
    required this.riwayat,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil 6 hari terakhir: Senin-Sabtu
    final enamHari = _getEnamHariTerakhir(riwayat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Riwayat Absensi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),

        // ── 6 Days Horizontal Scroll ──────────────────
        SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: enamHari.length,
            itemBuilder: (context, index) {
              return _HariCard(
                data: enamHari[index],
                index: index,
              );
            },
          ),
        ),

        // ── UX Text di Bawah Card ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tahapan Absensi Harian',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pastikan absen masuk sebelum jam 07:30 dan absen pulang setelah jam 15:00 untuk status hadir yang valid.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          fontFamily: 'Poppins',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<RiwayatAbsensi> _getEnamHariTerakhir(List<RiwayatAbsensi> data) {
    // Urutkan Senin-Sabtu (6 hari)
    final urutanHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    
    // Filter dan urutkan
    final filtered = data.where((item) => urutanHari.contains(item.hari)).toList();
    filtered.sort((a, b) => urutanHari.indexOf(a.hari).compareTo(urutanHari.indexOf(b.hari)));
    
    // Ambil maksimal 6
    return filtered.take(6).toList();
  }
}

// ═══════════════════════════════════════════════════════════
// HARI CARD — Compact 6 Cards Horizontal (Senin-Sabtu)
// ═══════════════════════════════════════════════════════════

class _HariCard extends StatelessWidget {
  final RiwayatAbsensi data;
  final int index;

  const _HariCard({
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.statusKehadiran;
    final isMasuk = data.jamMasuk != '—';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(16 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 96,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: Hari ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  data.hari,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Body: Jam Masuk ────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon + Label Masuk
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 11,
                            color: isMasuk
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isMasuk
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFFCBD5E1),
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Jam
                      Text(
                        isMasuk ? data.jamMasuk : '--:--',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMasuk
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                          fontFamily: 'Poppins',
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Status Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMasuk 
                              ? const Color(0xFF1D4ED8).withOpacity(0.08)
                              : status.warnaLatar,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMasuk ? 'Hadir' : status.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isMasuk 
                                ? const Color(0xFF1D4ED8)
                                : status.warna,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer: Status Bar ─────────────────────
              Container(
                width: double.infinity,
                height: 3,
                color: isMasuk 
                    ? const Color(0xFF1D4ED8)
                    : status.warna,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LEGACY: AbsensiHistoryTile (compatibility)
// ═══════════════════════════════════════════════════════════

class AbsensiHistoryTile extends StatelessWidget {
  final RiwayatAbsensi riwayat;
  final int index;

  const AbsensiHistoryTile({
    super.key,
    required this.riwayat,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}