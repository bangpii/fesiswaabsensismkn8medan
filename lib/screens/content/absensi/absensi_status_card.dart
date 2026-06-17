import 'dart:async';
import 'package:flutter/material.dart';
import 'absensi_models.dart';
import '../../../services/absensi_service.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI STATUS CARD — Real Backend Data + Elegant UI
// Jam Masuk | Sisa Waktu | Jam Pulang
// ═══════════════════════════════════════════════════════════

class AbsensiStatusCard extends StatefulWidget {
  final StatusAbsensi status;

  const AbsensiStatusCard({super.key, required this.status});

  @override
  State<AbsensiStatusCard> createState() => _AbsensiStatusCardState();
}

class _AbsensiStatusCardState extends State<AbsensiStatusCard>
    with SingleTickerProviderStateMixin {
  // ── Data dari backend ────────────────────────────────────
  String? _jamMasuk;
  String? _jamPulang;
  String? _jamMasukTarget;  
  String? _jamPulangTarget; // dari waktu.jam_pulang_mulai
  bool _loading = true;

  Timer? _ticker;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fetchData();

    // Ticker setiap menit agar sisa waktu auto-update
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final res = await AbsensiService.hariIni();
      if (!mounted) return;

      final data = res['data'];
      final waktu = res['waktu'];

      setState(() {
        _jamMasuk = data?['jam_masuk'];
        _jamPulang = data?['jam_pulang'];
        _jamMasukTarget = waktu?['jam_masuk_mulai']; 
        _jamPulangTarget = waktu?['jam_pulang_mulai'];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Hitung sisa waktu menuju jam pulang ──────────────────
  String _hitungSisaWaktu() {
    if (_jamPulang != null) return 'Selesai';
    if (_jamPulangTarget == null) return '--:--';

    final now = TimeOfDay.now();
    final parts = _jamPulangTarget!.split(':');
    if (parts.length < 2) return '--:--';

    final targetH = int.tryParse(parts[0]) ?? 0;
    final targetM = int.tryParse(parts[1]) ?? 0;

    final nowMinutes = now.hour * 60 + now.minute;
    final targetMinutes = targetH * 60 + targetM;
    final diff = targetMinutes - nowMinutes;

    if (diff <= 0) return 'Tiba';

    final h = diff ~/ 60;
    final m = diff % 60;

    if (h == 0) return '${m}m lagi';
    if (m == 0) return '${h}j lagi';
    return '${h}j ${m}m';
  }

  // ── Format jam dari "HH:MM:SS" → "HH:MM" ────────────────
  String _formatJam(String? raw) {
    if (raw == null) return '--:--';
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return '--:--';
  }

  // ── Format jam pulang target ─────────────────────────────
  String _jamPulangDisplay() {
    if (_jamPulang != null) {
      return _formatJam(_jamPulang); // ✅ hanya real
    }
    return '--:--'; // ❌ jangan tampilkan target di sini
  }

  bool get _sudahMasuk => _jamMasuk != null;
  bool get _sudahPulang => _jamPulang != null;

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.09),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top accent line ───────────────────────────
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.0),
                    const Color(0xFF2563EB),
                    const Color(0xFF60A5FA),
                    const Color(0xFF2563EB).withOpacity(0.0),
                  ],
                ),
              ),
            ),

            // ── Main content row ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Row(
                children: [
                  // Jam Masuk
                 Expanded(
                  child: _ColumnItem(
                    label: 'Masuk',
                    value: _formatJam(_jamMasuk),
                    secondaryValue: _formatJam(_jamMasukTarget),
                    icon: Icons.schedule_rounded,
                    isActive: _sudahMasuk,
                    colorActive: const Color(0xFF2563EB),
                  ),
                ),

                  _Divider(),

                  // Sisa Waktu / Durasi
                 Expanded(
                    child: _ColumnItem(
                      label: _sudahPulang ? 'Durasi' : 'Sisa Waktu',
                      value: _sudahPulang
                          ? _hitungDurasiSelesai()
                          : _hitungSisaWaktu(),
 secondaryValue: null,
                      icon: Icons.timer_outlined,
                      isActive: _sudahMasuk,
                      colorActive: const Color(0xFF0EA5E9),
                      isCenterAccent: true,
                    ),
                  ),
                  _Divider(),

                  // Jam Pulang
                  Expanded(
                    child: _ColumnItem(
                      label: 'Pulang',
                      value: _jamPulangDisplay(),
                      secondaryValue: _formatJam(_jamPulangTarget),
                      icon: Icons.watch_later_outlined,
                      isActive: _sudahPulang,
                      isDimTarget: !_sudahPulang && _jamPulangTarget != null,
                      colorActive: const Color(0xFF10B981),
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

  // Hitung durasi real jika sudah pulang
  String _hitungDurasiSelesai() {
    if (_jamMasuk == null || _jamPulang == null) return '--';
    try {
      final mParts = _jamMasuk!.split(':');
      final pParts = _jamPulang!.split(':');
      final masukMin = int.parse(mParts[0]) * 60 + int.parse(mParts[1]);
      final pulangMin = int.parse(pParts[0]) * 60 + int.parse(pParts[1]);
      final diff = pulangMin - masukMin;
      if (diff <= 0) return '--';
      final h = diff ~/ 60;
      final m = diff % 60;
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}j';
      return '${h}j ${m}m';
    } catch (_) {
      return '--';
    }
  }

  // ── Skeleton loading ─────────────────────────────────────
  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2563EB).withOpacity(0.08),
            ),
          ),
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE2E8F0),
                          const Color(0xFFF8FAFC),
                          _shimmerAnim.value,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE2E8F0),
                          const Color(0xFFF8FAFC),
                          _shimmerAnim.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COLUMN ITEM — Tiap kolom (Masuk / Sisa / Pulang)
