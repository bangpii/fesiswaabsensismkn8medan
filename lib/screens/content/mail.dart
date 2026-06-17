import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/izin_realtime_service.dart';
import '../../../services/izin_pesan_realtime_service.dart';
import 'mail/mail_models.dart';
import 'mail/mail_helpers.dart';
import 'mail/mail_list_view.dart';
import 'mail/mail_detail_view.dart';
import 'mail/mail_delete_dialog.dart';

// ═══════════════════════════════════════════════════════════
// MAIL SCREEN — Root screen, state management terpusat
// Data dari IzinRealtimeService + IzinPesanRealtimeService
// ═══════════════════════════════════════════════════════════

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  IzinModel? _selectedIzin;
  List<IzinModel> _izins = [];
  bool _isLoading = true;

  StreamSubscription? _izinSub;
  StreamSubscription? _pesanSub;

  @override
  void initState() {
    super.initState();
    _startServices();
  }

Future<void> _startServices() async {
  setState(() => _isLoading = true);

  // 🔥 LISTEN DULU (INI KUNCI)
  _izinSub = IzinRealtimeService.stream.listen((state) {
    if (!mounted) return;

    final izinList = state.izins
        .map((e) => IzinModel.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _izins = izinList;
      _isLoading = false;

      // Sync pesan jika sedang buka detail
      if (_selectedIzin != null) {
        final updated = izinList.firstWhere(
          (z) => z.id == _selectedIzin!.id,
          orElse: () => _selectedIzin!,
        );
        _selectedIzin = updated;
      }
    });
  });

  // 🔥 BARU START SERVICE
  await IzinRealtimeService.start();

  // 🔥 START PESAN
  IzinPesanRealtimeService.start();

  // 🔥 LISTEN PESAN
  _pesanSub = IzinPesanRealtimeService.stream.listen((state) {
    if (!mounted) return;

    // refresh unread badge
    IzinRealtimeService.load();
  });
}

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await IzinRealtimeService.load();
  }

  void _bukaPesan(IzinModel izin) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIzin = izin);
  }

  void _kembaliKeList() {
    HapticFeedback.lightImpact();
    setState(() => _selectedIzin = null);
    // Refresh list untuk update unread badge
    IzinRealtimeService.load();
  }

  void _hapusPesan(IzinModel izin) {
    HapticFeedback.mediumImpact();
    tampilkanDialogHapus(
      context: context,
      izin: izin,
      onKonfirmasi: () {
        setState(() {
          _izins.removeWhere((z) => z.id == izin.id);
          if (_selectedIzin?.id == izin.id) _selectedIzin = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _izinSub?.cancel();
    _pesanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMailBg,
      body: Stack(
        children: [
          // Background network mesh (SAMA PERSIS dengan header.dart)
          Positioned.fill(
            child: CustomPaint(painter: _MailNetworkGridPainter()),
          ),

          // Konten utama dengan animasi slide
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isDetail = child.key == const ValueKey('detail');
              final offset = isDetail
                  ? const Offset(1.0, 0.0)
                  : const Offset(-0.3, 0.0);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _selectedIzin == null
                ? MailListView(
                    key: const ValueKey('list'),
                    izins: _izins,
                    isLoading: _isLoading,
                    onRefresh: _refresh,
                    onBukaPesan: _bukaPesan,
                    onHapusPesan: _hapusPesan,
                  )
                : MailDetailView(
                    key: ValueKey('detail_${_selectedIzin!.id}'),
                    izin: _selectedIzin!,
                    onKembali: _kembaliKeList,
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Network Mesh Abstrak (IDENTIK dengan header.dart)
// ═══════════════════════════════════════════════════════════

class _MailNetworkGridPainter extends CustomPainter {
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
          x.clamp(0, size.width),
          y.clamp(0, size.height),
        ));
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
  bool shouldRepaint(_MailNetworkGridPainter old) => false;
}