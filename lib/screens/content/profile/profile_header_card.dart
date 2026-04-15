import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'profile_models.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE HEADER CARD
// Avatar klik → full-screen photo viewer dengan blur background
// ═══════════════════════════════════════════════════════════

class ProfileHeaderCard extends StatelessWidget {
  final DataSiswa siswa;

  const ProfileHeaderCard({super.key, required this.siswa});

  void _bukaFotoViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => _FotoViewerOverlay(siswa: siswa),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────
          GestureDetector(
            onTap: () => _bukaFotoViewer(context),
            child: _AvatarWidget(siswa: siswa, size: 78),
          ),

          const SizedBox(width: 18),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa.namaLengkap,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  ikon: FeatherIcons.creditCard,
                  label: 'NISN',
                  nilai: siswa.nisn,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  ikon: siswa.jenisKelamin == JenisKelamin.lakiLaki
                      ? FeatherIcons.user
                      : FeatherIcons.heart,
                  label: 'Kelamin',
                  nilai: siswa.labelKelamin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Widget Avatar
// ─────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final DataSiswa siswa;
  final double size;

  const _AvatarWidget({required this.siswa, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: AppColors.accent.withOpacity(0.1),
              child: Center(
                child: Text(
                  siswa.inisial,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Tap indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              FeatherIcons.maximize2,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info Row item
// ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const _InfoRow({
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(ikon, size: 13, color: AppColors.accent),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '·',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FOTO VIEWER OVERLAY — Fullscreen, blur background, zoomable
// ═══════════════════════════════════════════════════════════

class _FotoViewerOverlay extends StatefulWidget {
  final DataSiswa siswa;
  const _FotoViewerOverlay({required this.siswa});

  @override
  State<_FotoViewerOverlay> createState() => _FotoViewerOverlayState();
}

class _FotoViewerOverlayState extends State<_FotoViewerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _tutup() {
    _ctrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tutup,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Blur Background ────────────────────────
              FadeTransition(
                opacity: _ctrl,
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                ),
              ),

              // ── Foto Besar ─────────────────────────────
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: () {}, // cegah tap di foto menutup
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Foto / inisial circle
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: InteractiveViewer(
                              transformationController: _transformCtrl,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Container(
                                color: const Color(0xFF1D4ED8).withOpacity(0.15),
                                child: Center(
                                  child: Text(
                                    widget.siswa.inisial,
                                    style: GoogleFonts.poppins(
                                      fontSize: 88,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nama
                        Text(
                          widget.siswa.namaLengkap,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.siswa.kelas,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Tombol Close ───────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: GestureDetector(
                  onTap: _tutup,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      FeatherIcons.x,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}