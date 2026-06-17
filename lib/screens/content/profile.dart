// lib/screens/content/profile.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../services/student_service.dart';
import '../../services/student_data_cache.dart';
import '../../services/auth_service.dart';
import 'profile/profile_models.dart';
import 'profile/profile_header_card.dart';
import 'profile/profile_kehadiran_section.dart';
import 'profile/profile_info_section.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE SCREEN — Root / Wadah Utama
// Data diambil dari backend via StudentDataCache
// ═══════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  // ── Animasi masuk ──────────────────────────────────────
  late AnimationController _slideController;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  // ── Data ──────────────────────────────────────────────
  bool              _isLoading  = false;
  DataSiswa         _siswa      = buatDummySiswa();
  DataKehadiranBulan _kehadiran = buatDummyKehadiran();
  List<DataNilai>   _nilaiList  = [];
  // DataTabungan      _tabungan   = buatDummyTabungan();

  // ═══════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    // ── Animasi slide masuk
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve:  Curves.easeOut,
    );

    _loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════

  Future<void> _loadData() async {
    final cache = StudentDataCache.instance;

    if (cache.isLoaded && cache.rawData.isNotEmpty) {
      // ✅ Pakai cache — tidak perlu fetch ulang
      _applyRawData(cache.rawData);
      return;
    }

    // 🔄 Belum ada cache → fetch
    if (mounted) setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final login = prefs.getString('login') ??
          prefs.getString('identifier') ?? '';

      if (login.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final raw = await StudentService.getStudentData(login);
      if (!mounted) return;

      if (raw['message'] == 'Unauthenticated.') {
        setState(() => _isLoading = false);
        return;
      }

      // Simpan ke cache kalau belum ada
      if (!cache.isLoaded) {
        final user    = StudentService.extractUser(raw);
        final student = StudentService.extractStudent(raw);
        cache.isLoaded    = true;
        cache.namaLengkap = student['name']?.toString() ??
            user['name']?.toString() ?? 'Pengguna';
        cache.photoUrl    = student['photo']?.toString() ??
            user['photo']?.toString();
        cache.rawData     = raw;
      }

      _applyRawData(raw);
    } catch (e) {
      debugPrint('❌ [Profile] Exception: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyRawData(Map<String, dynamic> raw) {
    // DataSiswa dari backend
    final innerData = StudentService.extractProfileData(raw);
    final siswa     = DataSiswa.fromBackend(innerData);

    // ✅ PERBAIKAN: Nilai dari nilai_ujian (bukan dari quizzes di modules)
    final nilaiRaw  = StudentService.extractNilaiUjian(raw);
    final nilaiList = nilaiRaw.map((n) => DataNilai(
      mapel      : n['mapel']?.toString()          ?? '-',
      nilai      : (n['nilai'] as num?)?.toDouble() ?? 0.0,
      grade      : n['grade']?.toString()           ?? '-',
      quizTitle  : n['quizTitle']?.toString(),
      isPassed   : n['isPassed'] as bool?           ?? false,
    )).toList();

    // Kehadiran & tabungan masih dummy (belum ada endpoint)
    final now     = DateTime.now();
    final minggu  = ((now.day - 1) ~/ 7) + 1;
    final kehadiran = DataKehadiranBulan(
      bulan            : now.month,
      tahun            : now.year,
      mingguKe         : minggu.clamp(1, 5),
      totalHadir       : 0,
      totalIzin        : 0,
      totalTerlambat   : 0,
      totalHariEfektif : 0,
    );

    if (mounted) {
      setState(() {
        _siswa     = siswa;
        _nilaiList = nilaiList;
        _kehadiran = kehadiran;
        _isLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  // LOGOUT — Langsung tampilkan modal konfirmasi
  // ═══════════════════════════════════════════════════════

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: _LogoutDialog(
              onConfirm: _doLogout,
            ),
          ),
        );
      },
    );
  }

  Future<void> _doLogout() async {
    Navigator.of(context).pop(); // tutup dialog

    // 🔥 BERSIHKAN SEMUA DATA SESSI
    await AuthService.logout();          // Hapus token di Dio + SharedPreferences
    StudentDataCache.instance.clear();   // Hapus cache data siswa

    // 🔥 PANGGIL CALLBACK LOGOUT
    if (mounted && widget.onLogout != null) {
      widget.onLogout!();
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🆕 BUKA MODAL BIODATA LENGKAP
  // ═══════════════════════════════════════════════════════

  void _showBiodataModal() {
    HapticFeedback.lightImpact();
    bukaBiodataModal(context, _siswa);
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
          // ── Background Network Mesh ────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ProfileNetworkGridPainter()),
          ),

          // ── Content ───────────────────────────────
          SafeArea(
            child: _isLoading
                ? _buildLoading()
                : SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ── Top Bar ───────────────
                          SliverToBoxAdapter(
                            child: _ProfileTopBar(
                              namaLengkap : _siswa.namaLengkap,
                              onBiodataTap: _showBiodataModal,
                              onLogoutTap : _showLogoutDialog,
                            ),
                          ),

                          // ── Header Card ───────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 4, bottom: 20),
                              child: ProfileHeaderCard(siswa: _siswa),
                            ),
                          ),

                          // ── Kelas + Jurusan Strip ─
                          SliverToBoxAdapter(
                            child: _KelasStrip(siswa: _siswa),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 24)),

                          // ── Kehadiran Bulan ───────
                          SliverToBoxAdapter(
                            child: const SectionKehadiranBulan(),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 24)),

                          // ── Nilai ─────────────────
                          SliverToBoxAdapter(
                            child: SectionNilaiSiswa(
                                nilaiList: _nilaiList),
                          ),

                          // const SliverToBoxAdapter(
                          //     child: SizedBox(height: 24)),

                          // // ── Tabungan ──────────────
                          // SliverToBoxAdapter(
                          //   child:
                          //       SectionTabunganSiswa(tabungan: _tabungan),
                          // ),

                          // ── Bottom Padding ────────
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Memuat profil...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOP BAR
// 🆕 Tombol "mata" (lihat biodata) ditaruh di samping kiri
//    tombol logout, ukuran & style serupa.
// ═══════════════════════════════════════════════════════════

class _ProfileTopBar extends StatelessWidget {
  final String namaLengkap;
  final VoidCallback onBiodataTap;
  final VoidCallback onLogoutTap;

  const _ProfileTopBar({
    required this.namaLengkap,
    required this.onBiodataTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
          ),

          const SizedBox(width: 12),

          // ── 🆕 Tombol Lihat Biodata (mata) ─────────────
          GestureDetector(
            onTap: onBiodataTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                FeatherIcons.eye,
                size: 17,
                color: AppColors.accent,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Tombol Logout ───────────────────────────────
          GestureDetector(
            onTap: onLogoutTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                FeatherIcons.logOut,
                size: 17,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  FeatherIcons.logOut,
                  size: 26,
                  color: Color(0xFFDC2626),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Keluar Akun',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Yakin ingin keluar?\nSemua data sesi akan dihapus.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDC2626),
                              Color(0xFFB91C1C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                FeatherIcons.logOut,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Keluar',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KELAS STRIP
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
              ikon : FeatherIcons.bookOpen,
              label: 'Kelas',
              nilai: siswa.kelas,
              warna: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _StripItem(
              ikon : FeatherIcons.cpu,
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
// PAINTER: Network Mesh
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
    final nodes    = _buildNodes(size);
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
      final isBig    = i % 9 == 0;
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