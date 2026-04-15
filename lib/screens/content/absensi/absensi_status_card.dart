import 'package:flutter/material.dart';
import 'absensi_models.dart';

// ═══════════════════════════════════════════════════════════
// ABSENSI STATUS CARD — Modern Elegant 3-Column Layout
// Jam Masuk | Durasi | Jam Pulang
// ═══════════════════════════════════════════════════════════

class AbsensiStatusCard extends StatelessWidget {
  final StatusAbsensi status;

  const AbsensiStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Static jam untuk preview tampilan
    final String jamMasuk = '07:14';
    final String jamPulang = '15:30';
    final String durasi = '8j 16m';

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isTablet = size.width >= 600 && size.width < 1200;

    return Container(
      margin: EdgeInsets.only(top: isSmallScreen ? 8 : 16),
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : (isTablet ? 12 : 10),
        horizontal: isSmallScreen ? 8 : (isTablet ? 16 : 12),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Jam Masuk ────────────────────────────────────
          Expanded(
            child: _ItemWaktu(
              label: 'Masuk',
              jam: jamMasuk,
              iconData: Icons.arrow_downward_rounded,
              isActive: true,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            ),
          ),

          // Divider vertikal
          Container(
            width: 0.8,
            height: isSmallScreen ? 32 : (isTablet ? 50 : 40),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : (isTablet ? 8 : 6)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFE2E8F0).withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.3),
                  const Color(0xFFE2E8F0).withOpacity(0.1),
                ],
              ),
            ),
          ),

          // ── Durasi ───────────────────────────────────────
          Expanded(
            child: _ItemDurasi(
              durasi: durasi,
              isActive: true,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            ),
          ),

          // Divider vertikal
          Container(
            width: 0.8,
            height: isSmallScreen ? 32 : (isTablet ? 50 : 40),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : (isTablet ? 8 : 6)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFE2E8F0).withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.3),
                  const Color(0xFFE2E8F0).withOpacity(0.1),
                ],
              ),
            ),
          ),

          // ── Jam Pulang ───────────────────────────────────
          Expanded(
            child: _ItemWaktu(
              label: 'Pulang',
              jam: jamPulang,
              iconData: Icons.arrow_upward_rounded,
              isActive: true,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget item waktu (Jam Masuk & Jam Pulang) ─────────────────────
class _ItemWaktu extends StatelessWidget {
  final String label;
  final String jam;
  final IconData iconData;
  final bool isActive;
  final bool isSmallScreen;
  final bool isTablet;

  const _ItemWaktu({
    required this.label,
    required this.jam,
    required this.iconData,
    required this.isActive,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2563EB);
    final darkBlue = const Color(0xFF1E40AF);
    
    return InkWell(
      onTap: () {
        // Add haptic feedback for better UX
        if (isActive) {
          // You can add navigation or tooltip here
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 4 : (isTablet ? 6 : 5),
          horizontal: isSmallScreen ? 2 : (isTablet ? 4 : 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dengan container biru
            Container(
              width: isSmallScreen ? 28 : (isTablet ? 36 : 32),
              height: isSmallScreen ? 28 : (isTablet ? 36 : 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive 
                    ? [primaryBlue, darkBlue]
                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : (isTablet ? 10 : 9)),
                boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ]
                  : null,
              ),
              child: Icon(
                iconData,
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                size: isSmallScreen ? 14 : (isTablet ? 18 : 16),
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : (isTablet ? 6 : 5)),
            
            // Jam dengan style modern dan ukuran lebih kecil
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : (isTablet ? 8 : 6),
                vertical: isSmallScreen ? 2 : (isTablet ? 4 : 3),
              ),
              decoration: BoxDecoration(
                color: isActive 
                  ? primaryBlue.withOpacity(0.06)
                  : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(isSmallScreen ? 5 : (isTablet ? 6 : 5.5)),
                border: Border.all(
                  color: isActive 
                    ? primaryBlue.withOpacity(0.12)
                    : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              child: Text(
                jam,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : (isTablet ? 13 : 11),
                  fontWeight: FontWeight.w700,
                  color: isActive ? darkBlue : const Color(0xFFCBD5E1),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 3 : (isTablet ? 5 : 4)),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : (isTablet ? 10 : 9),
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontFamily: 'Poppins',
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget durasi (Tengah) ─────────────────────────────────────────
class _ItemDurasi extends StatelessWidget {
  final String durasi;
  final bool isActive;
  final bool isSmallScreen;
  final bool isTablet;

  const _ItemDurasi({
    required this.durasi,
    required this.isActive,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2563EB);
    final darkBlue = const Color(0xFF1E40AF);
    
    return InkWell(
      onTap: () {
        // Add haptic feedback for better UX
        if (isActive) {
          // You can show duration details dialog here
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 4 : (isTablet ? 6 : 5),
          horizontal: isSmallScreen ? 2 : (isTablet ? 4 : 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon jam dengan ukuran lebih kecil
            Container(
              width: isSmallScreen ? 32 : (isTablet ? 40 : 36),
              height: isSmallScreen ? 32 : (isTablet ? 40 : 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive 
                    ? [primaryBlue, darkBlue]
                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : (isTablet ? 12 : 11)),
                boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: -1.5,
                      ),
                    ]
                  : null,
                border: Border.all(
                  color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.access_time_filled_rounded,
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                size: isSmallScreen ? 16 : (isTablet ? 22 : 18),
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : (isTablet ? 6 : 5)),
            
            // Durasi dengan ukuran lebih kecil
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : (isTablet ? 10 : 8),
                vertical: isSmallScreen ? 2 : (isTablet ? 5 : 3.5),
              ),
              decoration: BoxDecoration(
                gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryBlue.withOpacity(0.1),
                        darkBlue.withOpacity(0.05),
                      ],
                    )
                  : null,
                color: isActive ? null : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(isSmallScreen ? 6 : (isTablet ? 8 : 7)),
                border: Border.all(
                  color: isActive 
                    ? primaryBlue.withOpacity(0.15)
                    : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              child: Text(
                durasi,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                  fontWeight: FontWeight.w800,
                  color: isActive ? darkBlue : const Color(0xFFCBD5E1),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 3 : (isTablet ? 5 : 4)),
            
            // Label
            Text(
              'Durasi',
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : (isTablet ? 10 : 9),
                fontWeight: FontWeight.w600,
                color: isActive ? primaryBlue : const Color(0xFF94A3B8),
                fontFamily: 'Poppins',
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}