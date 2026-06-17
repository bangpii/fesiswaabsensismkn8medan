import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boxicons/boxicons.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import '../../../services/notification_service.dart';

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
  final String? photoUrl;
  final UserRole role;
  final int jumlahNotifikasi;
  final VoidCallback onNotifikasiTap;
  final VoidCallback onProfilTap;

  SliverHeaderDelegate({
    required this.headerHeight,
    required this.namaLengkap,
    this.photoUrl,
    required this.role,
    required this.jumlahNotifikasi,
    required this.onNotifikasiTap,
    required this.onProfilTap,
  });

  String _getInisial(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
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
    final double shrinkPercent =
        (shrinkOffset / headerHeight).clamp(0.0, 1.0);
    final double opacity = 1.0 - shrinkPercent;

    final inisial = _getInisial(namaLengkap);
    final roleLabel = _getRoleLabel(role);
    final roleColor = _getRoleColor(role);
    final bool namaPanjang = namaLengkap.length > 18;

    if (shrinkPercent >= 1.0) return const SizedBox.shrink();

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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ────────────────────────────────
                GestureDetector(
                  onTap: onProfilTap,
                  child: AnimatedAvatar(
                    inisial: inisial,
                    photoUrl: photoUrl,
                    roleColor: roleColor,
                    size: 48,
                    padding: 2.5,
                    shrinkPercent: shrinkPercent,
                  ),
                ),

                const SizedBox(width: 12),

                // ── Nama + Role ───────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: onProfilTap,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            math.max(0, currentHeight - 20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                            if (shrinkPercent < 0.3)
                              const SizedBox(height: 2),
                            Text(
                              namaLengkap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: namaPanjang
                                    ? 12.5
                                    : 14.5,
                                fontWeight: FontWeight.w800,
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

                // ── Notifikasi ────────────────────────────
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
        oldDelegate.photoUrl != photoUrl ||
        oldDelegate.role != role ||
        oldDelegate.jumlahNotifikasi != jumlahNotifikasi;
  }
}

// ═══════════════════════════════════════════════════════════
// FUNGSI SHOW NOTIFIKASI MODAL
// ═══════════════════════════════════════════════════════════

void showNotifikasiModal(BuildContext context) {
  HapticFeedback.lightImpact();

  // Cari posisi tombol notifikasi
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup notifikasi',
    barrierColor: Colors.black.withOpacity(0.25),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      );
      return Align(
        alignment: Alignment.topRight,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: const _NotifikasiPanel(),
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════
// PANEL NOTIFIKASI
// ═══════════════════════════════════════════════════════════

class _NotifikasiPanel extends StatefulWidget {
  const _NotifikasiPanel();

  @override
  State<_NotifikasiPanel> createState() => _NotifikasiPanelState();
}

class _NotifikasiPanelState extends State<_NotifikasiPanel> {
  final _service = NotificationService.instance;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const headerHeight = 140.0;
    final panelTop = topPadding + headerHeight - 8;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          top: panelTop,
          right: 16,
          left: 16,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Flexible(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Boxicons.bx_bell,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          StreamBuilder<List<AppNotification>>(
            stream: _service.stream,
            initialData: _service.notifications,
            builder: (_, snap) {
              final unread =
                  snap.data?.where((n) => !n.isRead).length ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _service.markAllAsRead();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Tandai semua',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<AppNotification>>(
      stream: _service.stream,
      initialData: _service.notifications,
      builder: (context, snap) {
        final list = snap.data ?? [];

        if (list.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _NotifTile(
            notif: list[i],
            onTap: () {
              _service.markAsRead(list[i].id);
              HapticFeedback.selectionClick();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FeatherIcons.bell,
            size: 36,
            color: AppColors.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          Text(
            'Tidak ada notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TILE NOTIFIKASI
// ═══════════════════════════════════════════════════════════

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = _notifConfig(notif.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surface
              : config.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : config.color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                config.icon,
                size: 17,
                color: config.color,
              ),
            ),
            const SizedBox(width: 10),

            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.judul,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(
                              left: 6, top: 3),
                          decoration: BoxDecoration(
                            color: config.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.isi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Badge tipe
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      config.label,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: config.color,
                        letterSpacing: 0.2,
                      ),
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

  _NotifConfig _notifConfig(NotifType type) {
    switch (type) {
      case NotifType.absensi:
        return _NotifConfig(
          icon: Boxicons.bx_fingerprint,
          color: const Color(0xFFDC2626),
          label: 'Absensi',
        );
      case NotifType.jadwal:
        return _NotifConfig(
          icon: FeatherIcons.clock,
          color: const Color(0xFF7C3AED),
          label: 'Jadwal',
        );
      case NotifType.event:
        return _NotifConfig(
          icon: FeatherIcons.calendar,
          color: AppColors.accent,
          label: 'Event',
        );
      case NotifType.pengumuman:
        return _NotifConfig(
          icon: Boxicons.bx_phone,
          color: const Color(0xFFF59E0B),
          label: 'Pengumuman',
        );
    }
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifConfig(
      {required this.icon, required this.color, required this.label});
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Animated Avatar (tidak berubah)
// ═══════════════════════════════════════════════════════════

class AnimatedAvatar extends StatelessWidget {
  final String inisial;
  final String? photoUrl;
  final Color roleColor;
  final double size;
  final double padding;
  final double shrinkPercent;

  const AnimatedAvatar({
    super.key,
    required this.inisial,
    this.photoUrl,
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
                border:
                    Border.all(color: AppColors.border, width: 1),
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildInisial(roleColor, size),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _buildInisial(roleColor, size);
                        },
                      )
                    : _buildInisial(roleColor, size),
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

  Widget _buildInisial(Color roleColor, double size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor.withOpacity(0.15),
            roleColor.withOpacity(0.08),
          ],
        ),
      ),
      child: Center(
        child: Text(
          inisial,
          style: GoogleFonts.poppins(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w700,
            color: roleColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Animated Role Badge (tidak berubah)
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
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
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
// WIDGET: Notifikasi Button — reactive ke NotificationService
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
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService.instance.stream,
      initialData: NotificationService.instance.notifications,
      builder: (context, snap) {
        final count =
            snap.data?.where((n) => !n.isRead).length ?? jumlah;

        return GestureDetector(
          onTap: () {
            onTap();
            showNotifikasiModal(context);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withOpacity(0.04),
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
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius:
                          BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFF0F6FF),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
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
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Light Network Grid Background (tidak berubah)
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
          linePaint.color =
              const Color(0xFF2563EB).withOpacity(opacity);
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
            ..color =
                const Color(0xFF3B82F6).withOpacity(0.07)
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