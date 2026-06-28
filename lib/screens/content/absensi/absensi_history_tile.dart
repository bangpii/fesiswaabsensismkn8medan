// lib/screens/content/absensi/absensi_history_tile.dart
//
// 🔥 ABSENSI HISTORY SECTION — Modern Card UI
// ─────────────────────────────────────────────
// • Data dari AbsensiHistoryService (realtime Reverb)
// • Card per hari, iPhone-style dengan toggle Masuk/Pulang
// • Foto absen ditampilkan besar di tengah card
// • Icon barcode jika absen via barcode (bukan foto)
// • Fallback icon user kalau tidak ada foto / alpa
// • Status chip di header + jam + keterangan
// • Scroll horizontal, animasi stagger

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/absensi_history_service.dart';

// ════════════════════════════════════════════════════
// ROOT WIDGET — AbsensiHistorySection
// ════════════════════════════════════════════════════

class AbsensiHistorySection extends StatefulWidget {
  const AbsensiHistorySection({super.key});

  @override
  State<AbsensiHistorySection> createState() => _AbsensiHistorySectionState();
}

class _AbsensiHistorySectionState extends State<AbsensiHistorySection> {
  StreamSubscription<AbsensiHistoryResponse>? _sub;
  AbsensiHistoryResponse? _response;
  bool _loading = true;

  // ═══════════════════════════════════════════════
  // 🔥 FILTER MINGGU INI — logika konsisten dengan backend
  // ═══════════════════════════════════════════════
  List<RiwayatAbsensi> get _mingguIni {
    if (_response == null) return [];

    final now = DateTime.now();

    // 🔥 Referensi: Senin pertama bulan ini (sama dengan backend)
    DateTime firstMonday = DateTime(now.year, now.month, 1);
    while (firstMonday.weekday != DateTime.monday) {
      firstMonday = firstMonday.add(const Duration(days: 1));
    }

    // 🔥 Hitung mingguSekarang berdasarkan tanggal hari ini
    // Kalau Sabtu/Minggu, tetap pakai hari Jumat terakhir sebagai acuan
    final DateTime referenceDay;
    if (now.weekday == DateTime.saturday) {
      referenceDay = now.subtract(const Duration(days: 1)); // Jumat
    } else if (now.weekday == DateTime.sunday) {
      referenceDay = now.subtract(const Duration(days: 2)); // Jumat
    } else {
      referenceDay = now;
    }

    // Kalau referenceDay sebelum firstMonday (awal bulan weekend), pakai minggu 1
    final diffDays = referenceDay.isAfter(firstMonday) || referenceDay.isAtSameMomentAs(firstMonday)
        ? referenceDay.difference(firstMonday).inDays
        : 0;

    final mingguSekarang = (diffDays ~/ 7) + 1;

    // 🔥 Filter data: mingguKe cocok + bulan & tahun sama
    final filtered = _response!.data.where((item) {
      try {
        final d = DateTime.parse(item.tanggal);
        return item.mingguKe == mingguSekarang &&
            d.month == now.month &&
            d.year == now.year;
      } catch (_) {
        return false;
      }
    }).toList();

    // 🔥 Sort by tanggal aktual (ascending = Senin dulu)
    filtered.sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return filtered;
  }

  String get _namaBulan {
    const bulan = [
      '',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return bulan[DateTime.now().month];
  }

  String get _labelMinggu {
    final now = DateTime.now();

    // Hitung minggu ke berapa (konsisten dengan logika _mingguIni)
    DateTime firstMonday = DateTime(now.year, now.month, 1);
    while (firstMonday.weekday != DateTime.monday) {
      firstMonday = firstMonday.add(const Duration(days: 1));
    }

    final DateTime referenceDay;
    if (now.weekday == DateTime.saturday) {
      referenceDay = now.subtract(const Duration(days: 1));
    } else if (now.weekday == DateTime.sunday) {
      referenceDay = now.subtract(const Duration(days: 2));
    } else {
      referenceDay = now;
    }

    final diffDays = referenceDay.isAfter(firstMonday) || referenceDay.isAtSameMomentAs(firstMonday)
        ? referenceDay.difference(firstMonday).inDays
        : 0;

    final mingguKe = (diffDays ~/ 7) + 1;
    return 'Minggu ke-$mingguKe';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AbsensiHistoryService.start();
    _sub = AbsensiHistoryService.stream.listen((res) {
      if (mounted) {
        setState(() {
          _response = res;
          _loading = false;
        });
      }
    });
    await AbsensiHistoryService.load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _mingguIni;

    if (!_loading && items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 3.5,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Absensi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _namaBulan,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                            fontFamily: 'Poppins',
                            letterSpacing: 0.1,
                          ),
                        ),
                        const TextSpan(
                          text: '  ·  ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: _labelMinggu,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!_loading && items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} hari',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Loading Skeleton ─────────────────────────
        if (_loading)
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, i) => _SkeletonCard(index: i),
            ),
          ),

        // ── Card List ────────────────────────────────
        if (!_loading && items.isNotEmpty)
          SizedBox(
            height: 360,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _AbsensiCard(
                  data: items[index],
                  index: index,
                );
              },
            ),
          ),

        // ── Info Box ─────────────────────────────────
        if (!_loading && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketentuan Absensi Harian',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Absen masuk sebelum 07:30 · Absen pulang setelah 15:00 untuk status hadir yang valid.',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                            fontFamily: 'Poppins',
                            height: 1.5,
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
}

