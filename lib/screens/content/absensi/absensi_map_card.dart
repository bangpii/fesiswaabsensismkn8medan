import 'package:flutter/material.dart';
import 'absensi_models.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI MAP CARD — Card peta lokasi dengan radius zone
// Menampilkan Google Map placeholder yang siap diintegrasi
// dengan google_maps_flutter / flutter_map
// ═══════════════════════════════════════════════════════════

class AbsensiMapCard extends StatefulWidget {
  final StatusAbsensi statusHariIni;

  const AbsensiMapCard({super.key, required this.statusHariIni});

  @override
  State<AbsensiMapCard> createState() => _AbsensiMapCardState();
}

class _AbsensiMapCardState extends State<AbsensiMapCard>
    with SingleTickerProviderStateMixin {
  bool _dalamZona = true; // nanti connect ke backend GPS check
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _radarAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _radarCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  // ── Show Fullscreen Map ───────────────────────────────────
  void _showFullscreenMap() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => _FullscreenMapView(
        dalamZona: _dalamZona,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Icon dengan ukuran fixed
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                
                // Teks lokasi dengan Expanded agar tidak overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Absensi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SMKN 8 Medan, Sumatera Utara',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Status zona dengan ukuran flexible
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _dalamZona
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _dalamZona
                            ? const Color(0xFF16A34A).withOpacity(0.3)
                            : const Color(0xFFDC2626).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dalamZona
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _dalamZona ? 'Dalam Zona' : 'Luar Zona',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _dalamZona
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Peta (Placeholder siap Google Maps) ──────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Placeholder peta sementara
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: const Color(0xFFE8F0FE),
                    child: CustomPaint(
                      painter: _MapPlaceholderPainter(),
                    ),
                  ),

                  // Radar animasi zona
                  Center(
                    child: AnimatedBuilder(
                      animation: _radarAnim,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Lingkaran zona memudar
                            Opacity(
                              opacity: (1 - _radarAnim.value).clamp(0, 1),
                              child: Container(
                                width: 120 + (60 * _radarAnim.value),
                                height: 120 + (60 * _radarAnim.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _dalamZona
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    width: 1.5,
                                  ),
                                  color: (_dalamZona
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626))
                                      .withOpacity(0.05),
                                ),
                              ),
                            ),
                            // Zona radius tetap
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _dalamZona
                                      ? const Color(0xFF16A34A).withOpacity(0.4)
                                      : const Color(0xFFDC2626).withOpacity(0.4),
                                  width: 1.5,
                                  strokeAlign: BorderSide.strokeAlignCenter,
                                ),
                                color: (_dalamZona
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626))
                                    .withOpacity(0.1),
                              ),
                            ),
                            // Pin lokasi
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1D4ED8)
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_pin_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Posisi Kamu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── Label "Zona Absensi" & Button View Map ─────
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        // Label Radius
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.radar_rounded,
                                size: 12,
                                color: Color(0xFF1D4ED8),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Radius 100m',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Button View Map
                        GestureDetector(
                          onTap: _showFullscreenMap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1D4ED8).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fullscreen_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Koordinat
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        '3.5946° N, 98.6722° E',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                          fontFamily: 'Poppins',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FULLSCREEN MAP VIEW — Dialog peta fullscreen
// ═══════════════════════════════════════════════════════════

class _FullscreenMapView extends StatelessWidget {
  final bool dalamZona;
  final VoidCallback onClose;

  const _FullscreenMapView({
    required this.dalamZona,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFF0F172A),
        child: Stack(
          children: [
            // ── Fullscreen Map Placeholder ─────────────────
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE8F0FE),
                child: CustomPaint(
                  painter: _FullscreenMapPlaceholderPainter(),
                  size: Size(size.width, size.height),
                ),
              ),
            ),

            // ── Radar Animation di Tengah ──────────────────
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran zona besar
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dalamZona
                            ? const Color(0xFF16A34A).withOpacity(0.4)
                            : const Color(0xFFDC2626).withOpacity(0.4),
                        width: 2,
                      ),
                      color: (dalamZona
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626))
                          .withOpacity(0.1),
                    ),
                  ),
                  // Pin lokasi besar
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Posisi Kamu Saat Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Header Info ────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Absensi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'SMKN 8 Medan, Sumatera Utara',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: dalamZona
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dalamZona
                                    ? const Color(0xFF16A34A).withOpacity(0.3)
                                    : const Color(0xFFDC2626).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dalamZona
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dalamZona ? 'Dalam Zona' : 'Luar Zona',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: dalamZona
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              size: 16,
                              color: Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Radius Zona Absensi: 100 meter',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Close Button (Sudut Kanan Atas) ───────────
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Info ────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.location_on,
                              label: 'Koordinat',
                              value: '3.5946° N\n98.6722° E',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.access_time_filled_rounded,
                              label: 'Akurasi GPS',
                              value: '± 5 meter',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.network_cell_rounded,
                              label: 'Sinyal',
                              value: 'Kuat (4G)',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Item Widget for Bottom Sheet ─────────────────────
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1D4ED8),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            fontFamily: 'Poppins',
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── Custom Painter Placeholder Map (Card Size) ────────────
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1DDF5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Grid jalan horizontal
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Grid jalan vertikal
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Blok gedung
    final blockPaint = Paint()
      ..color = const Color(0xFFC4D4F0)
      ..style = PaintingStyle.fill;

    final blocks = [
      Rect.fromLTWH(10, 10, 50, 30),
      Rect.fromLTWH(70, 50, 40, 25),
      Rect.fromLTWH(130, 10, 60, 35),
      Rect.fromLTWH(200, 55, 45, 30),
      Rect.fromLTWH(10, 80, 55, 40),
      Rect.fromLTWH(250, 10, 50, 30),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(4)),
        blockPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Custom Painter Fullscreen Map ─────────────────────────
class _FullscreenMapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1DDF5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Grid jalan horizontal (lebih rapat untuk fullscreen)
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Grid jalan vertikal
    for (double x = 0; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Blok gedung (randomly positioned untuk efek peta besar)
    final blockPaint = Paint()
      ..color = const Color(0xFFC4D4F0)
      ..style = PaintingStyle.fill;

    // Generate lebih banyak blok untuk fullscreen
    final randomBlocks = [
      Rect.fromLTWH(20, 20, 80, 50),
      Rect.fromLTWH(120, 80, 60, 40),
      Rect.fromLTWH(250, 30, 90, 60),
      Rect.fromLTWH(400, 100, 70, 45),
      Rect.fromLTWH(50, 150, 100, 70),
      Rect.fromLTWH(200, 200, 80, 50),
      Rect.fromLTWH(350, 250, 60, 40),
      Rect.fromLTWH(100, 300, 90, 55),
      Rect.fromLTWH(300, 350, 75, 45),
      Rect.fromLTWH(450, 400, 85, 60),
      Rect.fromLTWH(30, 450, 70, 50),
      Rect.fromLTWH(180, 500, 95, 65),
    ];

    for (final b in randomBlocks) {
      if (b.right < size.width && b.bottom < size.height) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(b, const Radius.circular(6)),
          blockPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}