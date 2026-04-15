import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'absensi/absensi_models.dart';
import 'absensi/absensi_header.dart';
import 'absensi/absensi_map_card.dart';
import 'absensi/absensi_action_button.dart';
import 'absensi/absensi_status_card.dart';
import 'absensi/absensi_history_tile.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI SCREEN — Root / Wadah Utama
// Header modern + Map Card + Action Button + Status + History
// Background: Network Mesh Abstrak (sama dengan home.dart)
// ═══════════════════════════════════════════════════════════

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────
  StatusAbsensi _statusHariIni = StatusAbsensi.belumAbsen;
  bool _sedangMemproses = false;
  List<RiwayatAbsensi> _riwayat = [];

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _riwayat = buatDummyRiwayat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> _lakukanAbsensi() async {
    HapticFeedback.mediumImpact();
    setState(() => _sedangMemproses = true);
    await Future.delayed(const Duration(seconds: 2));
    HapticFeedback.heavyImpact();
    setState(() {
      _sedangMemproses = false;
      if (_statusHariIni == StatusAbsensi.belumAbsen) {
        _statusHariIni = StatusAbsensi.sudahMasuk;
      } else if (_statusHariIni == StatusAbsensi.sudahMasuk) {
        _statusHariIni = StatusAbsensi.sudahPulang;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF), // UPDATE: sama dengan home.dart
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════════
          // BACKGROUND NETWORK MESH ABSTRAK (BARU)
          // ═══════════════════════════════════════════════════
          Positioned.fill(
            child: CustomPaint(painter: AbsensiNetworkGridPainter()),
          ),

          // ── Content ──────────────────────────────────────
          SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ───────────────────────────────
                    SliverToBoxAdapter(
                      child: AbsensiHeader(statusHariIni: _statusHariIni),
                    ),

                    // ── Status Card ──────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: AbsensiStatusCard(status: _statusHariIni),
                      ),
                    ),

                    // ── Map Card ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: AbsensiMapCard(statusHariIni: _statusHariIni),
                      ),
                    ),

                    // ── Action Button ────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: AbsensiActionButton(
                          status: _statusHariIni,
                          sedangMemproses: _sedangMemproses,
                          pulseAnim: _pulseAnim,
                          onPressed: _statusHariIni != StatusAbsensi.sudahPulang
                              ? _lakukanAbsensi
                              : null,
                        ),
                      ),
                    ),

                    // ── History Section ──────────────────────
                    SliverToBoxAdapter(
                      child: AbsensiHistorySection(riwayat: _riwayat),
                    ),

                    // ── Bottom Padding ───────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
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
// PAINTER: Network Mesh Abstrak (SAMA PERSIS HOME.DART)
// ═══════════════════════════════════════════════════════════

class AbsensiNetworkGridPainter extends CustomPainter {
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

    // Gambar garis antar node yang dekat (mesh network)
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

    // Gambar node/dot
    for (int i = 0; i < nodes.length; i++) {
      final isBig = i % 9 == 0;
      final isAccent = i % 19 == 0;
      
      // Glow effect untuk node tertentu
      if (isAccent) {
        canvas.drawCircle(
          nodes[i],
          8,
          Paint()
            ..color = const Color(0xFF3B82F6).withOpacity(0.07)
            ..style = PaintingStyle.fill,
        );
      }
      
      // Node utama
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
  bool shouldRepaint(AbsensiNetworkGridPainter old) => false;
}