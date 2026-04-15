import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'izin_models.dart';

// ═══════════════════════════════════════════════════════════
// IZIN FORM CARD — Form pengiriman izin ke guru
// ═══════════════════════════════════════════════════════════

class IzinFormCard extends StatefulWidget {
  final VoidCallback? onKirim;

  const IzinFormCard({super.key, this.onKirim});

  @override
  State<IzinFormCard> createState() => _IzinFormCardState();
}

class _IzinFormCardState extends State<IzinFormCard> {
  JenisIzin _jenisIzin = JenisIzin.sakit;
  final _pesanController = TextEditingController();
  String _namaGuru = 'Bu Rahma';
  DateTime _tanggalIzin = DateTime.now();
  bool _sedangKirim = false;

  final List<String> _daftarGuru = [
    'Bu Rahma',
    'Pak Budi',
    'Bu Sari',
    'Pak Hendra',
    'Bu Dewi',
  ];

  @override
  void dispose() {
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _kirimIzin() async {
    if (_pesanController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _sedangKirim = true);
    await Future.delayed(const Duration(seconds: 2));
    HapticFeedback.heavyImpact();
    setState(() {
      _sedangKirim = false;
      _pesanController.clear();
    });
    widget.onKirim?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ─────────────────────────────────────
            Row(
              children: [
                Icon(
                  FeatherIcons.send,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Buat Izin Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Kepada (Guru) ──────────────────────────────
            _LabelField(label: 'Kepada Guru'),
            const SizedBox(height: 6),
            _DropdownGuru(
              nilai: _namaGuru,
              daftar: _daftarGuru,
              onChange: (v) => setState(() => _namaGuru = v!),
            ),
            const SizedBox(height: 12),

            // ── Tanggal Izin ───────────────────────────────
            _LabelField(label: 'Tanggal Izin'),
            const SizedBox(height: 6),
            _TanggalPicker(
              tanggal: _tanggalIzin,
              onPilih: (t) => setState(() => _tanggalIzin = t),
            ),
            const SizedBox(height: 12),

            // ── Jenis Izin ─────────────────────────────────
            _LabelField(label: 'Jenis Izin'),
            const SizedBox(height: 8),
            _JenisIzinSelector(
              nilai: _jenisIzin,
              onChange: (v) => setState(() => _jenisIzin = v),
            ),
            const SizedBox(height: 12),

            // ── Pesan / Keterangan ─────────────────────────
            _LabelField(label: 'Keterangan'),
            const SizedBox(height: 6),
            _TextAreaPesan(controller: _pesanController),
            const SizedBox(height: 16),

            // ── Tombol Kirim ───────────────────────────────
            _TombolKirim(
              sedangKirim: _sedangKirim,
              enabled: !_sedangKirim,
              onKirim: _kirimIzin,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────

class _LabelField extends StatelessWidget {
  final String label;
  const _LabelField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DropdownGuru extends StatelessWidget {
  final String nilai;
  final List<String> daftar;
  final ValueChanged<String?> onChange;

  const _DropdownGuru({
    required this.nilai,
    required this.daftar,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: nilai,
          isExpanded: true,
          icon: Icon(
            FeatherIcons.chevronDown,
            size: 15,
            color: AppColors.textMuted,
          ),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: daftar
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: onChange,
        ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
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
              colorScheme: ColorScheme.light(primary: AppColors.accent),
            ),
            child: child!,
          ),
        );
        if (hasil != null) onPilih(hasil);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(FeatherIcons.calendar, size: 14, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              _format(tanggal),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(FeatherIcons.chevronDown, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _JenisIzinSelector extends StatelessWidget {
  final JenisIzin nilai;
  final ValueChanged<JenisIzin> onChange;

  const _JenisIzinSelector({required this.nilai, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: JenisIzin.values.map((jenis) {
        final aktif = nilai == jenis;
        return GestureDetector(
          onTap: () => onChange(jenis),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: aktif
                  ? AppColors.accent.withOpacity(0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: aktif
                    ? AppColors.accent.withOpacity(0.4)
                    : AppColors.border,
                width: aktif ? 1.5 : 1,
              ),
            ),
            child: Text(
              jenis.label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                color: aktif ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TextAreaPesan extends StatelessWidget {
  final TextEditingController controller;

  const _TextAreaPesan({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
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
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

class _TombolKirim extends StatelessWidget {
  final bool sedangKirim;
  final bool enabled;
  final VoidCallback onKirim;

  const _TombolKirim({
    required this.sedangKirim,
    required this.enabled,
    required this.onKirim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                )
              : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onKirim : null,
            borderRadius: BorderRadius.circular(12),
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