// ═══════════════════════════════════════════════════════════
class _ColumnItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final bool isDimTarget; // jam pulang target (belum tercapai)
  final bool isCenterAccent;
  final Color colorActive;
  final String? secondaryValue;

  const _ColumnItem({
  required this.label,
  required this.value,
  required this.icon,
  required this.isActive,
  required this.colorActive,
  this.secondaryValue, // 🔥 TAMBAH
  this.isDimTarget = false,
  this.isCenterAccent = false,
});
  @override
  Widget build(BuildContext context) {
final Color iconBg = const Color(0xFF2563EB); // 🔥 biru tetap
final Color iconColor = Colors.white; // 🔥 putih tetap

    final Color valueColor = isActive
        ? const Color(0xFF0F172A)
        : isDimTarget
            ? const Color(0xFF64748B)
            : const Color(0xFFCBD5E1);

    final Color labelColor = isActive
        ? const Color(0xFF64748B)
        : isDimTarget
            ? const Color(0xFF94A3B8)
            : const Color(0xFFCBD5E1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icon container ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
width: isCenterAccent ? 44 : 40,
height: isCenterAccent ? 44 : 40,
  decoration: BoxDecoration(
  color: iconBg,
  borderRadius: BorderRadius.circular(isCenterAccent ? 12 : 10),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF2563EB).withOpacity(0.35),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.6),
      blurRadius: 2,
      offset: const Offset(0, -1),
    ),
  ],
),
child: Stack(
  alignment: Alignment.center,
  children: [
    Icon(
      icon,
      color: iconColor.withOpacity(0.9),
      size: isCenterAccent ? 20 : 18, // 🔥 lebih besar = lebih tebal
    ),
    Icon(
      icon,
      color: iconColor,
      size: isCenterAccent ? 20 : 18,
    ),
  ],
),
          ),

          const SizedBox(height: 7),

          // ── Value (jam / sisa waktu) ────────────────────
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
              letterSpacing: 0.3,
              height: 1.1,
            ),
            child: Column(
  children: [
 if (label == 'Sisa Waktu' || label == 'Durasi') ...[
  const SizedBox(height: 14), // 🔥 pengganti tinggi dari --:--

  Text(
    value,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: Color(0xFF64748B),
    ),
  ),
] else ...[
  Text(
    value,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  ),
],
    if (secondaryValue != null) ...[
      const SizedBox(height: 2),
      Text(
        secondaryValue!,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF94A3B8),
        ),
      ),
    ],
  ],
),
          ),

          const SizedBox(height: 3),

          // ── Label ───────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: labelColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DIVIDER VERTIKAL
// ═══════════════════════════════════════════════════════════
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE2E8F0).withOpacity(0.1),
            const Color(0xFF2563EB).withOpacity(0.15),
            const Color(0xFFE2E8F0).withOpacity(0.1),
          ],
        ),
      ),
    );
  }
}