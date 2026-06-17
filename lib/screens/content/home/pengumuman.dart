// lib/screens/content/home/pengumuman.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';
import '../../../services/cms_service.dart';

// ═══════════════════════════════════════════════════════════
// HELPER — parse Color dari hex string
// ═══════════════════════════════════════════════════════════
Color _parseColor(dynamic value,
    {Color fallback = const Color(0xFF2563EB)}) {
  if (value == null) return fallback;
  try {
    final hex = value.toString().replaceAll('#', '');
    if (hex.length == 6) return Color(int.parse('0xFF$hex'));
    if (hex.length == 8) return Color(int.parse('0x$hex'));
  } catch (_) {}
  return fallback;
}

// ═══════════════════════════════════════════════════════════
// HELPER — map icon string → IconData
// ═══════════════════════════════════════════════════════════
IconData _mapIcon(dynamic raw) {
  final s = (raw ?? '').toString().toLowerCase();
  switch (s) {
    case 'filetext':
    case 'file_text':
      return FeatherIcons.fileText;
    case 'clipboard':
      return FeatherIcons.clipboard;
    case 'bx_wallet':
      return Boxicons.bx_wallet;
    case 'alertcircle':
    case 'alert_circle':
      return FeatherIcons.alertCircle;
    case 'star':
      return FeatherIcons.star;
    case 'bx_calendar_event':
      return Boxicons.bx_calendar_event;
    case 'bell':
      return FeatherIcons.bell;
    case 'info':
      return FeatherIcons.info;
    case 'check':
    case 'check_circle':
      return FeatherIcons.checkCircle;
    default:
      return FeatherIcons.bell;
  }
}

// ═══════════════════════════════════════════════════════════
// HELPER — format waktu relatif dari created_at
// ═══════════════════════════════════════════════════════════
String _waktuRelatif(dynamic createdAt) {
  if (createdAt == null) return '';
  try {
    final dt   = DateTime.parse(createdAt.toString()).toLocal();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays    < 7)  return '${diff.inDays} hari lalu';

    final bulanMap = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulanMap[dt.month]}';
  } catch (_) {
    return '';
  }
}

// ═══════════════════════════════════════════════════════════
// 🆕 HELPER PUBLIK — parse raw CMS data jadi list pengumuman
// (pinned di depan, sisanya urut normal). Dipakai oleh
// SectionPengumuman dan juga bisa dipanggil dari luar (mis.
// tombol "Pengumuman" di Aksi Cepat Home).
// ═══════════════════════════════════════════════════════════
List<Map<String, dynamic>> parsePengumumanList(List<dynamic> raw) {
  final list = raw
      .where((s) => s['type'] == 'pengumuman')
      .map((s) {
        final d = s['data'] as Map<String, dynamic>? ?? {};
        return <String, dynamic>{
          'judul'   : d['judul']      ?? '',
          'isi'     : d['isi']        ?? '',
          'waktu'   : _waktuRelatif(d['created_at']),
          'icon'    : _mapIcon(d['icon']),
          'warna'   : _parseColor(d['warna']),
          'isPinned': d['is_pinned']  ?? false,
        };
      })
      .toList();

  // Pinned dulu
  list.sort((a, b) {
    final aPin = (a['isPinned'] as bool) ? 0 : 1;
    final bPin = (b['isPinned'] as bool) ? 0 : 1;
    return aPin.compareTo(bPin);
  });

  return list;
}

