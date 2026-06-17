// lib/screens/content/home.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_colors.dart';
import '../../../services/student_service.dart';
import '../../../services/student_data_cache.dart';
import '../../../services/notification_service.dart';
import 'header.dart';
import 'home/hero.dart';
import 'home/aksi_cepat.dart';
import 'home/event.dart';
import 'home/jadwal.dart';
import 'home/pengumuman.dart';

class HomeScreen extends StatefulWidget {

  final Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _jadwalKey = GlobalKey();
  final PageController _eventController = PageController();
  late AnimationController _waveController;

  // ── Event carousel ─────────────────────────────────────
  int _currentEvent = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  // ── Data state ─────────────────────────────────────────
  // 🔥 _isLoading hanya TRUE saat belum ada cache sama sekali
  bool _dataReady = false;
  bool _isLoading = false;
  String _namaLengkap = '';
  String? _photoUrl;
  UserRole _role = UserRole.siswa;
  List<Map<String, dynamic>> _jadwalHariIni = [];

  // ── Konstanta ──────────────────────────────────────────
  static const double _headerHeight = 140;
  final int _jumlahNotifikasi = 3;

  // ── Data statis ────────────────────────────────────────
  final List<Map<String, dynamic>> _events = [
    {
      'judul': 'Peringatan Hari Pendidikan Nasional',
      'tanggal': '2 Mei 2025',
      'kategori': 'Nasional',
      'warna': AppColors.accent,
      'gambar':
          'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=800&q=80',
    },
    // {
    //   'judul': 'Lomba Kompetensi Siswa (LKS) SMK 2025',
    //   'tanggal': '15 Mei 2025',
    //   'kategori': 'Kompetisi',
    //   'warna': Color(0xFF7C3AED),
    //   'gambar':
    //       'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80',
    // },
    // {
    //   'judul': 'Kunjungan Industri ke PT. Pertamina',
    //   'tanggal': '22 Mei 2025',
    //   'kategori': 'Industri',
    //   'warna': Color(0xFF0891B2),
    //   'gambar':
    //       'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&q=80',
    // },
    // {
    //   'judul': 'Ujian Akhir Semester Genap 2024/2025',
    //   'tanggal': '3–14 Juni 2025',
    //   'kategori': 'Akademik',
    //   'warna': Color(0xFF16A34A),
    //   'gambar':
    //       'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
    // },
  ];

  List<Map<String, dynamic>> get _loopEvents => [..._events, _events.first];

  // ═══════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final cache = StudentDataCache.instance;

