import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'mail_models.dart';
import 'mail_helpers.dart';

// ═══════════════════════════════════════════════════════════
// MAIL LIST VIEW — Inbox daftar percakapan izin (realtime)
// ═══════════════════════════════════════════════════════════

class MailListView extends StatefulWidget {
  final List<IzinModel> izins;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(IzinModel) onBukaPesan;
  final void Function(IzinModel) onHapusPesan;

  const MailListView({
    super.key,
    required this.izins,
    required this.isLoading,
    required this.onRefresh,
    required this.onBukaPesan,
    required this.onHapusPesan,
  });

  @override
  State<MailListView> createState() => _MailListViewState();
}

class _MailListViewState extends State<MailListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _tabIndex = 0; // 0=semua, 1=unread, 2=disetujui

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<IzinModel> get _filtered {
    List<IzinModel> hasil = widget.izins;

    if (_tabIndex == 1) {
      hasil = hasil.where((z) => z.unreadCount > 0).toList();
    } else if (_tabIndex == 2) {
      hasil = hasil.where((z) => z.status == IzinStatus.disetujui).toList();
    }

    if (_query.isNotEmpty) {
      hasil = hasil.where((z) =>
          z.keterangan.toLowerCase().contains(_query) ||
          z.jenisLabel.toLowerCase().contains(_query) ||
          z.statusLabel.toLowerCase().contains(_query) ||
          (z.lastPesan?.pesan.toLowerCase().contains(_query) ?? false)).toList();
    }

    return hasil;
  }

  int get _totalUnread => widget.izins.fold(0, (sum, z) => sum + z.unreadCount);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ListHeader(
          totalUnread: _totalUnread,
          tabIndex: _tabIndex,
          searchCtrl: _searchCtrl,
          onTabChanged: (i) => setState(() => _tabIndex = i),
          onRefresh: widget.onRefresh,
        ),
        Expanded(
          child: widget.isLoading
              ? const _LoadingShimmer()
              : _filtered.isEmpty
                  ? _EmptyState(query: _query)
                  : RefreshIndicator(
                      onRefresh: () async => widget.onRefresh(),
                      color: kMailBiru,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _IzinCard(
                          izin: _filtered[i],
                          onTap: widget.onBukaPesan,
                          onLongPress: widget.onHapusPesan,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────
class _ListHeader extends StatelessWidget {
  final int totalUnread;
  final int tabIndex;
  final TextEditingController searchCtrl;
  final void Function(int) onTabChanged;
  final VoidCallback onRefresh;

  const _ListHeader({
    required this.totalUnread,
    required this.tabIndex,
    required this.searchCtrl,
    required this.onTabChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kMailSurface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mail Izin',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kMailTextPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        if (totalUnread > 0)
                          Text(
                            '$totalUnread pesan belum dibaca',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kMailBiru,
                            ),
                          )
                        else
                          Text(
                            'Semua pesan sudah dibaca',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kMailTextMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kMailBiruMuda,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kMailBiruBorder, width: 0.8),
                      ),
                      child: const Icon(
                        FeatherIcons.refreshCw,
                        size: 16,
                        color: kMailBiru,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _SearchBox(controller: searchCtrl),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _Tabs(
                tabIndex: tabIndex,
                unreadCount: totalUnread,
                onChanged: onTabChanged,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
          ],
        ),
      ),
    );
  }
}

// ── Search Box ────────────────────────────────────────────
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 13, color: kMailTextPrimary),
        decoration: InputDecoration(
          hintText: 'Cari percakapan izin...',
          hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: kMailTextMuted),
          prefixIcon: const Icon(FeatherIcons.search, size: 15, color: kMailTextMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  final int tabIndex;
  final int unreadCount;
  final void Function(int) onChanged;

  const _Tabs({
    required this.tabIndex,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Semua', 'Belum Baca', 'Disetujui'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final aktif = i == tabIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? kMailBiru : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aktif ? kMailBiru : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: aktif ? Colors.white : kMailTextSecondary,
                    ),
                  ),
                  if (i == 1 && unreadCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: aktif ? Colors.white.withOpacity(0.28) : kMailBiru,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Izin Card ─────────────────────────────────────────────
class _IzinCard extends StatelessWidget {
  final IzinModel izin;
  final void Function(IzinModel) onTap;
  final void Function(IzinModel) onLongPress;

  const _IzinCard({
    required this.izin,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unread = izin.unreadCount > 0;
    final lastP = izin.lastPesan;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(izin);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress(izin);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? kMailBiruBorder : const Color(0xFFE2E8F0),
            width: unread ? 1 : 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: unread
                  ? kMailBiru.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strip kiri unread
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 3.5,
              height: 88,
              decoration: BoxDecoration(
                color: unread ? kMailBiru : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar dengan status dot
                    Stack(
                      children: [
                        MailAvatar(
                          inisial: izin.namaLengkap.isNotEmpty
                              ? izin.namaLengkap[0].toUpperCase()
                              : 'S',
                          ukuran: 42,
                          // warna: jenisColor(izin.jenisIzin),
                        ),
                        if (izin.status == IzinStatus.disetujui)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: kMailSuccess,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.check, size: 8, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Konten
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: nama + waktu
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${izin.jenisLabel} ( ${formatTanggalIzin(izin.tanggalIzin)} )',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                    color: kMailTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (lastP != null)
                                Text(
                                  formatWaktuSingkat(lastP.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: unread ? kMailBiru : kMailTextMuted,
                                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Row 2: badge status + jenis
                          Row(
                            children: [
                              IzinStatusBadge(status: izin.status, compact: true),
                              const SizedBox(width: 5),
                              IzinJenisBadge(jenis: izin.jenisIzin),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Row 3: preview pesan terakhir + unread dot
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastP != null
                                      ? '${lastP.dariSiswa ? "Kamu: " : "Admin: "}${lastP.pesan}'
                                      : izin.keterangan,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: unread ? kMailTextPrimary : kMailTextMuted,
                                    fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: kMailBiru,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${izin.unreadCount}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
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

// ── Loading Shimmer ───────────────────────────────────────
class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer();

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(_anim.value + 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFE2E8F0),
                        const Color(0xFFF1F5F9),
                        _anim.value,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFE2E8F0),
                            const Color(0xFFF1F5F9),
                            _anim.value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFE2E8F0),
                            const Color(0xFFF1F5F9),
                            _anim.value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFE2E8F0),
                            const Color(0xFFF1F5F9),
                            _anim.value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kMailBiruMuda, Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(FeatherIcons.inbox, size: 30, color: kMailBiru),
          ),
          const SizedBox(height: 14),
          Text(
            query.isNotEmpty ? 'Tidak ditemukan' : 'Belum ada pesan',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kMailTextPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            query.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Pesan dari admin akan muncul di sini',
            style: GoogleFonts.poppins(fontSize: 12, color: kMailTextMuted),
          ),
        ],
      ),
    );
  }
}