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
  // Controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _ringController;
  late AnimationController _exitController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _progressValue;
  late Animation<double> _ringRotation;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Status bar transparan
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // 1. Logo controller (0–900ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 2. Text controller (title + subtitle)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Progress bar (5 detik penuh)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // 4. Ring spinner (terus berputar)
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ringRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // 5. Exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  void _startSequence() async {
    // Logo muncul
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Text muncul setelah logo
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();

    // Progress + ring mulai
    await Future.delayed(const Duration(milliseconds: 400));
    _progressController.forward();
    _ringController.repeat();

    // Tunggu 5 detik loading selesai
    await Future.delayed(const Duration(milliseconds: 5200));
    _ringController.stop();

    // Exit animation
    await _exitController.forward();

    // Navigate ke HelloPage
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScaffold(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _ringController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
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
          children: [
            // — Background dekorasi: lingkaran blur slate di sudut —
            Positioned(
              top: -80,
              right: -80,
              child: _DecorCircle(
                size: 280,
                color: AppColors.accent.withOpacity(0.06),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: _DecorCircle(
                size: 220,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
            Positioned(
              top: size.height * 0.35,
              left: -40,
              child: _DecorCircle(
                size: 120,
                color: AppColors.accent.withOpacity(0.04),
              ),
            ),

            // — Konten Utama —
            SafeArea(
              child: Column(
                children: [
                  // Top spacer + label instansi
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _textController,
                        builder: (context, _) {
                          return FadeTransition(
                            opacity: _subtitleOpacity,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: Text(
                                'SMKN 8 MEDAN',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4.0,
                                  color: AppColors.accent.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Logo area
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo dengan ring spinner
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_logoController, _ringController]),
                            builder: (context, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ring spinner (muncul setelah logo)
                                  if (_logoController.isCompleted)
                                    Transform.rotate(
                                      angle:
                                          _ringRotation.value * 2 * math.pi,
                                      child: SizedBox(
                                        width: 148,
                                        height: 148,
                                        child: CustomPaint(
                                          painter: _ArcSpinnerPainter(
                                            color: AppColors.accent,
                                            progress:
                                                _progressValue.value,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Logo container
                                  ScaleTransition(
                                    scale: _logoScale,
                                    child: FadeTransition(
                                      opacity: _logoOpacity,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withOpacity(0.15),
                                              blurRadius: 32,
                                              offset: const Offset(0, 12),
                                              spreadRadius: 0,
                                            ),
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: AppColors.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(31),
                                          child: Image.asset(
                                            AppLogo.appLogo,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                // Fallback jika asset belum ada
                                                Center(
                                              child: Text(
                                                'A',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // App name
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, _) {
                              return FadeTransition(
                                opacity: _textOpacity,
                                child: SlideTransition(
                                  position: _textSlide,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Absensi SMKN 8 Medan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.5,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Sistem Absensi Digital',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress bar area
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    height: 3,
                                    width: double.infinity,
                                    color: AppColors.border,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressValue.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.accent,
                                              AppColors.accent
                                                  .withOpacity(0.6),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Persentase
                                Text(
                                  '${(_progressValue.value * 100).toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (context, _) {
                        return FadeTransition(
                          opacity: _subtitleOpacity,
                          child: Text(
                            '© 2026 SMKN 8 Medan',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      },
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
}

// ─── Helper Widgets ───────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _ArcSpinnerPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ArcSpinnerPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.25 + (progress * 0.35))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Arc utama yang berputar
    canvas.drawArc(rect, 0, math.pi * 1.4, false, paint);

    // Arc kecil refleksi
    final paint2 = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 1.5, math.pi * 0.4, false, paint2);
  }

  @override
  bool shouldRepaint(_ArcSpinnerPainter old) =>
      old.progress != progress || old.color != color;
}