import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../config/app_colors.dart';
import 'profile_models.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE HEADER CARD
// Avatar klik → full-screen photo viewer dengan blur background
// Foto: pakai network image kalau ada, fallback ke inisial (1 huruf)
// 🆕 Modal Biodata Lengkap (dipanggil dari tombol "mata" di TopBar)
// ═══════════════════════════════════════════════════════════

class ProfileHeaderCard extends StatelessWidget {
  final DataSiswa siswa;

  const ProfileHeaderCard({super.key, required this.siswa});

  void _bukaFotoViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque           : false,
        barrierDismissible: true,
        barrierLabel     : 'Tutup',
        barrierColor     : Colors.transparent,
        pageBuilder      : (_, __, ___) =>
            _FotoViewerOverlay(siswa: siswa),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────
          GestureDetector(
            onTap: () => _bukaFotoViewer(context),
            child: _AvatarWidget(siswa: siswa, size: 78),
          ),

          const SizedBox(width: 18),

          // ── Info ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa.namaLengkap,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  ikon : FeatherIcons.creditCard,
                  label: 'NISN',
                  nilai: siswa.nisn,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  ikon : siswa.jenisKelamin == JenisKelamin.lakiLaki
                      ? FeatherIcons.user
                      : FeatherIcons.heart,
                  label: 'Kelamin',
                  nilai: siswa.labelKelamin,
                ),
                if (siswa.agama != null && siswa.agama!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _InfoRow(
                    ikon : FeatherIcons.bookOpen,
                    label: 'Agama',
                    nilai: siswa.agama!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// AVATAR WIDGET
// Tampilkan foto network kalau ada, fallback ke inisial (1 huruf)
// ─────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final DataSiswa siswa;
  final double size;

  const _AvatarWidget({required this.siswa, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasFoto = siswa.fotoUrl != null && siswa.fotoUrl!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: hasFoto
                ? Image.network(
                    siswa.fotoUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInisial(size),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      );
                    },
                  )
                : _buildInisial(size),
          ),
        ),
        // Tap indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              FeatherIcons.maximize2,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInisial(double size) {
    return Container(
      color: AppColors.accent.withOpacity(0.1),
      child: Center(
        child: Text(
          siswa.inisial,
          style: GoogleFonts.poppins(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info Row item
// ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const _InfoRow({
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(ikon, size: 13, color: AppColors.accent),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        Text('·', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🆕 BIODATA MODAL (dipanggil dari ProfileScreen via tombol mata
// di TopBar, di samping kiri tombol logout).
// Anti-overflow: pakai SingleChildScrollView + constraint maxHeight,
// jadi aman di semua ukuran HP (Oppo, Samsung, iPhone, Xiaomi, dll)
// dan saat keyboard/notch muncul.
// ═══════════════════════════════════════════════════════════

void bukaBiodataModal(BuildContext context, DataSiswa siswa) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BiodataModal(siswa: siswa),
  );
}

class _BiodataModal extends StatelessWidget {
  final DataSiswa siswa;
  const _BiodataModal({required this.siswa});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset   = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      // Batas tinggi maksimal agar tidak overflow di HP layar pendek
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),

          // Header: avatar mini + nama + tutup
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
            child: Row(
              children: [
                _AvatarWidget(siswa: siswa, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa.namaLengkap,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Biodata Lengkap',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FeatherIcons.x,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.border.withOpacity(0.4),
          ),

          // ── List Biodata (scrollable, anti-overflow) ────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BiodataItem(
                    ikon : FeatherIcons.user,
                    label: 'Nama Lengkap',
                    nilai: siswa.namaLengkap,
                  ),
                  _BiodataItem(
                    ikon : FeatherIcons.creditCard,
                    label: 'NISN',
                    nilai: siswa.nisn,
                  ),
                  _BiodataItem(
                    ikon : FeatherIcons.hash,
                    label: 'NIS',
                    nilai: siswa.nis,
                  ),
                  _BiodataItem(
                    ikon : siswa.jenisKelamin == JenisKelamin.lakiLaki
                        ? FeatherIcons.user
                        : FeatherIcons.heart,
                    label: 'Jenis Kelamin',
                    nilai: siswa.labelKelamin,
                  ),
                  if (siswa.tingkat != null && siswa.tingkat!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.layers,
                      label: 'Tingkat',
                      nilai: siswa.tingkat!,
                    ),
                  _BiodataItem(
                    ikon : FeatherIcons.bookOpen,
                    label: 'Kelas',
                    nilai: siswa.kelas,
                  ),
                  _BiodataItem(
                    ikon : FeatherIcons.cpu,
                    label: 'Jurusan',
                    nilai: siswa.jurusan,
                  ),
                  if (siswa.agama != null && siswa.agama!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.star,
                      label: 'Agama',
                      nilai: siswa.agama!,
                    ),
                  if (siswa.tempatLahir != null &&
                      siswa.tempatLahir!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.mapPin,
                      label: 'Tempat Lahir',
                      nilai: siswa.tempatLahir!,
                    ),
                  if (siswa.tanggalLahir != null &&
                      siswa.tanggalLahir!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.calendar,
                      label: 'Tanggal Lahir',
                      nilai: siswa.tanggalLahir!,
                    ),
                  if (siswa.email != null && siswa.email!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.mail,
                      label: 'Email',
                      nilai: siswa.email!,
                    ),
                  if (siswa.namaOrangtua != null &&
                      siswa.namaOrangtua!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.users,
                      label: 'Nama Orang Tua',
                      nilai: siswa.namaOrangtua!,
                    ),
                  if (siswa.noHpOrangtua != null &&
                      siswa.noHpOrangtua!.isNotEmpty)
                    _BiodataItem(
                      ikon : FeatherIcons.phone,
                      label: 'No. HP Orang Tua',
                      nilai: siswa.noHpOrangtua!,
                      isLast: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Biodata Item (baris dalam modal, support wrap untuk teks panjang)
// ─────────────────────────────────────────────────────────

class _BiodataItem extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;
  final bool isLast;

  const _BiodataItem({
    required this.ikon,
    required this.label,
    required this.nilai,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(ikon, size: 14, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nilai,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.border.withOpacity(0.4),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FOTO VIEWER OVERLAY
// Fullscreen, blur background, zoomable (foto atau inisial)
// ═══════════════════════════════════════════════════════════

class _FotoViewerOverlay extends StatefulWidget {
  final DataSiswa siswa;
  const _FotoViewerOverlay({required this.siswa});

  @override
  State<_FotoViewerOverlay> createState() => _FotoViewerOverlayState();
}

class _FotoViewerOverlayState extends State<_FotoViewerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scaleAnim;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _scaleAnim = CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _tutup() {
    _ctrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFoto = widget.siswa.fotoUrl != null &&
        widget.siswa.fotoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _tutup,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Blur Background
              FadeTransition(
                opacity: _ctrl,
                child: Container(
                    color: Colors.black.withOpacity(0.75)),
              ),

              // Foto Besar
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: () {}, // cegah tap di foto menutup
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: InteractiveViewer(
                              transformationController: _transformCtrl,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: hasFoto
                                  ? Image.network(
                                      widget.siswa.fotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildInisialLarge(),
                                    )
                                  : _buildInisialLarge(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          widget.siswa.namaLengkap,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.siswa.kelas,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tombol Close
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: GestureDetector(
                  onTap: _tutup,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      FeatherIcons.x,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInisialLarge() {
    return Container(
      color: const Color(0xFF1D4ED8).withOpacity(0.15),
      child: Center(
        child: Text(
          widget.siswa.inisial,
          style: GoogleFonts.poppins(
            fontSize: 88,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}