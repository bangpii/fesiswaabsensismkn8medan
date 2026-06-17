import 'dart:async';
import 'package:flutter/material.dart';
import 'absensi_models.dart';
import 'absensi_camera_modal.dart';
import 'absensi_barcode_modal.dart';
import '../../../services/absensi_realtime_service.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI ACTION BUTTON — Tombol utama absen (barcode/kamera)
// Menampilkan 2 opsi: Kamera & Barcode
// 🔥 REALTIME: Listen stream dari AbsensiRealtimeService
//    → Auto update status, kunci tombol saat libur
// ═══════════════════════════════════════════════════════════

class AbsensiActionButton extends StatefulWidget {
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
  State<AbsensiActionButton> createState() => _AbsensiActionButtonState();
}

class _AbsensiActionButtonState extends State<AbsensiActionButton> {
  // 🔥 REALTIME STATE
  StreamSubscription<AbsensiRealtimeState>? _sub;
  AbsensiAction _action = AbsensiAction.none;
  String _statusText = '';

  @override
  void initState() {
    super.initState();

    // 🔥 START REALTIME SERVICE
    AbsensiRealtimeService.start();

    // 🔥 LISTEN STREAM
    _sub = AbsensiRealtimeService.stream.listen((state) {
      if (!mounted) return;

      setState(() {
        _action = state.action;
        _statusText = state.statusText;
      });

      print("BUTTON REALTIME:");
      print(state.statusText);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 DETEKSI LIBUR
    final isLibur = _statusText.toLowerCase().contains("libur");
    // 🔥 TOMBOL DISABLED kalau action = none ATAU libur
    final tombolDisabled = _action == AbsensiAction.none || isLibur;
    // 🔥 Status selesai (sudah pulang)
    final selesai = widget.status == StatusAbsensi.sudahPulang;

    return Column(
      children: [
        // ── Row 2 Tombol: Kamera | Barcode ──────────────
        Row(
          children: [
            // Tombol Kamera
            Expanded(
              child: _TombolOpsi(
                ikon: isLibur
                    ? Icons.lock_rounded
                    : Icons.camera_alt_rounded,
                label: isLibur ? 'Dikunci' : 'Kamera',
                sublabel: isLibur ? _statusText : 'Foto Wajah',
                warna: isLibur
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF2563EB),
                aktif: !tombolDisabled && !selesai,
                onTap: tombolDisabled || selesai
                    ? null
                    : () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => AbsensiCameraModal(
                              onSimpan: (result) {
                                widget.onPressed?.call();
                              },
                            ),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 280),
                          ),
                        );
                      },
              ),
            ),

            const SizedBox(width: 14),

            // Tombol Barcode
            Expanded(
              child: _TombolOpsi(
                ikon: isLibur
                    ? Icons.lock_rounded
                    : Icons.qr_code_scanner_rounded,
                label: isLibur ? 'Dikunci' : 'Barcode',
                sublabel: isLibur ? _statusText : 'Scan Kode',
                warna: isLibur
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1D4ED8),
                aktif: !tombolDisabled && !selesai,
                onTap: tombolDisabled || selesai
                    ? null
                    : () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => AbsensiBarcodesModal(
                              onAbsensi: (result) {
                                widget.onPressed?.call();
                              },
                            ),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 280),
                          ),
                        );
                      },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Tombol Utama Absen ───────────────────────────
      ],
    );
  }
}

// ── Widget Tombol Opsi (Kamera / Barcode) ─────────────────
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
              color: aktif
                  ? warna.withValues(alpha: 0.2)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: aktif
                    ? warna.withValues(alpha: 0.08)
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
                  color: warna.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: warna, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