// ═══════════════════════════════════════════════════════════
// 🆕 HELPER PUBLIK — buka modal "Semua Pengumuman" dari mana
// saja, langsung dari data cache CMS. Dipakai oleh tombol
// "Pengumuman" di Aksi Cepat Home agar siswa langsung diarahkan
// ke daftar pengumuman tanpa pindah halaman.
// ═══════════════════════════════════════════════════════════
void bukaModalSemuaPengumuman(BuildContext context, List<dynamic> rawCms) {
  final pengumuman = parsePengumumanList(rawCms);

  HapticFeedback.lightImpact();
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => _ModalSemuaPengumuman(
        pengumuman: pengumuman,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════
class _PengumumanItem {
  final String   judul;
  final String   isi;
  final String   waktu;
  final IconData icon;
  final Color    warna;
  final bool     isPinned;

  const _PengumumanItem({
    required this.judul,
    required this.isi,
    required this.waktu,
    required this.icon,
    required this.warna,
    required this.isPinned,
  });
}

// ═══════════════════════════════════════════════════════════
// KARTU PENGUMUMAN — list item
// ═══════════════════════════════════════════════════════════
class KartuPengumuman extends StatelessWidget {
  final Map<String, dynamic> data;
  const KartuPengumuman({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final warna = data['warna'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _bukaDetail(context, data);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: warna.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(data['icon'] as IconData, size: 18, color: warna),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Pin badge (kalau pinned)
                      if (data['isPinned'] == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: warna.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FeatherIcons.bookmark,
                                  size: 9, color: warna),
                              const SizedBox(width: 3),
                              Text(
                                'Pinned',
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  color: warna,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          data['judul'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['waktu'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data['isi'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Hint "tap to read"
                  Row(
                    children: [
                      Icon(FeatherIcons.chevronDown,
                          size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'Tap untuk baca selengkapnya',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.textMuted,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODAL DETAIL PENGUMUMAN — tap salah satu
// ═══════════════════════════════════════════════════════════
void _bukaDetail(BuildContext context, Map<String, dynamic> data) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => _ModalDetailPengumuman(data: data),
    ),
  );
}

class _ModalDetailPengumuman extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ModalDetailPengumuman({required this.data});

  @override
  Widget build(BuildContext context) {
    final warna = data['warna'] as Color;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Backdrop blur ──────────────────────────────
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: const Color(0xFF0D1B2E).withOpacity(0.6),
                ),
              ),
            ),

            // ── Modal card di tengah ───────────────────────
            Center(
              child: GestureDetector(
                onTap: () {}, // cegah tap modal menutup
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * v,
                      child: child,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: warna.withOpacity(0.18),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Top accent bar + ikon ──────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                warna.withOpacity(0.12),
                                warna.withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: warna.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Ikon besar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      warna,
                                      warna.withOpacity(0.75),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: warna.withOpacity(0.38),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  data['icon'] as IconData,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (data['isPinned'] == true)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 4),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                warna.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(FeatherIcons.bookmark,
                                                  size: 9, color: warna),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Pinned',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 8.5,
                                                  color: warna,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Text(
                                      data['judul'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E3A5F),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data['waktu'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color:
                                            const Color(0xFF6B8CAE),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tombol close
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: warna.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(11),
                                    border: Border.all(
                                      color: warna.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    FeatherIcons.x,
                                    size: 16,
                                    color: warna,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Isi konten ─────────────────────
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            data['isi'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF3D5A7A),
                              height: 1.65,
                            ),
                          ),
                        ),

                        // ── Tombol tutup bawah ─────────────
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    warna,
                                    warna.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: warna.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Tutup',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
// KARTU MODAL — versi lebih lebar untuk modal semua
// ═══════════════════════════════════════════════════════════
class _KartuPengumumanModal extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _KartuPengumumanModal({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final warna = data['warna'] as Color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _bukaDetail(context, data);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: warna.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: warna.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      warna.withOpacity(0.15),
                      warna.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: warna.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                    data['icon'] as IconData, size: 20, color: warna),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data['judul'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A5F),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: warna.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['waktu'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: warna,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['isi'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF4B6080),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(FeatherIcons.chevronDown,
                            size: 10,
                            color: warna.withOpacity(0.6)),
                        const SizedBox(width: 3),
                        Text(
                          'Tap untuk baca selengkapnya',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: warna.withOpacity(0.7),
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODAL SEMUA PENGUMUMAN
// ═══════════════════════════════════════════════════════════
class _ModalSemuaPengumuman extends StatelessWidget {
  final List<Map<String, dynamic>> pengumuman;
  const _ModalSemuaPengumuman({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: const Color(0xFF0D1B2E).withOpacity(0.55),
                ),
              ),
            ),

            // Bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Transform.translate(
                    offset: Offset(0, 60 * (1 - v)),
                    child: Opacity(opacity: v, child: child),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height * 0.82,
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
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Header modal
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 16, 0),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1D4ED8),
                                      Color(0xFF2563EB)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Boxicons.bx_bell,
                                    size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Semua Pengumuman',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E3A5F),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      '${pengumuman.length} pengumuman aktif',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B8CAE),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                        .withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.15),
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

                        // Divider
                        Container(
                          margin:
                              const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB).withOpacity(0.0),
                                const Color(0xFF2563EB)
                                    .withOpacity(0.15),
                                const Color(0xFF2563EB).withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),

                        // List
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 16, 20, 28),
                            physics: const BouncingScrollPhysics(),
                            itemCount: pengumuman.length,
                            itemBuilder: (ctx, i) =>
                                _KartuPengumumanModal(
                              data: pengumuman[i],
                              index: i,
                            ),
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
// SECTION PENGUMUMAN — stateful, subscribe ke CmsService.stream
// ═══════════════════════════════════════════════════════════
class SectionPengumuman extends StatefulWidget {
  const SectionPengumuman({super.key});

  @override
  State<SectionPengumuman> createState() => _SectionPengumumanState();
}

class _SectionPengumumanState extends State<SectionPengumuman> {
  static const int _batasAwal = 4;

  List<Map<String, dynamic>> _pengumuman = [];
  bool _isLoading = true;

  StreamSubscription<List<dynamic>>? _sub;

  @override
  void initState() {
    super.initState();

    _applyData(CmsService.cache);

    _sub = CmsService.stream.listen((raw) {
      if (mounted) _applyData(raw);
    });

    CmsService.load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── parse ─────────────────────────────────────────────

  void _applyData(List<dynamic> raw) {
    final list = parsePengumumanList(raw);

    if (!mounted) return;
    setState(() {
      _pengumuman = list;
      _isLoading  = false;
    });
  }

  // ── modal semua ───────────────────────────────────────

  void _bukaModal() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        pageBuilder: (ctx, _, __) => _ModalSemuaPengumuman(
          pengumuman: _pengumuman,
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_pengumuman.isEmpty) return _buildEmpty();

    final tampil = _pengumuman.length > _batasAwal
        ? _pengumuman.sublist(0, _batasAwal)
        : _pengumuman;
    final adaLebih = _pengumuman.length > _batasAwal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Boxicons.bx_bell,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Pengumuman',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            if (adaLebih)
              GestureDetector(
                onTap: _bukaModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.28),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${_pengumuman.length}',
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

        // ── List ───────────────────────────────────────
        ...tampil.map((p) => KartuPengumuman(data: p)),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ShimmerBox(width: 16, height: 16, radius: 4),
            const SizedBox(width: 6),
            _ShimmerBox(width: 100, height: 14, radius: 4),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ShimmerBox(
                width: double.infinity, height: 72, radius: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Boxicons.bx_bell,
                size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Pengumuman',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(FeatherIcons.bell,
                  size: 28,
                  color: AppColors.textMuted.withOpacity(0.35)),
              const SizedBox(height: 8),
              Text(
                'Belum ada pengumuman',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHIMMER BOX
// ═══════════════════════════════════════════════════════════
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withOpacity(_anim.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}