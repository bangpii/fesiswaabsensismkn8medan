import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../config/app_colors.dart';
import 'profile/profile_models.dart';
import 'profile/profile_header_card.dart';
import 'profile/profile_kehadiran_section.dart';
import 'profile/profile_info_section.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE SCREEN — Root / Wadah Utama
// Background: Network Mesh Abstrak (sama dengan halaman lain)
// ═══════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // ── Data ──────────────────────────────────────────────
  late final DataSiswa _siswa;
  late final DataKehadiranBulan _kehadiran;
  late final List<DataNilai> _nilaiList;
  late final DataTabungan _tabungan;

  @override
  void initState() {
    super.initState();
    _siswa = buatDummySiswa();
    _kehadiran = buatDummyKehadiran();
    _nilaiList = buatDummyNilai();
    _tabungan = buatDummyTabungan();

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

    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: Stack(
        children: [
          // ── Background Network Mesh ──────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ProfileNetworkGridPainter()),
          ),

          // ── Content ─────────────────────────────────
          SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Top Bar ──────────────────────
                    SliverToBoxAdapter(
                      child: _ProfileTopBar(namaLengkap: _siswa.namaLengkap),
                    ),

                    // ── Header Card (Avatar + Info) ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        child: ProfileHeaderCard(siswa: _siswa),
                      ),
                    ),

                    // ── Kelas + Jurusan Info Strip ────
                    SliverToBoxAdapter(
                      child: _KelasStrip(siswa: _siswa),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Kehadiran Bulan ───────────────
                    SliverToBoxAdapter(
                      child: SectionKehadiranBulan(data: _kehadiran),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Nilai ─────────────────────────
                    SliverToBoxAdapter(
                      child: SectionNilaiSiswa(nilaiList: _nilaiList),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Tabungan ──────────────────────
                    SliverToBoxAdapter(
                      child: SectionTabunganSiswa(tabungan: _tabungan),
                    ),

                    // ── Bottom Padding ────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
// TOP BAR — Judul Halaman Profile
// ═══════════════════════════════════════════════════════════

class _ProfileTopBar extends StatelessWidget {
  final String namaLengkap;
  const _ProfileTopBar({required this.namaLengkap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil Saya',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Informasi akun siswa',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          // Edit Profile button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                FeatherIcons.settings,
                size: 17,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KELAS STRIP — Info kelas & jurusan
// ═══════════════════════════════════════════════════════════

class _KelasStrip extends StatelessWidget {
  final DataSiswa siswa;
  const _KelasStrip({required this.siswa});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StripItem(
              ikon: FeatherIcons.bookOpen,
              label: 'Kelas',
              nilai: siswa.kelas,
              warna: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _StripItem(
              ikon: FeatherIcons.cpu,
              label: 'Jurusan',
              nilai: siswa.jurusan,
              warna: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;
  final Color warna;

  const _StripItem({
    required this.ikon,
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 14, color: warna),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: warna.withOpacity(0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  nilai,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: warna,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTER: Network Mesh Abstrak (sama persis halaman lain)
// ═══════════════════════════════════════════════════════════

class _ProfileNetworkGridPainter extends CustomPainter {
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
        list.add(
            Offset(x.clamp(0, size.width), y.clamp(0, size.height)));
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
  bool shouldRepaint(_ProfileNetworkGridPainter old) => false;
}