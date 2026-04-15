import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'mail_models.dart';

// ═══════════════════════════════════════════════════════════
// MAIL HELPERS — Shared utilities & reusable widgets
// ═══════════════════════════════════════════════════════════

const Color kMailBiru = Color(0xFF1D4ED8);
const Color kMailBiruMuda = Color(0xFFEFF6FF);
const Color kMailBiruBorder = Color(0xFFBFDBFE);
const Color kMailTextPrimary = Color(0xFF111827);
const Color kMailTextSecondary = Color(0xFF6B7280);
const Color kMailTextMuted = Color(0xFF9CA3AF);
const Color kMailBorder = Color(0xFFE5E7EB);
const Color kMailBg = Color(0xFFF8FAFF);

// ── Format Waktu ──────────────────────────────────────────
String formatWaktuSingkat(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
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
  return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatWaktuBalas(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String labelRole(SenderRole role) {
  switch (role) {
    case SenderRole.guru:
      return 'Guru';
    case SenderRole.admin:
      return 'Admin';
    case SenderRole.waliKelas:
      return 'Wali Kelas';
  }
}

// ── Shared Widget: Avatar ─────────────────────────────────
class MailAvatar extends StatelessWidget {
  final String inisial;
  final double ukuran;
  final bool kecil;

  const MailAvatar({
    super.key,
    required this.inisial,
    required this.ukuran,
    this.kecil = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: kMailBiru,
        borderRadius: BorderRadius.circular(kecil ? 9 : ukuran * 0.28),
      ),
      child: Center(
        child: Text(
          inisial,
          style: GoogleFonts.poppins(
            fontSize: ukuran * (kecil ? 0.32 : 0.3),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Shared Widget: Role Badge ─────────────────────────────
class MailRoleBadge extends StatelessWidget {
  final String label;

  const MailRoleBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kMailBiruMuda,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: kMailBiru,
        ),
      ),
    );
  }
}

// ── Shared Widget: Icon Button ────────────────────────────
class MailIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bg;
  final Color border;

  const MailIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = kMailTextSecondary,
    this.bg = const Color(0xFFF3F4F6),
    this.border = kMailBorder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Background Grid Painter ───────────────────────────────
class MailGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1D4ED8).withOpacity(0.03)
      ..strokeWidth = 0.5;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final dotPaint = Paint()
      ..color = const Color(0xFF1D4ED8).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(MailGridPainter old) => false;
}