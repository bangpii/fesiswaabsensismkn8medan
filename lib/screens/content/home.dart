import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';
import 'header.dart';
import 'home/hero.dart';
import 'home/aksi_cepat.dart';
import 'home/event.dart';
import 'home/jadwal.dart';
import 'home/pengumuman.dart';

// ═══════════════════════════════════════════════════════════
// HOME SCREEN — Header Scroll Away Completely (No Pin)
// ═══════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Scroll Controller untuk animasi header ─────────────────
  final ScrollController _scrollController = ScrollController();

  // ── Animation Controllers ──────────────────────────────────
  final PageController _eventController = PageController();
  int _currentEvent = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  late AnimationController _waveController;

  // ── Data User ────────────────────────────────────────────
  final String _namaLengkap = 'Baihaqie Ar Rafi';
  final UserRole _role = UserRole.siswa;
  final int _jumlahNotifikasi = 3;

  // ── Konstanta ukuran header ──────────────────────────────
  static const double _headerHeight = 140;

  // ── Data Event ───────────────────────────────────────────
  final List<Map<String, dynamic>> _events = [
    {
      'judul': 'Peringatan Hari Pendidikan Nasional',
      'tanggal': '2 Mei 2025',
      'kategori': 'Nasional',
      'warna': AppColors.accent,
      'gambar':
          'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=800&q=80',
    },
    {
      'judul': 'Lomba Kompetensi Siswa (LKS) SMK 2025',
      'tanggal': '15 Mei 2025',
      'kategori': 'Kompetisi',
      'warna': Color(0xFF7C3AED),
      'gambar':
          'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80',
    },
    {
      'judul': 'Kunjungan Industri ke PT. Pertamina',
      'tanggal': '22 Mei 2025',
      'kategori': 'Industri',
      'warna': Color(0xFF0891B2),
      'gambar':
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&q=80',
    },
    {
      'judul': 'Ujian Akhir Semester Genap 2024/2025',
      'tanggal': '3–14 Juni 2025',
      'kategori': 'Akademik',
      'warna': Color(0xFF16A34A),
      'gambar':
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
    },
  ];

  List<Map<String, dynamic>> get _loopEvents => [..._events, _events.first];

  // ── Jadwal Pelajaran Hari Ini ────────────────────────────
  final List<Map<String, dynamic>> _jadwalHariIni = [
    {
      'mapel': 'Pemrograman Berorientasi Objek',
      'guru': 'Pak Rizky Pratama',
      'jam': '07:00 – 08:30',
      'ruang': 'Lab. Komputer 1',
      'status': 'selesai',
      'icon': Boxicons.bx_code_alt,
    },
    {
      'mapel': 'Basis Data',
      'guru': 'Bu Sari Indah',
      'jam': '08:30 – 10:00',
      'ruang': 'Lab. Komputer 2',
      'status': 'aktif',
      'icon': Boxicons.bx_data,
    },
    {
      'mapel': 'Matematika',
      'guru': 'Pak Ahmad Fauzi',
      'jam': '10:15 – 11:45',
      'ruang': 'Ruang 3.4',
      'status': 'akan datang',
      'icon': FeatherIcons.bookOpen,
    },
    {
      'mapel': 'Bahasa Inggris',
      'guru': 'Bu Dewi Kartika',
      'jam': '12:30 – 14:00',
      'ruang': 'Ruang 2.1',
      'status': 'akan datang',
      'icon': FeatherIcons.globe,
    },
    {
      'mapel': 'Bahasa Spanyol',
      'guru': 'Baihaqie Ar Rafi',
      'jam': '12:30 – 22:00',
      'ruang': 'Ruang 2.1',
      'status': 'akan datang',
      'icon': FeatherIcons.globe,
    },
  ];

  // ── Pengumuman ────────────────────────────────────────────
  final List<Map<String, dynamic>> _pengumuman = [
    {
      'judul': 'Pengumpulan Tugas Akhir Semester',
      'isi':
          'Batas pengumpulan tugas akhir semester adalah tanggal 30 Mei 2025. Pastikan semua tugas dikumpulkan tepat waktu.',
      'waktu': '2 jam lalu',
      'icon': FeatherIcons.fileText,
      'warna': AppColors.accent,
    },
    {
      'judul': 'Jadwal Piket Kelas Diperbarui',
      'isi':
          'Jadwal piket kelas telah diperbarui untuk semester genap. Silakan cek papan pengumuman di kelas masing-masing.',
      'waktu': '1 hari lalu',
      'icon': FeatherIcons.clipboard,
      'warna': Color(0xFF7C3AED),
    },
    {
      'judul': 'Pembayaran SPP Bulan Mei',
      'isi':
          'Harap segera melakukan pembayaran SPP bulan Mei sebelum tanggal 10. Keterlambatan dikenakan denda administrasi.',
      'waktu': '2 hari lalu',
      'icon': Boxicons.bx_wallet,
      'warna': Color(0xFFF59E0B),
    },
    {
      'judul': 'Peraturan Seragam Sekolah Baru',
      'isi':
          'Mulai 1 Juni 2025 berlaku peraturan seragam baru. Setiap siswa wajib mengenakan seragam lengkap sesuai ketentuan.',
      'waktu': '3 hari lalu',
      'icon': FeatherIcons.alertCircle,
      'warna': Color(0xFF0891B2),
    },
    {
      'judul': 'Pendaftaran Ekstrakurikuler Dibuka',
      'isi':
          'Pendaftaran ekstrakurikuler semester genap resmi dibuka. Segera daftarkan diri sebelum kuota penuh.',
      'waktu': '4 hari lalu',
      'icon': FeatherIcons.star,
      'warna': Color(0xFF16A34A),
    },
    {
      'judul': 'Libur Hari Raya Waisak',
      'isi':
          'Sekolah libur pada tanggal 12 Mei 2025 dalam rangka peringatan Hari Raya Waisak. Kegiatan belajar dimulai kembali 13 Mei.',
      'waktu': '5 hari lalu',
      'icon': Boxicons.bx_calendar_event,
      'warna': Color(0xFFDC2626),
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted || _isUserInteracting) return;
      final next = _currentEvent + 1;
      if (next >= _loopEvents.length) {
        _eventController.jumpToPage(0);
        setState(() => _currentEvent = 0);
      } else {
        _eventController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    _eventController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────

  void _onNotifikasiTap(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifikasi',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onProfilTap() {
    HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: Stack(
        children: [
          // ── Background Network Grid ──────────────────────
          Positioned.fill(
            child: CustomPaint(painter: LightNetworkGridPainter()),
          ),

          // ── Custom Scroll View ───────────────────────────
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═════════════════════════════════════════════
              // SLIVER HEADER — SCROLL AWAY COMPLETELY
              // ═════════════════════════════════════════════
              SliverPersistentHeader(
                delegate: SliverHeaderDelegate(
                  headerHeight: _headerHeight,
                  namaLengkap: _namaLengkap,
                  role: _role,
                  jumlahNotifikasi: _jumlahNotifikasi,
                  onNotifikasiTap: () => _onNotifikasiTap(context),
                  onProfilTap: _onProfilTap,
                ),
                pinned: false,
                floating: false,
              ),

              // ═════════════════════════════════════════════
              // CONTENT
              // ═════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroAbstrak(waveController: _waveController),

                    const SizedBox(height: 20),

                              _SectionPadding(
                      child: const SectionAksiCepat(),
                    ),

                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionPadding(
                          child: _SectionHeader(
                            judul: 'Event Sekolah',
                            ikon: FeatherIcons.calendar,
                          ),
                        ),
                        const SizedBox(height: 14),
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              setState(() => _isUserInteracting = true);
                            } else if (notification is ScrollEndNotification) {
                              Future.delayed(
                                  const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  setState(() => _isUserInteracting = false);
                                }
                              });
                            }
                            return false;
                          },
                          child: KarouselEvent(
                            events: _loopEvents,
                            controller: _eventController,
                            currentIndex: _currentEvent % _events.length,
                            onPageChanged: (i) {
                              if (i >= _events.length) {
                                _eventController.jumpToPage(0);
                                setState(() => _currentEvent = 0);
                              } else {
                                setState(() => _currentEvent = i);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _SectionPadding(
                        child: SectionJadwal(jadwal: _jadwalHariIni)),

                    const SizedBox(height: 24),

                    _SectionPadding(
                        child: SectionPengumuman(pengumuman: _pengumuman)),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HELPER WIDGETS — Layout konten (tetap di home.dart)
// ═══════════════════════════════════════════════════════════

class _SectionPadding extends StatelessWidget {
  final Widget child;
  const _SectionPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final String? aksi;

  const _SectionHeader({
    required this.judul,
    required this.ikon,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(ikon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              judul,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (aksi != null)
          GestureDetector(
            onTap: () {},
            child: Text(
              aksi!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}