    if (cache.isLoaded) {
      // ✅ Data sudah ada di cache → langsung tampil, TANPA loading
      _namaLengkap   = cache.namaLengkap;
      _photoUrl      = cache.photoUrl;
      _jadwalHariIni = cache.jadwalHariIni;
      _isLoading     = false;
      _dataReady     = true;

      // Carousel langsung start karena tidak ada loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startAutoScroll();
      });
    } else {
      // 🔄 Belum ada cache → fetch dari API
      _isLoading = true;
      _loadStudentData();
    }

    // 🔥 Start notification service
    NotificationService.instance.start();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _eventController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // FETCH DATA (hanya dipanggil sekali saat belum ada cache)
  // ═══════════════════════════════════════════════════════

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final login =
          prefs.getString('login') ?? prefs.getString('identifier') ?? '';

      debugPrint('🔍 [Home] login key: "$login"');

      if (login.isEmpty) {
        debugPrint('⚠️ [Home] login kosong di prefs!');
        if (mounted) {
          setState(() => _isLoading = false);
          _startAutoScroll();
        }
        return;
      }

      final raw = await StudentService.getStudentData(login);

      debugPrint(
          '📦 [Home] keys: ${raw.keys.toList()} | status: ${raw['status']}');

      if (!mounted) return;

      if (raw['message'] == 'Unauthenticated.') {
        debugPrint('❌ [Home] Token expired atau tidak valid!');
        setState(() => _isLoading = false);
        _startAutoScroll();
        return;
      }

      final user    = StudentService.extractUser(raw);
      final student = StudentService.extractStudent(raw);
      final sched   = StudentService.extractTodaySchedule(raw);

      debugPrint('👤 [Home] user.name: ${user['name']}');
      debugPrint('🎓 [Home] student.name: ${student['name']}');
      debugPrint('📅 [Home] today_schedule: ${sched.length} item → $sched');

      final nama = _val(student['name']) ?? _val(user['name']) ?? 'Pengguna';
      final foto = _val(student['photo']) ?? _val(user['photo']);

      debugPrint('✅ [Home] Nama: "$nama" | Foto: $foto');

      final jadwal = _buildJadwal(sched);
      debugPrint('📋 [Home] Jadwal: ${jadwal.length} item');

      // 🔥 Simpan ke cache supaya pindah tab tidak fetch ulang
      final cache         = StudentDataCache.instance;
      cache.isLoaded      = true;
      cache.namaLengkap   = nama;
      cache.photoUrl      = foto;
      cache.jadwalHariIni = jadwal;
      cache.rawData       = raw;

      if (!mounted) return;

      setState(() {
        _namaLengkap   = nama;
        _photoUrl      = foto;
        _role          = UserRole.siswa;
        _jadwalHariIni = jadwal;
        _isLoading     = false;
        _dataReady     = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startAutoScroll();
      });
    } catch (e, st) {
      debugPrint('❌ [Home] Exception: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
        _startAutoScroll();
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════

  String? _val(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  List<Map<String, dynamic>> _buildJadwal(
      List<Map<String, dynamic>> list) {
    if (list.isEmpty) return [];

    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) =>
        ((a['jam_masuk'] as String?) ?? '')
            .compareTo((b['jam_masuk'] as String?) ?? ''));

    final now    = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    return sorted.map((s) {
      final module  = _val(s['module'])  ?? '-';
      final teacher = _val(s['teacher']) ?? '-';
      final rawIn   = (s['jam_masuk']   as String?) ?? '00:00:00';
      final rawOut  = (s['jam_selesai'] as String?) ?? '00:00:00';
      final inMin   = _mnt(rawIn);
      final outMin  = _mnt(rawOut);

      final String status;
      if (nowMin > outMin) {
        status = 'selesai';
      } else if (nowMin >= inMin) {
        status = 'aktif';
      } else {
        status = 'akan datang';
      }

      return <String, dynamic>{
        'mapel'  : module,
        'guru'   : teacher,
        'jam'    : '${_fmt(rawIn)} – ${_fmt(rawOut)}',
        'ruang'  : '-',
        'status' : status,
        'icon'   : _moduleIcon(module),
      };
    }).toList();
  }

  int _mnt(String raw) {
    final p = raw.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  String _fmt(String raw) {
    final p = raw.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : raw;
  }

  IconData _moduleIcon(String name) {
    final l = name.toLowerCase();
    if (l.contains('agama')    || l.contains('religi')   ||
        l.contains('kristen')  || l.contains('islam')    ||
        l.contains('katholik') || l.contains('hindu')    ||
        l.contains('budha'))    return Boxicons.bx_book_heart;
    if (l.contains('matematika') || l.contains('math'))
                                    return FeatherIcons.hash;
    if (l.contains('bahasa') && l.contains('inggris'))
                                    return FeatherIcons.globe;
    if (l.contains('bahasa'))       return FeatherIcons.bookOpen;
    if (l.contains('komputer')  || l.contains('pemrograman') ||
        l.contains('coding')    || l.contains('tik') ||
        l.contains('rpl')       || l.contains('ddk') ||
        l.contains('tkkr')      || l.contains('software'))
                                    return Boxicons.bx_code_alt;
    if (l.contains('basis data') || l.contains('database'))
                                    return Boxicons.bx_data;
    if (l.contains('jaringan')  || l.contains('network'))
                                    return Boxicons.bx_network_chart;
    if (l.contains('fisika'))       return FeatherIcons.zap;
    if (l.contains('kimia'))        return FeatherIcons.droplet;
    if (l.contains('biologi'))      return FeatherIcons.feather;
    if (l.contains('sejarah')   || l.contains('pkn'))
                                    return FeatherIcons.flag;
    if (l.contains('olahraga')  || l.contains('penjas') ||
        l.contains('pjok'))         return FeatherIcons.activity;
    if (l.contains('seni')      || l.contains('budaya'))
                                    return FeatherIcons.penTool;
    if (l.contains('perhotelan') || l.contains('hotel'))
                                    return Boxicons.bx_building_house;
    if (l.contains('kecantikan'))   return Boxicons.bx_spa;
    if (l.contains('kejuruan')  || l.contains('produktif'))
                                    return Boxicons.bx_briefcase;
    if (l.contains('pkwu')      || l.contains('kewirausahaan'))
                                    return Boxicons.bx_store;
    return FeatherIcons.bookOpen;
  }

  // ── Auto scroll ────────────────────────────────────────
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted || _isUserInteracting) return;
      if (!_eventController.hasClients) return;

      final next = _currentEvent + 1;
      if (next >= _loopEvents.length) {
        _eventController.jumpToPage(0);
        if (mounted) setState(() => _currentEvent = 0);
      } else {
        _eventController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

void _onNotifikasiTap(BuildContext ctx) {
    // Modal sudah di-trigger langsung dari NotifButton
    // Tidak perlu action tambahan di sini
  }

  void _onProfilTap() => HapticFeedback.lightImpact();

  void _scrollToJadwal() {

      final context = _jadwalKey.currentContext;

      if (context != null) {

        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );

      }

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
          Positioned.fill(
            child: CustomPaint(painter: LightNetworkGridPainter()),
          ),
if (!_dataReady) _buildLoading(),
if (_dataReady) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildLoading() => Positioned.fill(
        child: Container(
          color: const Color(0xFFF0F6FF),
          child: Center(
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
                  'Memuat data...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildContent() => CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ───────────────────────────────────
          SliverPersistentHeader(
            delegate: SliverHeaderDelegate(
              headerHeight: _headerHeight,
namaLengkap: _namaLengkap,
              photoUrl: _photoUrl,
              role: _role,
              jumlahNotifikasi: NotificationService.instance.unreadCount,
              onNotifikasiTap: () => _onNotifikasiTap(context),
              onProfilTap: _onProfilTap,
            ),
            pinned: false,
            floating: false,
          ),

          // ── BODY ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroAbstrak(waveController: _waveController),
                const SizedBox(height: 20),

              _Pad(
                    child: SectionAksiCepat(
                      onNavigate: (index) {

                        widget.onNavigate?.call(index);

                      },

                      onJadwalTap: _scrollToJadwal,
                    ),
                  ),
                const SizedBox(height: 24),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pad(
                      child: _SectionHeader(
                        judul: 'Event Sekolah',
                        ikon: FeatherIcons.calendar,
                      ),
                    ),
                    const SizedBox(height: 14),
                    NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollStartNotification) {
                          setState(() => _isUserInteracting = true);
                        } else if (n is ScrollEndNotification) {
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              if (mounted) {
                                setState(
                                    () => _isUserInteracting = false);
                              }
                            },
                          );
                        }
                        return false;
                      },
                      child: KarouselEvent(
                        controller: _eventController,
                        currentIndex: _currentEvent,
                        onPageChanged: (i) {
                          setState(() {
                            _currentEvent = i;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                    key: _jadwalKey,
                    child: _Pad(
                      child: _jadwalHariIni.isEmpty
                          ? const _JadwalKosong()
                          : SectionJadwal(jadwal: _jadwalHariIni),
                    ),
                  ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const SectionPengumuman(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Jadwal kosong
// ═══════════════════════════════════════════════════════════

class _JadwalKosong extends StatelessWidget {
  const _JadwalKosong();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(FeatherIcons.clock, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Jadwal Hari Ini',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                FeatherIcons.coffee,
                size: 30,
                color: AppColors.textMuted.withOpacity(0.35),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada jadwal hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════

class _Pad extends StatelessWidget {
  final Widget child;
  const _Pad({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final String? aksi;
  final VoidCallback? onAksi;

  const _SectionHeader({
    required this.judul,
    required this.ikon,
    this.aksi,
    this.onAksi,
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
            onTap: onAksi,
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