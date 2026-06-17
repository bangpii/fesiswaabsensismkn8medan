import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../services/izin_pesan_realtime_service.dart';
import 'mail_models.dart';
import 'mail_helpers.dart';

// ═══════════════════════════════════════════════════════════
// MAIL DETAIL VIEW — Chat realtime ala WhatsApp + header Gmail
// ═══════════════════════════════════════════════════════════

class MailDetailView extends StatefulWidget {
  final IzinModel izin;
  final VoidCallback onKembali;

  const MailDetailView({
    super.key,
    required this.izin,
    required this.onKembali,
  });

  @override
  State<MailDetailView> createState() => _MailDetailViewState();
}

class _MailDetailViewState extends State<MailDetailView> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _showInput = false;
  List<IzinPesanModel> _pesans = [];
  StreamSubscription? _pesanSub;

  @override
  void initState() {
    super.initState();
    _pesans = List.from(widget.izin.pesans);

    // Mark as read
    IzinPesanRealtimeService.markAsRead(widget.izin.id);

    // Start listening realtime
    IzinPesanRealtimeService.start();

    // Subscribe to realtime updates
    _pesanSub = IzinPesanRealtimeService.stream.listen((state) {
      if (!mounted) return;
      if (state.izinId != widget.izin.id) return;

      if (state.action == PesanAction.message && state.pesan != null) {
        final newPesan = IzinPesanModel.fromJson(state.pesan!);
        final exists = _pesans.any((p) => p.id == newPesan.id);
        if (!exists) {
          setState(() => _pesans.add(newPesan));
          _scrollToBottom();
          // Auto mark as read
          IzinPesanRealtimeService.markAsRead(widget.izin.id);
        }
      } else if (state.action == PesanAction.read) {
        setState(() {
          for (final p in _pesans) {
            if (p.dariSiswa) p.isRead = true;
          }
        });
      }
    });

    _scrollToBottomDelayed();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottomDelayed() {
    Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
  }

  // ═══════════════════════════════════════
  // 🔥 BUKA INPUT CHAT + AUTO FOKUS KEYBOARD
  // ═══════════════════════════════════════
  void _bukaInputBalas() {
    HapticFeedback.lightImpact();
    setState(() => _showInput = true);
    // Delay sedikit agar widget sudah ter-render, baru request focus
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _focusNode.requestFocus();
        _scrollToBottom();
      }
    });
  }

  void _tutupInput() {
    _focusNode.unfocus();
    setState(() {
      _showInput = false;
      _inputCtrl.clear();
    });
  }

  Future<void> _kirimPesan() async {
    final teks = _inputCtrl.text.trim();
    if (teks.isEmpty || _isSending) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    final result = await IzinPesanRealtimeService.kirimPesan(
      izinId: widget.izin.id,
      pesan: teks,
    );

    if (result['success'] == true && mounted) {
      final data = result['data'];
      if (data != null) {
        final pesanBaru = IzinPesanModel.fromJson(data);
        final exists = _pesans.any((p) => p.id == pesanBaru.id);
        if (!exists) {
          setState(() => _pesans.add(pesanBaru));
        }
      }
      _inputCtrl.clear();
      _scrollToBottom();
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _pesanSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  // 🔥 viewInsets.bottom = tinggi keyboard saat ini
  final keyboardH = MediaQuery.of(context).viewInsets.bottom;
  final isKeyboardOpen = keyboardH > 0;

  return GestureDetector(
    behavior: HitTestBehavior.translucent,

    // 🔥 klik area luar = tutup keyboard
    onTap: () {
      FocusScope.of(context).unfocus();
    },

    child: Scaffold(
      backgroundColor: Colors.transparent,

      // 🔥 footer tidak ikut naik
      resizeToAvoidBottomInset: false,

      body: Column(
        children: [
          _ChatHeader(
            izin: widget.izin,
            onKembali: widget.onKembali,
          ),

          _IzinInfoBanner(
            izin: widget.izin,
          ),

          // 🔥 Chat body
          Expanded(
            child: _ChatBody(
              pesans: _pesans,
              scrollCtrl: _scrollCtrl,
              onBalas: _bukaInputBalas,
            ),
          ),

          // 🔥 INPUT AREA
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),

            crossFadeState: _showInput
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            firstChild: const SizedBox.shrink(),

            secondChild: _ChatInput(
              ctrl: _inputCtrl,
              focusNode: _focusNode,
              isSending: _isSending,
              keyboardHeight: keyboardH,
              isKeyboardOpen: isKeyboardOpen,
              onKirim: _kirimPesan,
              onTutup: _tutupInput,
            ),
          ),
        ],
      ),
    ),
  );
}
}

