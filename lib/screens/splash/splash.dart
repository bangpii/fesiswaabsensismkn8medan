import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../config/app_logo.dart';
import '../../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────
  late AnimationController _meshController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _progressController;
  late AnimationController _exitController;

  // ── Animations ──────────────────────────────────────────
  late Animation<double> _meshOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _progressValue;
  late Animation<double> _progressOpacity;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Mesh background fade in
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _meshOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _meshController, curve: Curves.easeOut),
    );

    // Logo animation (elastic + glow)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Title animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Tagline / instansi
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    // Elegant progress indicator (3.5 detik)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
  }

  void _startSequence() async {
    // Phase 1: Mesh background muncul
    await Future.delayed(const Duration(milliseconds: 100));
    _meshController.forward();

    // Phase 2: Logo muncul dengan elastic
    await Future.delayed(const Duration(milliseconds: 400));
    _logoController.forward();

    // Phase 3: Title muncul
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();

    // Phase 4: Tagline instansi
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    // Phase 5: Progress mulai
    await Future.delayed(const Duration(milliseconds: 300));
    _progressController.forward();

    // Phase 6: Tunggu progress selesai
    await Future.delayed(const Duration(milliseconds: 3800));

    // Phase 7: Exit animation
    await _exitController.forward();

    // Navigate
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScaffold(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _meshController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Network Mesh Biru ──────────────
            AnimatedBuilder(
              animation: _meshController,
              builder: (context, child) {
                return Opacity(
                  opacity: _meshOpacity.value,
                  child: CustomPaint(
                    painter: _SplashNetworkMeshPainter(),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // ── Konten Utama (Tengah) ─────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Logo Besar di Tengah ───────────
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(
                                              0.12 * _logoGlow.value),
                                          blurRadius: 60,
                                          spreadRadius: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Secondary ring
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.accent.withOpacity(
                                            0.08 * _logoGlow.value),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Logo container
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        AppLogo.appLogo,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            'A',
                                            style: GoogleFonts.poppins(
                                              fontSize: 56,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // ── Judul Utama (Tengah) ───────────
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, _) {
                          return FadeTransition(
                            opacity: _titleOpacity,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Column(
                                children: [
                                  Text(
                                    'SMKN 8 MEDAN',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sistem Absensi Digital',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.accent,
                                      letterSpacing: 2.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // ── Elegant Loading Indicator ──────
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return FadeTransition(
                            opacity: _progressOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Elegant dot indicator
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildDot(0),
                                    const SizedBox(width: 8),
                                    _buildDot(1),
                                    const SizedBox(width: 8),
                                    _buildDot(2),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Subtle progress line
                                Container(
                                  width: 120,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.border.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressValue.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accent,
                                            AppColors.accent.withOpacity(0.4),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer (Bawah) ────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: AnimatedBuilder(
                animation: _taglineController,
                builder: (context, _) {
                return FadeTransition(
  opacity: _taglineOpacity,
  child: SlideTransition(
    position: _taglineSlide,
    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chip instansi
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'SMKN 8 MEDAN',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.0,
                              color: AppColors.accent.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Copyright
                        Text(
                          '© 2026 SMKN 8 Medan',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted.withOpacity(0.5),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Animated dot untuk loading indicator
  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = _progressValue.value;
        final dotProgress = ((progress * 3) - index).clamp(0.0, 1.0);
        final isActive = dotProgress > 0;

        return Container(
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.accent.withOpacity(0.6 + (dotProgress * 0.4))
                : AppColors.border.withOpacity(0.5),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Network Mesh Biru (sama konsep dengan Profile)
// ═══════════════════════════════════════════════════════════

class _SplashNetworkMeshPainter extends CustomPainter {
  static final _rng = math.Random(42);
  static List<Offset>? _nodes;

  static List<Offset> _buildNodes(Size size) {
    if (_nodes != null) return _nodes!;
    final list = <Offset>[];
    const cols = 7;
    const rows = 14;
    final dx = size.width / (cols - 1);
    final dy = size.height / (rows - 1);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * dx + (_rng.nextDouble() - 0.5) * dx * 0.6;
        final y = r * dy + (_rng.nextDouble() - 0.5) * dy * 0.6;
        list.add(
          Offset(
            x.clamp(0, size.width),
            y.clamp(0, size.height),
          ),
        );
      }
    }
    _nodes = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _buildNodes(size);

    // Gambar garis-garis jaringan
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 120) {
          final opacity = (1 - dist / 120) * 0.14;
          linePaint.color = const Color(0xFF2563EB).withOpacity(opacity);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Gambar node/dot
    for (int i = 0; i < nodes.length; i++) {
      final isBig = i % 8 == 0;
      final isAccent = i % 17 == 0;

      // Glow untuk node accent
      if (isAccent) {
        canvas.drawCircle(
          nodes[i],
          7,
          Paint()
            ..color = const Color(0xFF3B82F6).withOpacity(0.06)
            ..style = PaintingStyle.fill,
        );
      }

      // Node utama
      canvas.drawCircle(
        nodes[i],
        isBig ? 3.2 : 1.6,
        Paint()
          ..color = isBig
              ? const Color(0xFF2563EB).withOpacity(0.20)
              : const Color(0xFF93C5FD).withOpacity(0.40)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashNetworkMeshPainter old) => false;
}