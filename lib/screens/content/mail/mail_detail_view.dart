import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'mail_models.dart';
import 'mail_helpers.dart';

// ═══════════════════════════════════════════════════════════
// MAIL DETAIL VIEW — Isi email + balasan + form balas
// ═══════════════════════════════════════════════════════════

class MailDetailView extends StatefulWidget {
  final MailMessage mail;
  final VoidCallback onKembali;
  final void Function(MailMessage) onHapusPesan;

  const MailDetailView({
    super.key,
    required this.mail,
    required this.onKembali,
    required this.onHapusPesan,
  });

  @override
  State<MailDetailView> createState() => _MailDetailViewState();
}

class _MailDetailViewState extends State<MailDetailView> {
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _tampilFormBalas = false;
  bool _lihatSemuaBalasan = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _kirimBalas() {
    final isi = _replyCtrl.text.trim();
    if (isi.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      widget.mail.balasan.add(MailReply(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pengirim: 'Baihaqie Ar Rafi',
        inisial: 'BA',
        isi: isi,
        waktu: DateTime.now(),
        dariku: true,
      ));
      _replyCtrl.clear();
      _tampilFormBalas = false;
      _lihatSemuaBalasan = true;
    });
    _replyFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mail = widget.mail;
    final totalBalasan = mail.balasan.length;
    final tampilkanSemua = _lihatSemuaBalasan || totalBalasan <= 1;
    final balasanTampil =
        tampilkanSemua ? mail.balasan : mail.balasan.take(1).toList();

    return GestureDetector(
      onTap: () {
        if (_tampilFormBalas && !_replyFocusNode.hasFocus) {
          setState(() => _tampilFormBalas = false);
          _replyFocusNode.unfocus();
        }
      },
      child: Column(
        children: [
          // ── Header Detail ────────────────────────────────
          _DetailHeader(
            mail: mail,
            onKembali: widget.onKembali,
          ),

          // ── Konten Scrollable ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email utama
                  _EmailBody(mail: mail),
                  const SizedBox(height: 12),

                  // Balasan
                  if (totalBalasan > 0) ...[
                    if (!tampilkanSemua)
                      _LihatSemuaButton(
                        totalBalasan: totalBalasan,
                        onTap: () =>
                            setState(() => _lihatSemuaBalasan = true),
                      ),
                    ...balasanTampil
                        .map((r) => _ReplyCard(reply: r, mail: mail)),
                  ],

                  const SizedBox(height: 12),

                  // Form balas / tombol balas
                  if (_tampilFormBalas)
                    _FormBalas(
                      mail: mail,
                      replyCtrl: _replyCtrl,
                      replyFocusNode: _replyFocusNode,
                      onKirim: _kirimBalas,
                      onBatalkan: () {
                        setState(() => _tampilFormBalas = false);
                        _replyFocusNode.unfocus();
                      },
                    )
                  else
                    _TombolBalas(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _tampilFormBalas = true);
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _replyFocusNode.requestFocus(),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Header ─────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final MailMessage mail;
  final VoidCallback onKembali;

  const _DetailHeader({required this.mail, required this.onKembali});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Tombol kembali
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onKembali();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kMailBorder),
                      ),
                      child: const Icon(
                        FeatherIcons.arrowLeft,
                        size: 17,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mail.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: kMailTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: kMailBorder),
          ],
        ),
      ),
    );
  }
}

// ── Email Body ────────────────────────────────────────────
class _EmailBody extends StatelessWidget {
  final MailMessage mail;

  const _EmailBody({required this.mail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kMailBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header pengirim
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MailAvatar(inisial: mail.senderInitials, ukuran: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mail.senderName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kMailTextPrimary,
                              ),
                            ),
                          ),
                          MailRoleBadge(label: labelRole(mail.senderRole)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatWaktuLengkap(mail.waktu),
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: kMailTextMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Kepada: ',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: kMailTextMuted,
                            ),
                          ),
                          Text(
                            'Baihaqie Ar Rafi',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: kMailTextSecondary,
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

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),

          // Isi email
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Text(
              mail.preview,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF374151),
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reply Card ────────────────────────────────────────────
class _ReplyCard extends StatelessWidget {
  final MailReply reply;
  final MailMessage mail;

  const _ReplyCard({required this.reply, required this.mail});

  @override
  Widget build(BuildContext context) {
    final isDariku = reply.dariku;
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        left: isDariku ? 20 : 0,
        right: isDariku ? 0 : 20,
      ),
      decoration: BoxDecoration(
        color: isDariku ? kMailBiruMuda : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isDariku ? 14 : 4),
          bottomRight: Radius.circular(isDariku ? 4 : 14),
        ),
        border: Border.all(
          color: isDariku ? kMailBiruBorder : kMailBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                MailAvatar(
                  inisial: reply.inisial,
                  ukuran: 30,
                  kecil: true,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.pengirim,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kMailTextPrimary,
                        ),
                      ),
                      Text(
                        isDariku ? 'Siswa' : labelRole(mail.senderRole),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: kMailBiru,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatWaktuBalas(reply.waktu),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: kMailTextMuted,
                  ),
                ),
                if (isDariku) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    FeatherIcons.checkCircle,
                    size: 11,
                    color: kMailBiru,
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9, horizontal: 14),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              reply.isi,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lihat Semua Button ────────────────────────────────────
class _LihatSemuaButton extends StatelessWidget {
  final int totalBalasan;
  final VoidCallback onTap;

  const _LihatSemuaButton({
    required this.totalBalasan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kMailBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.messageSquare,
                size: 14, color: kMailBiru),
            const SizedBox(width: 7),
            Text(
              'Lihat semua $totalBalasan balasan',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kMailBiru,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(FeatherIcons.chevronDown,
                size: 13, color: kMailBiru),
          ],
        ),
      ),
    );
  }
}

// ── Tombol Balas ──────────────────────────────────────────
class _TombolBalas extends StatelessWidget {
  final VoidCallback onTap;

  const _TombolBalas({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kMailBiru.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.cornerUpLeft,
                size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Balas Pesan',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Balas ────────────────────────────────────────────
class _FormBalas extends StatefulWidget {
  final MailMessage mail;
  final TextEditingController replyCtrl;
  final FocusNode replyFocusNode;
  final VoidCallback onKirim;
  final VoidCallback onBatalkan;

  const _FormBalas({
    required this.mail,
    required this.replyCtrl,
    required this.replyFocusNode,
    required this.onKirim,
    required this.onBatalkan,
  });

  @override
  State<_FormBalas> createState() => _FormBalasState();
}

class _FormBalasState extends State<_FormBalas> {
  @override
  void initState() {
    super.initState();
    widget.replyCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.replyCtrl.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adaTeks = widget.replyCtrl.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kMailBiruBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: kMailBiru.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header form
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const MailAvatar(inisial: 'BA', ukuran: 30, kecil: true),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Baihaqie Ar Rafi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kMailTextPrimary,
                        ),
                      ),
                      Text(
                        'Membalas ${widget.mail.senderName}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: kMailTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol batal/tutup form
                GestureDetector(
                  onTap: widget.onBatalkan,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      FeatherIcons.x,
                      size: 13,
                      color: kMailTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Divider(color: Color(0xFFEEF2FF), height: 1),
          ),

          // Input + tombol kirim
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.replyCtrl,
                    focusNode: widget.replyFocusNode,
                    maxLines: null,
                    minLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis balasan...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFFD1D5DB),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: adaTeks ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: adaTeks ? widget.onKirim : null,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kMailBiru,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        FeatherIcons.send,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
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