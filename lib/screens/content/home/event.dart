// lib/screens/content/home/event.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import '../../../services/cms_service.dart';

// ═══════════════════════════════════════════════════════════
// HELPER — parse Color dari hex string
// ═══════════════════════════════════════════════════════════
Color _parseColor(dynamic value, {Color fallback = const Color(0xFF2563EB)}) {
  if (value == null) return fallback;
  try {
    final hex = value.toString().replaceAll('#', '');
    if (hex.length == 6) return Color(int.parse('0xFF$hex'));
    if (hex.length == 8) return Color(int.parse('0x$hex'));
  } catch (_) {}
  return fallback;
}

// ═══════════════════════════════════════════════════════════
// HELPER — format tanggal dari ISO string
// ═══════════════════════════════════════════════════════════
String _formatTanggal(dynamic mulai, dynamic selesai) {
  if (mulai == null) return '';
  try {
    final dtMulai   = DateTime.parse(mulai.toString()).toLocal();
    final bulanMap  = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    String fmt(DateTime d) =>
        '${d.day} ${bulanMap[d.month]} ${d.year}';

    if (selesai == null) return fmt(dtMulai);

    final dtSelesai = DateTime.parse(selesai.toString()).toLocal();

    if (dtMulai.year  == dtSelesai.year  &&
        dtMulai.month == dtSelesai.month &&
        dtMulai.day   == dtSelesai.day) {
      return fmt(dtMulai);
    }

    return '${fmt(dtMulai)} – ${fmt(dtSelesai)}';
  } catch (_) {
    return mulai.toString();
  }
}

// ═══════════════════════════════════════════════════════════
// KAROUSEL EVENT — stateful, subscribe ke CmsService.stream
// ═══════════════════════════════════════════════════════════
class KarouselEvent extends StatefulWidget {
  /// Opsional: controller & state dari parent (home.dart).
  /// Kalau null, widget ini kelola sendiri.
  final PageController?      controller;
  final int?                 currentIndex;
  final ValueChanged<int>?   onPageChanged;

  const KarouselEvent({
    super.key,
    this.controller,
    this.currentIndex,
    this.onPageChanged,
  });

  @override
  State<KarouselEvent> createState() => _KarouselEventState();
}

class _KarouselEventState extends State<KarouselEvent> {
  late PageController _pageCtrl;
  bool _ownController = false;

  List<Map<String, dynamic>> _events = [];
  int    _currentIndex     = 0;
  bool   _isLoading        = true;
  bool   _isUserInteracting = false;

  Timer?           _autoTimer;
  StreamSubscription<List<dynamic>>? _sub;

  // ── lifecycle ────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _pageCtrl = widget.controller!;
    } else {
      _pageCtrl      = PageController();
      _ownController = true;
    }

    if (widget.currentIndex != null) {
      _currentIndex = widget.currentIndex!;
    }

    // Ambil cache dulu supaya tidak blank
    _applyData(CmsService.cache);

    // Subscribe stream realtime
    _sub = CmsService.stream.listen((raw) {
      if (mounted) _applyData(raw);
    });

    // Load (juga trigger stream)
    CmsService.load();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _sub?.cancel();
    if (_ownController) _pageCtrl.dispose();
    super.dispose();
  }

  // ── parse data ───────────────────────────────────────────

  void _applyData(List<dynamic> raw) {
    final events = raw
        .where((s) => s['type'] == 'event')
        .map((s) {
          final d = s['data'] as Map<String, dynamic>? ?? {};
          return <String, dynamic>{
            'judul'    : d['judul']          ?? '',
            'kategori' : d['kategori']        ?? '',
            'warna'    : _parseColor(d['warna']),
            'gambar'   : d['gambar_url']      ?? '',
            'tanggal'  : _formatTanggal(
                           d['tanggal_mulai'],
                           d['tanggal_selesai'],
                         ),
          };
        })
        .toList();

    if (!mounted) return;
    setState(() {
      _events   = events;
      _isLoading = false;
    });

    _restartAutoScroll();
  }

  // ── auto scroll ──────────────────────────────────────────

  void _restartAutoScroll() {
    _autoTimer?.cancel();
    if (_events.isEmpty) return;

    _autoTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted || _isUserInteracting || !_pageCtrl.hasClients) return;
      final total = _loopEvents.length;
      final next  = _currentIndex + 1;

      if (next >= total) {
        _pageCtrl.jumpToPage(0);
        _setIndex(0);
      } else {
        _pageCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _setIndex(int i) {
    setState(() => _currentIndex = i);
    widget.onPageChanged?.call(i);
  }

  List<Map<String, dynamic>> get _loopEvents =>
      _events.isEmpty ? [] : [..._events, _events.first];

  // ── build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_events.isEmpty) return _buildEmpty();

    final displayIndex = _currentIndex % _events.length;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) {
                setState(() => _isUserInteracting = true);
              } else if (n is ScrollEndNotification) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _isUserInteracting = false);
                });
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) {
                if (i >= _events.length) {
                  _pageCtrl.jumpToPage(0);
                  _setIndex(0);
                } else {
                  _setIndex(i);
                }
              },
              itemCount: _loopEvents.length,
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              clipBehavior: Clip.none,
              itemBuilder: (_, i) {
                final screenWidth = MediaQuery.of(context).size.width;
                return Padding(
                  padding: EdgeInsets.only(
                    left : i == 0                      ? 20 : 8,
                    right: i == _loopEvents.length - 1 ? 20 : 8,
                  ),
                  child: KartuEvent(
                    event: _loopEvents[i],
                    width: screenWidth - 40,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _events.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width : i == displayIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == displayIndex
                    ? AppColors.accent
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── skeleton ─────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 2,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ShimmerBox(
                width : MediaQuery.of(context).size.width - 40,
                height: 200,
                radius: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => _ShimmerBox(
              width : i == 0 ? 20 : 6,
              height: 6,
              radius: 100,
              margin: const EdgeInsets.symmetric(horizontal: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FeatherIcons.calendar,
                size: 28, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(
              'Belum ada event',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KARTU EVENT — tidak berubah dari versi sebelumnya
// ═══════════════════════════════════════════════════════════
class KartuEvent extends StatelessWidget {
  final Map<String, dynamic> event;
  final double width;
  const KartuEvent({super.key, required this.event, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar
            (event['gambar'] as String).isNotEmpty
                ? Image.network(
                    event['gambar'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ColorPlaceholder(
                      color: event['warna'] as Color,
                    ),
                  )
                : _ColorPlaceholder(color: event['warna'] as Color),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),

            // Teks
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge kategori
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: event['warna'] as Color,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      event['kategori'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Judul
                  Text(
                    event['judul'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tanggal
                  Row(
                    children: [
                      const Icon(FeatherIcons.calendar,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        event['tanggal'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════

class _ColorPlaceholder extends StatelessWidget {
  final Color color;
  const _ColorPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        color: color.withOpacity(0.2),
        child: Center(
          child: Icon(FeatherIcons.image,
              size: 32, color: color.withOpacity(0.5)),
        ),
      );
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final EdgeInsets? margin;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    this.margin,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width : widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}