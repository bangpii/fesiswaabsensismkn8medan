import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mail_models.dart';
import 'mail_helpers.dart';

// ═══════════════════════════════════════════════════════════
// MAIL DELETE DIALOG — Konfirmasi hapus pesan
// ═══════════════════════════════════════════════════════════

Future<void> tampilkanDialogHapus({
  required BuildContext context,
  required MailMessage mail,
  required VoidCallback onKonfirmasi,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => _HapusDialog(
      mail: mail,
      onKonfirmasi: onKonfirmasi,
    ),
  );
}

class _HapusDialog extends StatelessWidget {
  final MailMessage mail;
  final VoidCallback onKonfirmasi;

  const _HapusDialog({
    required this.mail,
    required this.onKonfirmasi,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 26,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),

            // Judul
            Text(
              'Hapus Pesan?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: kMailTextPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Deskripsi
            Text(
              'Pesan dari ${mail.senderName} akan dihapus secara permanen dan tidak dapat dikembalikan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: kMailTextSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol aksi
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kMailBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kMailTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onKonfirmasi();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }
}