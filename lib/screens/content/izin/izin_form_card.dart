import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import '../../../services/izin_realtime_service.dart';
import 'izin_models.dart';

// ═══════════════════════════════════════════════════════════
// IZIN FORM MODAL — Dipanggil dari header sebagai bottom sheet
// Terhubung ke IzinRealtimeService → POST /izin
// ═══════════════════════════════════════════════════════════

/// Panggil fungsi ini dari IzinScreen saat button "Buat Izin" ditekan
Future<void> showIzinFormModal(BuildContext context,
    {VoidCallback? onSuccess}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) => _IzinFormSheet(onSuccess: onSuccess),
  );
}

// ─────────────────────────────────────────────────────────
// Bottom Sheet Container
// ─────────────────────────────────────────────────────────

class _IzinFormSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _IzinFormSheet({this.onSuccess});

  @override
  State<_IzinFormSheet> createState() => _IzinFormSheetState();
}

class _IzinFormSheetState extends State<_IzinFormSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // 🔧 FIX: dibuat nullable (JenisIzin?) & tanpa nilai default,
  // supaya saat modal pertama kali dibuka belum ada jenis izin
  // yang terpilih. Ini dibutuhkan agar perilaku "klik untuk pilih,
  // klik lagi untuk batal pilih" di _JenisIzinSelector bisa jalan,
  // dan validasi "wajib pilih jenis izin" bisa benar-benar terpicu.
  JenisIzin? _jenisIzin;
  final _keteranganController = TextEditingController();
  DateTime _tanggalIzin = DateTime.now();
  bool _sedangKirim = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatTanggalApi(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // 🔧 FIX: helper format tanggal versi Indonesia, dipakai untuk
  // menampilkan tanggal di pesan validasi.
  String _formatTanggalIndo(DateTime d) {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  Future<void> _kirim() async {
    if (_sedangKirim) return;

    // 🔧 FIX: VALIDASI TANGGAL — tidak boleh memilih tanggal
    // sebelum hari ini (dibandingkan tanggal saja, tanpa jam).
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggalDipilih =
        DateTime(_tanggalIzin.year, _tanggalIzin.month, _tanggalIzin.day);

    if (tanggalDipilih.isBefore(hariIni)) {
      HapticFeedback.vibrate();
      setState(() {
        _errorMsg =
            'Tidak bisa membuat izin sebelum tanggal ${_formatTanggalIndo(hariIni)}';
      });
      return;
    }

    // 🔧 FIX: VALIDASI JENIS IZIN — wajib dipilih sebelum kirim.
    if (_jenisIzin == null) {
      HapticFeedback.vibrate();
      setState(() {
        _errorMsg = 'Wajib pilih jenis izin';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _sedangKirim = true;
      _errorMsg = null;
    });

    final result = await IzinRealtimeService.create(
      tanggal: _formatTanggalApi(_tanggalIzin),
      jenis: _jenisIzin!.apiValue,
      keterangan: _keteranganController.text.trim().isEmpty
          ? null
          : _keteranganController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    } else {
      setState(() {
        _sedangKirim = false;
        _errorMsg = result['message'] ?? 'Gagal mengirim izin';
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    // 🔧 FIX: batasi tinggi maksimal sheet relatif ke tinggi layar,
    // supaya proporsional di semua ukuran HP (kecil maupun besar).
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          // 🔧 FIX: konten dibungkus SingleChildScrollView. Kalau total
          // tinggi konten (drag handle + header + error box + form)
          // lebih besar dari ruang yang tersedia (HP dengan layar pendek,
          // atau saat keyboard muncul), konten akan bisa di-scroll
          // alih-alih overflow seperti error "RenderFlex overflowed".
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag Handle ───────────────────────────
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Modal Header ──────────────────
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              FeatherIcons.fileText,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buat Izin Baru',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Isi form berikut dengan benar',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                FeatherIcons.x,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Error Message ─────────────────
                      if (_errorMsg != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFCA5A5), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(FeatherIcons.alertCircle,
                                  size: 13, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Tanggal Izin ──────────────────
                      _FormLabel(label: 'Tanggal Izin'),
                      const SizedBox(height: 6),
                      _TanggalPicker(
                        tanggal: _tanggalIzin,
                        onPilih: (t) => setState(() => _tanggalIzin = t),
                      ),
                      const SizedBox(height: 14),

                      // ── Jenis Izin ────────────────────
                      _FormLabel(label: 'Jenis Izin'),
                      const SizedBox(height: 8),
                      _JenisIzinSelector(
                        nilai: _jenisIzin,
                        onChange: (v) => setState(() => _jenisIzin = v),
                      ),
                      const SizedBox(height: 14),

                      // ── Keterangan ────────────────────
                      _FormLabel(label: 'Keterangan (Opsional)'),
                      const SizedBox(height: 6),
                      _TextAreaKeterangan(controller: _keteranganController),
                      const SizedBox(height: 20),

                      // ── Tombol Kirim ──────────────────
                      _TombolKirim(
                        sedangKirim: _sedangKirim,
                        onKirim: _kirim,
                      ),
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

// ─────────────────────────────────────────────────────────
// Sub Widgets
// ─────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TanggalPicker extends StatelessWidget {
  final DateTime tanggal;
  final ValueChanged<DateTime> onPilih;

  const _TanggalPicker({required this.tanggal, required this.onPilih});

  String _format(DateTime d) {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final hasil = await showDatePicker(
          context: context,
          initialDate: tanggal,
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB),
              ),
            ),
            child: child!,
          ),
        );
        if (hasil != null) onPilih(hasil);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6FF), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(FeatherIcons.calendar,
                size: 15, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text(
              _format(tanggal),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(FeatherIcons.chevronDown,
                size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _JenisIzinSelector extends StatelessWidget {
  // 🔧 FIX: nilai & callback dibuat nullable agar mendukung
  // status "belum ada jenis izin yang dipilih".
  final JenisIzin? nilai;
  final ValueChanged<JenisIzin?> onChange;

  const _JenisIzinSelector({required this.nilai, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: JenisIzin.values.map((jenis) {
        final aktif = nilai == jenis;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              // 🔧 FIX: TOGGLE — kalau chip ini sudah aktif/terpilih,
              // klik lagi akan membatalkan pilihan (kembali ke null /
              // tidak ada jenis izin yang terpilih). Kalau belum aktif,
              // klik akan memilih jenis ini.
              onChange(aktif ? null : jenis);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: jenis != JenisIzin.values.last ? 8 : 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: aktif
                    ? const Color(0xFF2563EB).withOpacity(0.08)
                    : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: aktif
                      ? const Color(0xFF2563EB).withOpacity(0.5)
                      : const Color(0xFFE2E8F0),
                  width: aktif ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconJenis(jenis),
                    size: 16,
                    color: aktif
                        ? const Color(0xFF2563EB)
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jenis.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight:
                          aktif ? FontWeight.w600 : FontWeight.w400,
                      color: aktif
                          ? const Color(0xFF2563EB)
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconJenis(JenisIzin jenis) {
    switch (jenis) {
      case JenisIzin.sakit:
        return FeatherIcons.thermometer;
      case JenisIzin.izin:
        return FeatherIcons.fileText;
      case JenisIzin.lainnya:
        return FeatherIcons.moreHorizontal;
    }
  }
}

class _TextAreaKeterangan extends StatelessWidget {
  final TextEditingController controller;

  const _TextAreaKeterangan({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6FF), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Tuliskan keterangan izin kamu...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _TombolKirim extends StatelessWidget {
  final bool sedangKirim;
  final VoidCallback onKirim;

  const _TombolKirim({
    required this.sedangKirim,
    required this.onKirim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: !sedangKirim
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: sedangKirim ? const Color(0xFFCBD5E1) : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: !sedangKirim
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: sedangKirim ? null : onKirim,
            borderRadius: BorderRadius.circular(13),
            child: Center(
              child: sedangKirim
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FeatherIcons.send,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Kirim Izin',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}