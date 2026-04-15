import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'config/app_colors.dart';
import 'screens/splash/splash.dart';
import 'screens/content/home.dart';
import 'screens/content/mail.dart';
import 'screens/content/absensi.dart';
import 'screens/footer/footer.dart';
import 'screens/content/izin.dart';
import 'screens/content/profile.dart';

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
// MAIN SCAFFOLD — Shell dengan Footer + Content (Header di dalam Home)
// ═══════════════════════════════════════════════════════════
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // ── Layar berdasarkan navigasi ─────────────────────────
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(); // Header sudah di dalam sini
      case 1:
        return const MailScreen();
      case 2:
         return const AbsensiScreen();
      case 3:
        return const IzinScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // HAPUS appBar: AppHeader(...) — sekarang di dalam HomeScreen
      body: AnimatedSwitcher(
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
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PLACEHOLDER SCREEN — untuk halaman yang belum dibuat
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
                  const Icon(Icons.fingerprint, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mulai Absensi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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