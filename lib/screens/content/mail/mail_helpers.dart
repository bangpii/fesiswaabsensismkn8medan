import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'mail_models.dart';

// ═══════════════════════════════════════════════════════════
// MAIL HELPERS — Shared utilities & reusable widgets
// ═══════════════════════════════════════════════════════════

// ── Design Tokens ─────────────────────────────────────────
const Color kMailBiru        = Color(0xFF1D4ED8);
const Color kMailBiruLight   = Color(0xFF3B82F6);
const Color kMailBiruMuda    = Color(0xFFEFF6FF);
const Color kMailBiruBorder  = Color(0xFFBFDBFE);
const Color kMailTextPrimary   = Color(0xFF0F172A);
const Color kMailTextSecondary = Color(0xFF64748B);
const Color kMailTextMuted     = Color(0xFF94A3B8);
const Color kMailBorder      = Color(0xFFE2E8F0);
const Color kMailBg          = Color(0xFFF0F6FF);
const Color kMailSurface     = Color(0xFFFFFFFF);
const Color kMailSuccess     = Color(0xFF10B981);
const Color kMailWarning     = Color(0xFFF59E0B);
const Color kMailDanger      = Color(0xFFEF4444);

// ── Format Waktu ──────────────────────────────────────────
String formatWaktuSingkat(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 7) {
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return hari[dt.weekday - 1];
  }
  return '${dt.day}/${dt.month}';
}

String formatWaktuLengkap(DateTime dt) {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatWaktuChat(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatTanggalIzin(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

// ── Status Colors ─────────────────────────────────────────
Color statusColor(IzinStatus s) {
  switch (s) {
    case IzinStatus.disetujui: return kMailSuccess;
    case IzinStatus.ditolak: return kMailDanger;
    case IzinStatus.pending: return kMailWarning;
  }
}

Color statusBg(IzinStatus s) {
  switch (s) {
    case IzinStatus.disetujui: return const Color(0xFFD1FAE5);
    case IzinStatus.ditolak: return const Color(0xFFFEE2E2);
    case IzinStatus.pending: return const Color(0xFFFEF3C7);
  }
}

IconData statusIcon(IzinStatus s) {
  switch (s) {
    case IzinStatus.disetujui: return FeatherIcons.checkCircle;
    case IzinStatus.ditolak: return FeatherIcons.xCircle;
    case IzinStatus.pending: return FeatherIcons.clock;
  }
}

// ── Jenis Badge Color ─────────────────────────────────────

// ── Shared Widget: Avatar Inisial ──────────────────────────
class MailAvatar extends StatelessWidget {
  final String inisial;
  final double ukuran;
  final bool kecil;
  final Color? warna;

  const MailAvatar({
    super.key,
    required this.inisial,
    required this.ukuran,
    this.kecil = false,
    this.warna,
  });

  @override
  Widget build(BuildContext context) {
    final bg = warna ?? kMailBiru;
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, Color.lerp(bg, Colors.black, 0.18) ?? bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kecil ? 8 : ukuran * 0.3),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          inisial,
          style: GoogleFonts.poppins(
            fontSize: ukuran * (kecil ? 0.33 : 0.3),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────
class IzinStatusBadge extends StatelessWidget {
  final IzinStatus status;
  final bool compact;

  const IzinStatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: compact ? 9 : 10, color: statusColor(status)),
          const SizedBox(width: 3),
          Text(
            status == IzinStatus.disetujui
                ? 'Disetujui'
                : status == IzinStatus.ditolak
                    ? 'Ditolak'
                    : 'Pending',
            style: GoogleFonts.poppins(
              fontSize: compact ? 9 : 9.5,
              fontWeight: FontWeight.w700,
              color: statusColor(status),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jenis Badge ───────────────────────────────────────────
class IzinJenisBadge extends StatelessWidget {
  final IzinJenis jenis;

  const IzinJenisBadge({super.key, required this.jenis});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Read Receipt ──────────────────────────────────────────
class ReadReceiptIcon extends StatelessWidget {
  final bool isRead;
  final double size;

  const ReadReceiptIcon({super.key, required this.isRead, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          FeatherIcons.check,
          size: size,
          color: isRead ? const Color(0xFF3B82F6) : kMailTextMuted,
        ),
        Transform.translate(
          offset: Offset(-size * 0.45, 0),
          child: Icon(
            FeatherIcons.check,
            size: size,
            color: isRead ? const Color(0xFF3B82F6) : kMailTextMuted,
          ),
        ),
      ],
    );
  }
}