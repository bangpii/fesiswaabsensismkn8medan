import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// ENUM: User Role
// ═══════════════════════════════════════════════════════════

enum UserRole { siswa, guru }

// ═══════════════════════════════════════════════════════════
// SLIVER HEADER DELEGATE — SCROLL AWAY VERSION
// ═══════════════════════════════════════════════════════════

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double headerHeight;
  final String namaLengkap;
  final UserRole role;
  final int jumlahNotifikasi;
  final VoidCallback onNotifikasiTap;
  final VoidCallback onProfilTap;

  SliverHeaderDelegate({
    required this.headerHeight,
    required this.namaLengkap,
    required this.role,
    required this.jumlahNotifikasi,
    required this.onNotifikasiTap,
    required this.onProfilTap,
  });

  String _getInisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.siswa:
        return 'Siswa';
      case UserRole.guru:
        return 'Guru';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.siswa:
        return AppColors.accent;
      case UserRole.guru:
        return AppColors.success;
    }
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double shrinkPercent = (shrinkOffset / headerHeight).clamp(0.0, 1.0);
    final double opacity = 1.0 - shrinkPercent;

    final inisial = _getInisial(namaLengkap);
    final roleLabel = _getRoleLabel(role);
    final roleColor = _getRoleColor(role);
    final bool namaPanjang = namaLengkap.length > 18;

    if (shrinkPercent >= 1.0) {
      return const SizedBox.shrink();
    }

    final double currentHeight =
        (headerHeight - shrinkOffset).clamp(0.0, headerHeight);

    return Opacity(
      opacity: opacity,
      child: Container(
        height: currentHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FF),
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withOpacity(opacity),
              width: 1,
            ),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ──────────────────────────────────────
                GestureDetector(
                  onTap: onProfilTap,
                  child: AnimatedAvatar(
                    inisial: inisial,
                    roleColor: roleColor,
                    size: 48,
                    padding: 2.5,
                    shrinkPercent: shrinkPercent,
                  ),
                ),

                const SizedBox(width: 12),

                // ── Nama + Role ─────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: onProfilTap,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0, currentHeight - 20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (shrinkPercent < 0.3)
                              Text(
                                'Selamat Datang',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            if (shrinkPercent < 0.3) const SizedBox(height: 2),

                            Text(
                              namaLengkap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: namaPanjang ? 12.5 : 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),

                            if (shrinkPercent < 0.6) ...[
                              const SizedBox(height: 3),
                              AnimatedRoleBadge(
                                label: roleLabel,
                                color: roleColor,
                                shrinkPercent: shrinkPercent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── Notifikasi ──────────────────────────────────
                NotifButton(
                  jumlah: jumlahNotifikasi,
                  onTap: onNotifikasiTap,
                  shrinkPercent: shrinkPercent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant SliverHeaderDelegate oldDelegate) {
    return oldDelegate.namaLengkap != namaLengkap ||
        oldDelegate.role != role ||
        oldDelegate.jumlahNotifikasi != jumlahNotifikasi;
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Animated Avatar
// ═══════════════════════════════════════════════════════════

class AnimatedAvatar extends StatelessWidget {
  final String inisial;
  final Color roleColor;
  final double size;
  final double padding;
  final double shrinkPercent;

  const AnimatedAvatar({
    super.key,
    required this.inisial,
    required this.roleColor,
    required this.size,
    required this.padding,
    required this.shrinkPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: roleColor.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    roleColor.withOpacity(0.15),
                    roleColor.withOpacity(0.08),
                  ],
                ),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Center(
                child: Text(
                  inisial,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.31,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: size * 0.02,
          bottom: size * 0.02,
          child: Container(
            width: size * 0.21,
            height: size * 0.21,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF0F6FF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Animated Role Badge
// ═══════════════════════════════════════════════════════════

class AnimatedRoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double shrinkPercent;

  const AnimatedRoleBadge({
    super.key,
    required this.label,
    required this.color,
    required this.shrinkPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
          height: 1.0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Notifikasi Button
// ═══════════════════════════════════════════════════════════

class NotifButton extends StatelessWidget {
  final int jumlah;
  final VoidCallback onTap;
  final double shrinkPercent;

  const NotifButton({
    super.key,
    required this.jumlah,
    required this.onTap,
    required this.shrinkPercent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Boxicons.bx_bell,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          if (jumlah > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFFF0F6FF),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    jumlah > 99 ? '99+' : '$jumlah',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Light Network Grid Background
// ═══════════════════════════════════════════════════════════

class LightNetworkGridPainter extends CustomPainter {
  static final _rng = math.Random(7);
  static List<Offset>? _nodes;

  static List<Offset> _buildNodes(Size size) {
    if (_nodes != null) return _nodes!;
    final list = <Offset>[];
    const cols = 8;
    const rows = 18;
    final dx = size.width / (cols - 1);
    final dy = size.height / (rows - 1);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * dx + (_rng.nextDouble() - 0.5) * dx * 0.55;
        final y = r * dy + (_rng.nextDouble() - 0.5) * dy * 0.55;
        list.add(Offset(
            x.clamp(0, size.width), y.clamp(0, size.height)));
      }
    }
    _nodes = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _buildNodes(size);
    final linePaint = Paint()
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 110) {
          final opacity = (1 - dist / 110) * 0.16;
          linePaint.color = const Color(0xFF2563EB).withOpacity(opacity);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    for (int i = 0; i < nodes.length; i++) {
      final isBig = i % 9 == 0;
      final isAccent = i % 19 == 0;
      if (isAccent) {
        canvas.drawCircle(
          nodes[i],
          8,
          Paint()
            ..color = const Color(0xFF3B82F6).withOpacity(0.07)
            ..style = PaintingStyle.fill,
        );
      }
      canvas.drawCircle(
        nodes[i],
        isBig ? 3.5 : 1.8,
        Paint()
          ..color = isBig
              ? const Color(0xFF2563EB).withOpacity(0.22)
              : const Color(0xFF93C5FD).withOpacity(0.45)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(LightNetworkGridPainter old) => false;
}