// ── Chat Header ───────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final IzinModel izin;
  final VoidCallback onKembali;

  const _ChatHeader({required this.izin, required this.onKembali});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onKembali();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        FeatherIcons.arrowLeft,
                        size: 17,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MailAvatar(
                    inisial: 'A',
                    ukuran: 38,
                    warna: const Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Sekolah',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kMailTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: kMailSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: kMailSuccess,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IzinStatusBadge(status: izin.status),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
          ],
        ),
      ),
    );
  }
}

// ── Izin Info Banner ──────────────────────────────────────
class _IzinInfoBanner extends StatelessWidget {
  final IzinModel izin;

  const _IzinInfoBanner({required this.izin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kMailBiruMuda,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: kMailBiru.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              izin.jenisIzin == IzinJenis.sakit
                  ? FeatherIcons.thermometer
                  : FeatherIcons.fileText,
              size: 14,
              color: kMailBiru,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${izin.jenisLabel} · ${formatTanggalIzin(izin.tanggalIzin)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: kMailBiru,
                  ),
                ),
                Text(
                  izin.keterangan,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: kMailTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IzinJenisBadge(jenis: izin.jenisIzin),
        ],
      ),
    );
  }
}

// ── Chat Body ─────────────────────────────────────────────
class _ChatBody extends StatelessWidget {
  final List<IzinPesanModel> pesans;
  final ScrollController scrollCtrl;
  final VoidCallback onBalas;

  const _ChatBody({
    required this.pesans,
    required this.scrollCtrl,
    required this.onBalas,
  });

  @override
  Widget build(BuildContext context) {
    if (pesans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.messageCircle,
                size: 36, color: kMailBiruBorder),
            const SizedBox(height: 10),
            Text(
              'Belum ada pesan',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kMailTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            // 🔥 Tombol balas jika kosong
            _BalasButton(onTap: onBalas, kecil: false),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      physics: const BouncingScrollPhysics(),
      itemCount: pesans.length,
      itemBuilder: (_, i) {
        final p = pesans[i];
        final showDateSep =
            i == 0 || !_isSameDay(pesans[i - 1].createdAt, p.createdAt);

        // 🔥 Tampilkan tombol balas hanya setelah bubble admin terakhir
        final isLastAdminBubble = !p.dariSiswa &&
            (i == pesans.length - 1 ||
                pesans.sublist(i + 1).every((x) => x.dariSiswa));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateSep) _DateSeparator(date: p.createdAt),
            _ChatBubble(
              pesan: p,
              showBalasButton: isLastAdminBubble,
              onBalas: onBalas,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Date Separator ────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: kMailBorder, thickness: 0.6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kMailBorder, width: 0.8),
              ),
              child: Text(
                _label(),
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: kMailTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
              child: Divider(color: kMailBorder, thickness: 0.6)),
        ],
      ),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final IzinPesanModel pesan;
  final bool showBalasButton;
  final VoidCallback onBalas;

  const _ChatBubble({
    required this.pesan,
    required this.showBalasButton,
    required this.onBalas,
  });

  @override
  Widget build(BuildContext context) {
    final isDariku = pesan.dariSiswa;

    return Padding(
      padding: EdgeInsets.only(
        bottom: showBalasButton ? 4 : 6,
        left: isDariku ? 48 : 0,
        right: isDariku ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isDariku ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isDariku ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isDariku) ...[
                MailAvatar(
                  inisial: 'A',
                  ukuran: 28,
                  kecil: true,
                  warna: kMailBiru,
                ),
                const SizedBox(width: 6),
              ],

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDariku ? kMailBiru : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isDariku ? 16 : 4),
                      bottomRight:
                          Radius.circular(isDariku ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDariku
                            ? kMailBiru.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isDariku
                        ? null
                        : Border.all(
                            color: kMailBorder, width: 0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: isDariku
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isDariku)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Admin Sekolah',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: kMailBiru,
                            ),
                          ),
                        ),
                      Text(
                        pesan.pesan,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDariku
                              ? Colors.white
                              : kMailTextPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatWaktuChat(pesan.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: isDariku
                                  ? Colors.white.withOpacity(0.65)
                                  : kMailTextMuted,
                            ),
                          ),
                          if (isDariku) ...[
                            const SizedBox(width: 4),
                            ReadReceiptIcon(
                              isRead: pesan.isRead,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔥 TOMBOL BALAS — muncul di bawah bubble admin terakhir
          if (showBalasButton && !isDariku)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 6, bottom: 4),
              child: _BalasButton(onTap: onBalas, kecil: true),
            ),
        ],
      ),
    );
  }
}

