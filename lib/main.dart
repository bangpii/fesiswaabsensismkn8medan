// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'config/app_colors.dart';
import 'screens/splash/splash.dart';
import 'screens/content/home.dart';
import 'screens/content/mail.dart';
import 'screens/content/absensi.dart';
import 'screens/footer/footer.dart';
import 'screens/content/izin.dart';
import 'screens/content/profile.dart';
import 'screens/splash/login.dart';
import 'screens/splash/lupa_password.dart';
import 'services/ping_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/student_data_cache.dart';

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi SMKN 8 Medan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MAIN SCAFFOLD — Shell dengan Footer + Content
// ═══════════════════════════════════════════════════════════
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  int _currentIndex = 0;

  // 🔥 AUTH STATE
  bool _showLogin      = true;
  bool _isLoggedIn     = false;
  bool _isCheckingAuth = true; // true saat pertama kali cek token
  int _loginCount      = 0;

  // 🔥 ANIMATION VARIABLES UNTUK FADE OUT MODAL
  bool _isModalVisible = true;
  late AnimationController _modalFadeController;
  late Animation<double>   _modalOpacityAnimation;
  late Animation<double>   _modalScaleAnimation;

  // ── Layar berdasarkan navigasi ─────────────────────────
  Widget _getScreen(int index) {
    switch (index) {
    case 0:  return HomeScreen(
  key: ValueKey('home_$_loginCount'),
  onNavigate: (i) {
    setState(() {
      _currentIndex = i;
    });
  },
);
      case 1:  return const MailScreen();
      case 2:  return const AbsensiScreen();
      case 3:  return const IzinScreen();
      case 4:  return ProfileScreen(onLogout: _handleLogout);
      default: return HomeScreen(
  onNavigate: (i) {

    setState(() {
      _currentIndex = i;
    });

  },
);
    }
  }

  // ═══════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔥 Observer lifecycle app
    _setupModalAnimation();
    _checkExistingLogin();                      // 🔥 Cek token tersimpan

    // Ping callback
    PingService.onStatusChanged = (isOnline) {
      debugPrint(isOnline ? '🟢 [Ping] ONLINE' : '🔴 [Ping] OFFLINE');
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PingService.stop();
    _modalFadeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // 🔥 APP LIFECYCLE OBSERVER
  // Keluar app  → set offline (ping stop)
  // Buka lagi   → set online (ping start)
  // TIDAK logout — user harus klik logout sendiri
  // ═══════════════════════════════════════════════════════
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {

      // 🟢 App kembali ke foreground
      case AppLifecycleState.resumed:
        if (_isLoggedIn) {
          debugPrint('📱 [App] Resumed → start ping');
          PingService.start();
        }
        break;

      // 🔴 App ke background / di-minimize / layar dikunci
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_isLoggedIn) {
          debugPrint('📱 [App] Paused/Inactive → stop ping → offline');
          PingService.stop();
          // Fire-and-forget: beritahu server offline
          _setOfflineQuiet();
        }
        break;

      // 🔴 App di-detach (di-kill dari task manager)
      case AppLifecycleState.detached:
        if (_isLoggedIn) {
          debugPrint('📱 [App] Detached → offline');
          PingService.stop();
          _setOfflineQuiet();
        }
        break;

      default:
        break;
    }
  }

  /// Kirim status offline ke server tanpa blocking UI
  void _setOfflineQuiet() {
    ApiService.dio.get('/status').catchError((_) {});
    // Reverb realtime sudah handle via AuthController@ping timeout
    // Tidak perlu hapus token — user masih login
  }

  // ═══════════════════════════════════════════════════════
  // 🔥 CEK TOKEN TERSIMPAN — Persistent Login
  // Saat app dibuka, cek apakah token masih ada di SharedPreferences
  // Kalau ada → langsung masuk tanpa perlu login ulang
  // ═══════════════════════════════════════════════════════
 Future<void> _checkExistingLogin() async {
    try {
      await ApiService.loadToken();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Tidak ada token → tampil login
      if (token == null || token.isEmpty) {
        if (mounted) setState(() {
          _isLoggedIn     = false;
          _isCheckingAuth = false;
          _isModalVisible = true;
        });
        return;
      }

      // Ada token → coba validasi ke server
      try {
        final result = await AuthService.status();

        // HANYA logout kalau server eksplisit bilang Unauthenticated
        final isExplicitlyUnauth = result != null &&
            result is Map &&
            result['message'] == 'Unauthenticated.';

        if (isExplicitlyUnauth) {
          debugPrint('❌ [Auth] Token tidak valid → logout');
          await ApiService.clearToken();
          if (mounted) setState(() {
            _isLoggedIn     = false;
            _isCheckingAuth = false;
            _isModalVisible = true;
          });
          return;
        }

        // Server OK → tetap login
        debugPrint('✅ [Auth] Token valid → auto login');
        if (mounted) {
          PingService.start();
          setState(() {
            _isLoggedIn     = true;
            _isModalVisible = false;
            _isCheckingAuth = false;
          });
          _modalFadeController.forward();
        }

      } catch (networkError) {
        // Server mati / timeout → TETAP LOGIN, jangan hapus token
        debugPrint('⚠️ [Auth] Server tidak bisa dicapai, tetap login: $networkError');
        if (mounted) {
          PingService.start();
          setState(() {
            _isLoggedIn     = true;
            _isModalVisible = false;
            _isCheckingAuth = false;
          });
          _modalFadeController.forward();
        }
      }

    } catch (e) {
      debugPrint('⚠️ [Auth] Error tak terduga: $e');
      if (mounted) setState(() {
        _isLoggedIn     = false;
        _isCheckingAuth = false;
        _isModalVisible = true;
      });
    }
  }

  void _setupModalAnimation() {
    _modalFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _modalOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _modalFadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _modalScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _modalFadeController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 🔥 HANDLE LOGIN SUCCESS
  // ═══════════════════════════════════════════════════════
void _handleLoginSuccess() async {
    if (mounted) {
      PingService.start();
      setState(() {
        _isLoggedIn     = true;
        _isModalVisible = false;
        _loginCount     += 1;
      });
    }
    _modalFadeController.forward();
}

  // ═══════════════════════════════════════════════════════
  // 🔥 HANDLE LOGOUT — Hanya dipanggil saat user klik tombol Keluar
  // USB putus / app di-background TIDAK akan trigger ini
  // ═══════════════════════════════════════════════════════
  void _handleLogout() {
    PingService.stop();                  // Hentikan ping
    StudentDataCache.instance.clear();   // Bersihkan cache

    setState(() {
      _isLoggedIn     = false;
      _showLogin      = true;
      _isModalVisible = true;
      _currentIndex   = 0;
    });
    _modalFadeController.reset();
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Saat masih mengecek token (splash singkat)
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1D4ED8),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
        // 🔥 supaya footer tidak ikut naik saat keyboard muncul
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════
          // LAYER 1: MAIN CONTENT
          // ═══════════════════════════════════════════════
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _getScreen(_currentIndex),
            ),
          ),

          // ═══════════════════════════════════════════════
          // LAYER 2: FOOTER
          // ═══════════════════════════════════════════════
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppFooter(
              currentIndex: _currentIndex,
              onTap: (i) {
                if (_isLoggedIn) {
                  setState(() => _currentIndex = i);
                }
              },
            ),
          ),

          // ═══════════════════════════════════════════════
          // LAYER 3: BLUR + MODAL LOGIN
          // Hanya tampil kalau belum login
          // ═══════════════════════════════════════════════
          if (!_isLoggedIn) ...[
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _isModalVisible ? 1.0 : 0.0,
                curve: Curves.easeOutCubic,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _modalFadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _modalOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _modalScaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(_showLogin),
                    width: MediaQuery.of(context).size.width * 0.88,
                    constraints: const BoxConstraints(
                      maxWidth: 380,
                      minHeight: 480,
                      maxHeight: 640,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 30,
                          spreadRadius: 5,
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _showLogin
                        ? LoginScreen(
                            onForgot: () {
                              setState(() => _showLogin = false);
                            },
                            onLoginSuccess: _handleLoginSuccess,
                          )
                        : LupaPasswordScreen(
                            onBack: () {
                              setState(() => _showLogin = true);
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PLACEHOLDER SCREEN
// ═══════════════════════════════════════════════════════════
class _PlaceholderScreen extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Color warna;
  final bool isAbsensi;

  const _PlaceholderScreen({
    required this.judul,
    required this.ikon,
    required this.warna,
    this.isAbsensi = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: warna.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: warna.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(ikon, size: 36, color: warna),
          ),
          const SizedBox(height: 20),
          Text(
            'Halaman $judul',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Segera hadir',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          if (isAbsensi) ...[
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mulai Absensi',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}