// ════════════════════════════════════════════════════
// MAIN CARD — dengan state toggle Masuk/Pulang
// ════════════════════════════════════════════════════

class _AbsensiCard extends StatefulWidget {
  final RiwayatAbsensi data;
  final int index;

  const _AbsensiCard({required this.data, required this.index});

  @override
  State<_AbsensiCard> createState() => _AbsensiCardState();
}

class _AbsensiCardState extends State<_AbsensiCard>
    with SingleTickerProviderStateMixin {
  // false = Masuk, true = Pulang
  bool _showPulang = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode(bool pulang) {
    if (_showPulang == pulang) return;
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _showPulang = pulang);
        _fadeCtrl.forward();
      }
    });
  }

  // ── Status helpers ────────────────────────────────
  Color get _statusColor {
    switch (widget.data.status.toLowerCase()) {
      case 'hadir':
        return const Color(0xFF16A34A);
      case 'terlambat':
        return const Color(0xFFF59E0B);
      case 'alpa':
        return const Color(0xFFDC2626);
      case 'izin':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _statusBg {
    switch (widget.data.status.toLowerCase()) {
      case 'hadir':
        return const Color(0xFFDCFCE7);
      case 'terlambat':
        return const Color(0xFFFEF3C7);
      case 'alpa':
        return const Color(0xFFFEE2E2);
      case 'izin':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String get _statusLabel {
    switch (widget.data.status.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'alpa':
        return 'Alpa';
      case 'izin':
        return 'Izin';
      default:
        return widget.data.status;
    }
  }

  IconData get _statusIcon {
    switch (widget.data.status.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle_rounded;
      case 'terlambat':
        return Icons.access_time_rounded;
      case 'alpa':
        return Icons.cancel_rounded;
      case 'izin':
        return Icons.assignment_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── Data aktif sesuai mode ──────────────────────
  String? get _activeFoto =>
      _showPulang ? widget.data.fotoPulang : widget.data.fotoMasuk;

  String? get _activeJam =>
      _showPulang ? widget.data.jamPulang : widget.data.jamMasuk;

  bool get _activeHasSudah =>
      _showPulang ? widget.data.sudahPulang : widget.data.sudahMasuk;

  String get _activeLabel => _showPulang ? 'Pulang' : 'Masuk';

  // 🔥 Tipe media aktif (camera / barcode)
  String? get _activeTipe =>
      _showPulang ? widget.data.tipePulang : widget.data.tipeMasuk;

  bool get _isBarcode => _activeTipe == 'barcode';

  // ── Keterangan dinamis ──────────────────────────
  String get _keteranganText {
    if (_showPulang) {
      if (!widget.data.sudahPulang) {
        if (widget.data.sudahMasuk) {
          return 'Belum absen pulang';
        }
        return 'Tidak ada data absen pulang';
      }
      // 🔥 keterangan kustom untuk barcode pulang
      if (_isBarcode) return 'Pulang via Barcode ✓';
      return widget.data.keterangan != null &&
              widget.data.keterangan!.isNotEmpty
          ? widget.data.keterangan!
          : 'Absen Pulang Tercatat';
    } else {
      if (!widget.data.sudahMasuk) {
        if (widget.data.status.toLowerCase() == 'alpa') {
          return 'Tidak hadir (Alpa)';
        }
        return 'Tidak ada data absen masuk';
      }
      // 🔥 keterangan kustom untuk barcode masuk
      if (_isBarcode) {
        return widget.data.status.toLowerCase() == 'terlambat'
            ? 'Masuk via Barcode (Terlambat)'
            : 'Masuk via Barcode ✓';
      }
      if (widget.data.keterangan != null &&
          widget.data.keterangan!.isNotEmpty) {
        return widget.data.keterangan!;
      }
      switch (widget.data.status.toLowerCase()) {
        case 'hadir':
          return 'Absen Masuk Tepat Waktu!';
        case 'terlambat':
          return 'Absen Masuk Terlambat';
        default:
          return 'Absen Masuk Tercatat';
      }
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final d = DateTime.parse(tanggal);
      const bulan = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${bulan[d.month]} ${d.year}';
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (widget.index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(24 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Container(
        width: 172,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _statusColor.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top status strip ─────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor,
                      _statusColor.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // ── Header: Hari + Tanggal + Status Badge ──
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                        color: Color(0xFFEEF2F7), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.hari,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                            letterSpacing: -0.3,
                            height: 1,
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon,
                                  size: 9, color: _statusColor),
                              const SizedBox(width: 3),
                              Text(
                                _statusLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                  fontFamily: 'Poppins',
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(data.tanggal),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Poppins',
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body: Foto + Jam ─────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Column(
                    children: [
                      // ── Foto / Barcode / Placeholder ──────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: GestureDetector(
                          // Kalau barcode, tidak ada fullscreen foto
                          onTap: _activeHasSudah && _activeFoto != null && !_isBarcode
                              ? () => _showFotoDialog(
                                  context, _activeFoto!, _activeLabel)
                              : null,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: _activeHasSudah
                                  ? _statusColor.withOpacity(0.06)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _activeHasSudah
                                    ? _statusColor.withOpacity(0.20)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.5),
                              child: _buildFotoContent(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Jam Absen ──────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Text(
                              'Jam $_activeLabel',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: _activeHasSudah
                                    ? (_showPulang
                                        ? const Color(0xFF64748B)
                                        : _statusColor.withOpacity(0.7))
                                    : const Color(0xFFCBD5E1),
                                fontFamily: 'Poppins',
                                letterSpacing: 0.3,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activeHasSudah && _activeJam != null
                                  ? _activeJam!
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _activeHasSudah && _activeJam != null
                                    ? (_showPulang
                                        ? const Color(0xFF334155)
                                        : _statusColor)
                                    : const Color(0xFFCBD5E1),
                                fontFamily: 'Poppins',
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Toggle Masuk / Pulang ───────────
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _ToggleTab(
                              label: 'Masuk',
                              isActive: !_showPulang,
                              activeColor: _statusColor,
                              onTap: () => _toggleMode(false),
                            ),
                            Container(
                              width: 1,
                              height: 14,
                              margin: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            _ToggleTab(
                              label: 'Pulang',
                              isActive: _showPulang,
                              activeColor: const Color(0xFF475569),
                              onTap: () => _toggleMode(true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Keterangan Footer ────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                        color: Color(0xFFEEF2F7), width: 1),
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Center(
                    child: Text(
                      _keteranganText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: _keteranganColor,
                        fontFamily: 'Poppins',
                        height: 1.4,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // 🔥 FOTO CONTENT — camera / barcode / placeholder
  // ════════════════════════════════════════════════
  Widget _buildFotoContent() {
    // 🔥 BARCODE — tampilkan icon barcode, bukan foto
    if (_activeHasSudah && _isBarcode) {
      return _BarcodePlaceholder(color: _statusColor);
    }

    // 🔥 CAMERA — tampilkan foto selfie
    if (_activeHasSudah && _activeFoto != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _activeFoto!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFF1F5F9),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _statusColor.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _UserPlaceholder(
                color: _statusColor, hasData: true),
          ),
          // Zoom hint overlay
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.40),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.zoom_in_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
        ],
      );
    }

    // 🔥 PLACEHOLDER — belum absen / alpa
    return _UserPlaceholder(
      color: _activeHasSudah ? _statusColor : const Color(0xFFCBD5E1),
      hasData: _activeHasSudah,
      isAlpa: widget.data.status.toLowerCase() == 'alpa' && !_showPulang,
    );
  }

  Color get _keteranganColor {
    if (!_activeHasSudah) {
      if (widget.data.status.toLowerCase() == 'alpa') {
        return const Color(0xFFDC2626);
      }
      return const Color(0xFF94A3B8);
    }
    if (!_showPulang) {
      switch (widget.data.status.toLowerCase()) {
        case 'hadir':
          return const Color(0xFF16A34A);
        case 'terlambat':
          return const Color(0xFFF59E0B);
        default:
          return const Color(0xFF64748B);
      }
    }
    return const Color(0xFF64748B);
  }

  void _showFotoDialog(BuildContext context, String url, String labelFoto) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Foto $labelFoto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.20), width: 1),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
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

// ════════════════════════════════════════════════════
// 🔥 BARCODE PLACEHOLDER — tampil kalau absen via barcode
// ════════════════════════════════════════════════════

class _BarcodePlaceholder extends StatelessWidget {
  final Color color;

  const _BarcodePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.05),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lingkaran icon barcode
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.qr_code_rounded,
                size: 28,
                color: color.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Via Barcode',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.65),
                fontFamily: 'Poppins',
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TOGGLE TAB — Masuk / Pulang
// ════════════════════════════════════════════════════

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF94A3B8),
                fontFamily: 'Poppins',
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// USER PLACEHOLDER — fallback foto
// ════════════════════════════════════════════════════

class _UserPlaceholder extends StatelessWidget {
  final Color color;
  final bool hasData;
  final bool isAlpa;

  const _UserPlaceholder({
    required this.color,
    required this.hasData,
    this.isAlpa = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.06),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isAlpa
                    ? Icons.person_off_rounded
                    : (hasData
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded),
                size: 20,
                color: color.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 48,
              height: 22,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: color.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// SKELETON LOADING CARD
// ════════════════════════════════════════════════════

class _SkeletonCard extends StatefulWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 172,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 56,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, color: Color(0xFFEEF2F7), thickness: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 34,
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════
// LEGACY COMPAT
// ════════════════════════════════════════════════════

class AbsensiHistoryTile extends StatelessWidget {
  final dynamic riwayat;
  final int index;

  const AbsensiHistoryTile({
    super.key,
    required this.riwayat,
    required this.index,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}