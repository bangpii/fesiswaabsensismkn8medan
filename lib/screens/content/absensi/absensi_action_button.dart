import 'package:flutter/material.dart';
import 'absensi_models.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI ACTION BUTTON — Tombol utama absen (barcode/kamera)
// Menampilkan 2 opsi: Kamera & Barcode
// ═══════════════════════════════════════════════════════════

class AbsensiActionButton extends StatelessWidget {
  final StatusAbsensi status;
  final bool sedangMemproses;
  final Animation<double> pulseAnim;
  final VoidCallback? onPressed;

  const AbsensiActionButton({
    super.key,
    required this.status,
    required this.sedangMemproses,
    required this.pulseAnim,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selesai = status == StatusAbsensi.sudahPulang;

    return Column(
      children: [
        // ── Row 2 Tombol: Kamera | Barcode ──────────
        Row(
          children: [
            // Tombol Kamera
            Expanded(
              child: _TombolOpsi(
                ikon: Icons.camera_alt_rounded,
                label: 'Kamera',
                sublabel: 'Foto Wajah',
                warna: const Color(0xFF7C3AED),
                aktif: !selesai,
                onTap: selesai ? null : onPressed,
              ),
            ),
            const SizedBox(width: 14),
            // Tombol Barcode
            Expanded(
              child: _TombolOpsi(
                ikon: Icons.qr_code_scanner_rounded,
                label: 'Barcode',
                sublabel: 'Scan Kode',
                warna: const Color(0xFF1D4ED8),
                aktif: !selesai,
                onTap: selesai ? null : onPressed,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Tombol Utama Absen ───────────────────────────
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: (!selesai && !sedangMemproses) ? pulseAnim.value : 1.0,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: selesai
                    ? const LinearGradient(
                        colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                      )
                    : LinearGradient(
                        colors: [
                          status.warna,
                          status.warna.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: selesai
                    ? []
                    : [
                        BoxShadow(
                          color: status.warna.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: sedangMemproses
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Memverifikasi...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selesai
                                ? Icons.check_circle_rounded
                                : status.ikon,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status.labelTombol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        if (selesai) ...[
          const SizedBox(height: 10),
          Text(
            'Absensi hari ini sudah selesai. Sampai jumpa besok! 👋',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}

// ── Widget Tombol Opsi (Kamera / Fingerprint) ─────────────
class _TombolOpsi extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String sublabel;
  final Color warna;
  final bool aktif;
  final VoidCallback? onTap;

  const _TombolOpsi({
    required this.ikon,
    required this.label,
    required this.sublabel,
    required this.warna,
    required this.aktif,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aktif ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: aktif ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: aktif ? warna.withOpacity(0.2) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: aktif
                    ? warna.withOpacity(0.08)
                    : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: warna, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}