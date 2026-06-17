import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:boxicons/boxicons.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// APP FOOTER — Bottom Navigation Bar
// ═══════════════════════════════════════════════════════════
class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(ikon: FeatherIcons.home, ikonAktif: Boxicons.bxs_home, label: 'Home'),
      _NavItem(ikon: MdiIcons.gmail, ikonAktif: MdiIcons.gmail, label: 'Mail'),
      _NavItem(ikon: Boxicons.bx_camera, ikonAktif: Boxicons.bxs_camera, label: 'Absensi', isAbsensi: true),
      _NavItem(ikon: FeatherIcons.fileText, ikonAktif: Boxicons.bxs_file, label: 'Izin'),
      _NavItem(ikon: FeatherIcons.user, ikonAktif: Boxicons.bxs_user, label: 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;

              if (item.isAbsensi) {
                return _AbsensiButton(
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onTap(i);
                  },
                );
              }

              return _NavButton(
                item: item,
                isActive: isActive,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(i);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Nav Item Model
// ─────────────────────────────────────────────────────────
class _NavItem {
  final IconData ikon;
  final IconData ikonAktif;
  final String label;
  final bool isAbsensi;

  const _NavItem({
    required this.ikon,
    required this.ikonAktif,
    required this.label,
    this.isAbsensi = false,
  });
}

// ─────────────────────────────────────────────────────────
// Nav Button Normal
// ─────────────────────────────────────────────────────────
class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _labelAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _labelAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon dengan animasi scale + background pill
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? AppColors.accent.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      widget.isActive
                          ? widget.item.ikonAktif
                          : widget.item.ikon,
                      size: 20,
                      color: widget.isActive
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Label dengan fade in
                Opacity(
                  opacity: widget.isActive ? 1.0 : 0.5,
                  child: Text(
                    widget.item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Absensi Button — Spesial (tengah, menonjol ke atas)
// ─────────────────────────────────────────────────────────
class _AbsensiButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AbsensiButton({required this.isActive, required this.onTap});

  @override
  State<_AbsensiButton> createState() => _AbsensiButtonState();
}

class _AbsensiButtonState extends State<_AbsensiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: OverflowBox(
          maxHeight: 120,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Transform translate untuk mengangkat button ke atas
              Transform.translate(
                offset: const Offset(0, -16),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: widget.isActive ? _pulseAnim.value : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1D4ED8),
                          const Color(0xFF1E40AF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Boxicons.bx_camera,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Label dengan Transform.translate untuk naik ke atas (lebih dekat ke button)
              Transform.translate(
                offset: const Offset(0, -4), // Naik 4 pixel ke atas
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  decoration: BoxDecoration(
                    color: widget.isActive 
                        ? AppColors.accent.withOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Absensi',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.isActive
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}