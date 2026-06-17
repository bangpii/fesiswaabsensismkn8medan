import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:boxicons/boxicons.dart';
import '../../../config/app_colors.dart';
import 'profile_models.dart';

// ═══════════════════════════════════════════════════════════
// SECTION NILAI SISWA
// ═══════════════════════════════════════════════════════════

class SectionNilaiSiswa extends StatelessWidget {
  final List<DataNilai> nilaiList;

  const SectionNilaiSiswa({super.key, required this.nilaiList});

  @override
  Widget build(BuildContext context) {
    // Hitung rata-rata
    final rataRata = nilaiList.isEmpty
        ? 0.0
        : nilaiList.fold<double>(0, (sum, n) => sum + n.nilai) / nilaiList.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Boxicons.bx_award, size: 16, color: const Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    'Nilai Semester',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                ),
                child: Text(
                  'Rata-rata ${rataRata.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Card wrapper
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: List.generate(nilaiList.length, (i) {
                final item = nilaiList[i];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.mapel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.nilai.toStringAsFixed(0),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 30,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _gradeColor(item.grade).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                item.grade,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _gradeColor(item.grade),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < nilaiList.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: AppColors.border.withOpacity(0.5),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFF16A34A);
    if (grade.startsWith('B')) return const Color(0xFF0891B2);
    if (grade.startsWith('C')) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION TABUNGAN SISWA
// ═══════════════════════════════════════════════════════════

// class SectionTabunganSiswa extends StatelessWidget {
//   final DataTabungan tabungan;

//   const SectionTabunganSiswa({super.key, required this.tabungan});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Boxicons.bx_wallet, size: 16, color: const Color(0xFFDC2626)),
//               const SizedBox(width: 6),
//               Text(
//                 'Tabungan Sekolah',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                   letterSpacing: -0.2,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
//               ),
//               borderRadius: BorderRadius.circular(18),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF1D4ED8).withOpacity(0.28),
//                   blurRadius: 20,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Icon(
//                     Boxicons.bx_wallet,
//                     size: 24,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         tabungan.label,
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.white.withOpacity(0.75),
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         tabungan.formatRupiah,
//                         style: GoogleFonts.poppins(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w800,
//                           color: Colors.white,
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Icon(
//                       FeatherIcons.trendingUp,
//                       size: 16,
//                       color: Colors.white.withOpacity(0.6),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       tabungan.tanggalUpdate,
//                       style: GoogleFonts.poppins(
//                         fontSize: 9.5,
//                         color: Colors.white.withOpacity(0.55),
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }