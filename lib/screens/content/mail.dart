import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mail/mail_models.dart';
import 'mail/mail_helpers.dart';
import 'mail/mail_list_view.dart';
import 'mail/mail_detail_view.dart';
import 'mail/mail_delete_dialog.dart';

// ═══════════════════════════════════════════════════════════
// MAIL SCREEN — Root / wadah utama
// Semua logika state management terpusat di sini.
// UI dibagi ke: mail_list_view, mail_detail_view, mail_delete_dialog
// ═══════════════════════════════════════════════════════════

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  // ── State ────────────────────────────────────────────────
  int _tabIndex = 0;
  MailMessage? _selectedMail;
  final TextEditingController _searchCtrl = TextEditingController();
  String _queryPencarian = '';
  late List<MailMessage> _semuaPesan;

  @override
  void initState() {
    super.initState();
    _semuaPesan = buatDataDummyMail();
    _searchCtrl.addListener(() {
      setState(() => _queryPencarian = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter ───────────────────────────────────────────────
  List<MailMessage> get _pesanTersaring {
    List<MailMessage> hasil = _semuaPesan;
    if (_tabIndex == 1) hasil = hasil.where((m) => !m.dibaca).toList();
    if (_queryPencarian.isNotEmpty) {
      hasil = hasil
          .where((m) =>
              m.senderName.toLowerCase().contains(_queryPencarian) ||
              m.subject.toLowerCase().contains(_queryPencarian) ||
              m.preview.toLowerCase().contains(_queryPencarian))
          .toList();
    }
    return hasil;
  }

  int get _jumlahBelumDibaca => _semuaPesan.where((m) => !m.dibaca).length;

  // ── Actions ──────────────────────────────────────────────
  void _bukaPesan(MailMessage mail) {
    HapticFeedback.lightImpact();
    setState(() {
      mail.dibaca = true;
      _selectedMail = mail;
    });
  }

  void _kembaliKeList() {
    setState(() => _selectedMail = null);
  }

  void _hapusPesan(MailMessage mail) {
    HapticFeedback.mediumImpact();
    tampilkanDialogHapus(
      context: context,
      mail: mail,
      onKonfirmasi: () {
        setState(() {
          _semuaPesan.removeWhere((m) => m.id == mail.id);
          if (_selectedMail?.id == mail.id) _selectedMail = null;
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF), // UPDATE: sama seperti home.dart
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════════
          // BACKGROUND NETWORK MESH ABSTRAK (UPDATE BARU)
          // Sama persis dengan header.dart / home.dart
          // ═══════════════════════════════════════════════════
          Positioned.fill(
            child: CustomPaint(painter: MailNetworkGridPainter()),
          ),

          // Konten — navigasi antar view dengan AnimatedSwitcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final isDetail = child.key == const ValueKey('detail');
              final offset = isDetail
                  ? const Offset(1.0, 0.0)
                  : const Offset(-1.0, 0.0);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _selectedMail == null
                ? MailListView(
                    key: const ValueKey('list'),
                    pesanTersaring: _pesanTersaring,
                    jumlahBelumDibaca: _jumlahBelumDibaca,
                    tabIndex: _tabIndex,
                    searchCtrl: _searchCtrl,
                    onTabChanged: (i) => setState(() => _tabIndex = i),
                    onBukaPesan: _bukaPesan,
                    onHapusPesan: _hapusPesan,
                  )
                : MailDetailView(
                    key: const ValueKey('detail'),
                    mail: _selectedMail!,
                    onKembali: _kembaliKeList,
                    onHapusPesan: _hapusPesan,
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Network Mesh Abstrak (SAMA PERSIS HEADER.DART)
// ═══════════════════════════════════════════════════════════

class MailNetworkGridPainter extends CustomPainter {
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
  bool shouldRepaint(MailNetworkGridPainter old) => false;
}