// ── Tombol Balas ──────────────────────────────────────────
class _BalasButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool kecil;

  const _BalasButton({required this.onTap, required this.kecil});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kecil ? 10 : 16,
          vertical: kecil ? 5 : 9,
        ),
        decoration: BoxDecoration(
          color: kMailBiruMuda,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kMailBiruBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FeatherIcons.cornerUpLeft,
              size: kecil ? 11 : 14,
              color: kMailBiru,
            ),
            const SizedBox(width: 5),
            Text(
              'Balas Pesan',
              style: GoogleFonts.poppins(
                fontSize: kecil ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: kMailBiru,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Input (keyboard-aware, di atas footer) ───────────
class _ChatInput extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isSending;
  final double keyboardHeight;
  final bool isKeyboardOpen;
  final VoidCallback onKirim;
  final VoidCallback onTutup;

  const _ChatInput({
    required this.ctrl,
    required this.focusNode,
    required this.isSending,
    required this.keyboardHeight,
    required this.isKeyboardOpen,
    required this.onKirim,
    required this.onTutup,
  });

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _adaTeks = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      final ada = widget.ctrl.text.trim().isNotEmpty;
      if (ada != _adaTeks) setState(() => _adaTeks = ada);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Safe area bottom (notch/home bar) — hanya saat keyboard TIDAK muncul
    final safeBottom = widget.isKeyboardOpen
        ? 0.0
        : MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      // 🔥 Padding bottom = tinggi keyboard + safe area
      // Ini yang bikin input naik tepat di atas keyboard
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: widget.keyboardHeight + safeBottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🔥 Tombol tutup input (X)
          GestureDetector(
            onTap: widget.onTutup,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FeatherIcons.x,
                size: 15,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔥 TextField multiline
          Expanded(
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? kMailBiruBorder
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: widget.ctrl,
                focusNode: widget.focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: kMailTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: kMailTextMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔥 Tombol Send
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _adaTeks
                  ? const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _adaTeks ? null : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              boxShadow: _adaTeks
                  ? [
                      BoxShadow(
                        color: kMailBiru.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _adaTeks && !widget.isSending
                    ? widget.onKirim
                    : null,
                child: Center(
                  child: widget.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          FeatherIcons.send,
                          size: 17,
                          color: _adaTeks
                              ? Colors.white
                              : kMailTextMuted,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}