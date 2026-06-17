import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'izin/izin_models.dart';
import 'izin/izin_header.dart';
import 'izin/izin_form_card.dart';
import 'izin/izin_history_tile.dart';
import '../../services/izin_realtime_service.dart';

// ═══════════════════════════════════════════════════════════
// IZIN SCREEN — Root / Wadah Utama
// Header + Form Kirim Izin + Riwayat Izin
// Background: Network Mesh Abstrak (sama dengan home & absensi)
// ═══════════════════════════════════════════════════════════

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late StreamSubscription _izinSub;

  List<RiwayatIzin> _riwayat = [];
  bool _isLoading = true;

  @override
void initState() {
  super.initState();

  _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
  );

  // 🔥 START REALTIME IZIN
 Future.microtask(() async {
  await IzinRealtimeService.start();
});

  // 🔥 LISTEN DATA
_izinSub = IzinRealtimeService.stream.listen((state) {
  final list = state.izins;

  setState(() {
    _isLoading = false; // 🔥 STOP loading
    _riwayat = list
        .map((e) => RiwayatIzin.fromJson(e))
        .toList();
  });
});
}

  @override
    void dispose() {
      _izinSub.cancel(); // 🔥 WAJIB
      _slideController.dispose();
      super.dispose();
  }

  void _onIzinTerkirim() {
    // Refresh riwayat setelah izin berhasil dikirim
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: Stack(
        children: [
          // ── Background Network Mesh ────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _IzinNetworkGridPainter()),
          ),

          // ── Content ───────────────────────────────────
          SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ───────────────────────────
                  SliverToBoxAdapter(
                    child: IzinHeader(
                      onBuatIzin: () {
                        showIzinFormModal(context, onSuccess: _onIzinTerkirim);
                      },
                    ),
                  ),

                    // ── Riwayat Section ──────────────────
                    SliverToBoxAdapter(
                      child: IzinHistorySection(
  riwayat: _riwayat,
  isLoading: _isLoading, // 🔥 INI YANG KURANG
),
                    ),

                    // ── Bottom Padding ───────────────────
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
// PAINTER: Network Mesh Abstrak (sama persis home & absensi)
// ═══════════════════════════════════════════════════════════

class _IzinNetworkGridPainter extends CustomPainter {
  static final _rng = math.Random(13);
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
  bool shouldRepaint(_IzinNetworkGridPainter old) => false;
}