import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// KAROUSEL EVENT
// ═══════════════════════════════════════════════════════════
class KarouselEvent extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const KarouselEvent({
    super.key,
    required this.events,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 40;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: events.length,
            physics: const BouncingScrollPhysics(),
            padEnds: false,
            clipBehavior: Clip.none,
            itemBuilder: (_, i) {
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 20 : 8,
                  right: i == events.length - 1 ? 20 : 8,
                ),
                child: KartuEvent(
                  event: events[i],
                  width: cardWidth,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Dot Indikator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            events.length - 1,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == currentIndex
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
}

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
            Image.network(
              event['gambar'] as String,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: (event['warna'] as Color).withValues(alpha: 0.2),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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