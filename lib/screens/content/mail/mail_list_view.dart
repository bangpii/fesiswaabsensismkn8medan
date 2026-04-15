import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'mail_models.dart';
import 'mail_helpers.dart';

// ═══════════════════════════════════════════════════════════
// MAIL LIST VIEW — Inbox daftar pesan
// ═══════════════════════════════════════════════════════════

const int _kTampilAwal = 4;

class MailListView extends StatefulWidget {
  final List<MailMessage> pesanTersaring;
  final int jumlahBelumDibaca;
  final int tabIndex;
  final TextEditingController searchCtrl;
  final void Function(int) onTabChanged;
  final void Function(MailMessage) onBukaPesan;
  final void Function(MailMessage) onHapusPesan;

  const MailListView({
    super.key,
    required this.pesanTersaring,
    required this.jumlahBelumDibaca,
    required this.tabIndex,
    required this.searchCtrl,
    required this.onTabChanged,
    required this.onBukaPesan,
    required this.onHapusPesan,
  });

  @override
  State<MailListView> createState() => _MailListViewState();
}

class _MailListViewState extends State<MailListView> {
  bool _tampilSemua = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.pesanTersaring;
    final tampil = (!_tampilSemua && filtered.length > _kTampilAwal)
        ? filtered.take(_kTampilAwal).toList()
        : filtered;
    final adaLebih = filtered.length > _kTampilAwal && !_tampilSemua;

    return Column(
      children: [
        _MailListHeader(
          jumlahBelumDibaca: widget.jumlahBelumDibaca,
          tabIndex: widget.tabIndex,
          searchCtrl: widget.searchCtrl,
          onTabChanged: widget.onTabChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const _MailKosong()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tampil.length + (adaLebih ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, i) {
                    if (i < tampil.length) {
                      return _MailCard(
                        mail: tampil[i],
                        onTap: widget.onBukaPesan,
                        onHapus: widget.onHapusPesan,
                      );
                    }
                    // Tombol tampilkan semua
                    return _TampilSemuaButton(
                      sisaCount: filtered.length - _kTampilAwal,
                      onTap: () => setState(() => _tampilSemua = true),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────
class _MailListHeader extends StatelessWidget {
  final int jumlahBelumDibaca;
  final int tabIndex;
  final TextEditingController searchCtrl;
  final void Function(int) onTabChanged;

  const _MailListHeader({
    required this.jumlahBelumDibaca,
    required this.tabIndex,
    required this.searchCtrl,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
          Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kotak Masuk',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (jumlahBelumDibaca > 0)
            Text(
              '$jumlahBelumDibaca belum dibaca',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
      // Settings/Filter button
      GestureDetector(
        onTap: () {},
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            FeatherIcons.sliders,
            size: 17,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  ),
),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(controller: searchCtrl),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TabBar(
                tabIndex: tabIndex,
                jumlahBelumDibaca: jumlahBelumDibaca,
                onTabChanged: onTabChanged,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 0.5, color: kMailBorder),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: kMailTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Cari pesan...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: kMailTextMuted,
          ),
          prefixIcon: const Icon(
            FeatherIcons.search,
            size: 16,
            color: kMailTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int tabIndex;
  final int jumlahBelumDibaca;
  final void Function(int) onTabChanged;

  const _TabBar({
    required this.tabIndex,
    required this.jumlahBelumDibaca,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Semua', 'Belum Dibaca'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final aktif = i == tabIndex;
        return GestureDetector(
          onTap: () => onTabChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: aktif ? kMailBiru : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: aktif ? kMailBiru : const Color(0xFFD1D5DB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tabs[i],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: aktif ? Colors.white : kMailTextSecondary,
                  ),
                ),
                if (i == 1 && jumlahBelumDibaca > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: aktif
                          ? Colors.white.withOpacity(0.25)
                          : kMailBiru,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$jumlahBelumDibaca',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Mail Card ─────────────────────────────────────────────
class _MailCard extends StatelessWidget {
  final MailMessage mail;
  final void Function(MailMessage) onTap;
  final void Function(MailMessage) onHapus;

  const _MailCard({
    required this.mail,
    required this.onTap,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(mail),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onHapus(mail);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !mail.dibaca ? kMailBiruBorder : kMailBorder,
            width: !mail.dibaca ? 1 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strip kiri unread
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: 108,
              decoration: BoxDecoration(
                color: !mail.dibaca ? kMailBiru : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MailAvatar(inisial: mail.senderInitials, ukuran: 42),
                    const SizedBox(width: 11),
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
                                    fontSize: 13,
                                    fontWeight: !mail.dibaca
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: kMailTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatWaktuSingkat(mail.waktu),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: !mail.dibaca
                                      ? kMailBiru
                                      : kMailTextMuted,
                                  fontWeight: !mail.dibaca
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          MailRoleBadge(label: labelRole(mail.senderRole)),
                          const SizedBox(height: 5),
                          Text(
                            mail.subject,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: !mail.dibaca
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: const Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mail.preview.replaceAll('\n', ' '),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kMailTextMuted,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!mail.dibaca) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: kMailBiru,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tampilkan Semua Button ────────────────────────────────
class _TampilSemuaButton extends StatelessWidget {
  final int sisaCount;
  final VoidCallback onTap;

  const _TampilSemuaButton({
    required this.sisaCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kMailBiruBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: kMailBiru.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.mail, size: 14, color: kMailBiru),
            const SizedBox(width: 8),
            Text(
              'Tampilkan $sisaCount pesan lainnya',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kMailBiru,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(FeatherIcons.chevronDown, size: 13, color: kMailBiru),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class _MailKosong extends StatelessWidget {
  const _MailKosong();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: kMailBiruMuda,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(FeatherIcons.inbox, size: 28, color: kMailBiru),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada pesan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kotak masuk kamu kosong',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kMailTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}