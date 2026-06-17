// lib/screens/content/absensi/absensi_camera_modal.dart
//
// 🔥 ABSENSI CAMERA MODAL — DINAMIS MASUK / PULANG
//
// Alur:
//   1. Saat modal dibuka → start AbsensiRealtimeService
//   2. Dengarkan stream dari AbsensiRealtimeService
//   3. Update _tipe & status text otomatis dari service
//   4. Tampilkan UI sesuai tipe (label, warna, pesan)
//   5. Foto → Compress → Absen (masuk/pulang otomatis sesuai tipe)
//   6. Reverb broadcast realtime, tidak perlu refresh
//
import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/absensi_service.dart';
import '../../../services/absensi_realtime_service.dart';

// ─────────────────────────────────────────────────────────
// TIPE ABSENSI — DIAMBIL OTOMATIS DARI ABSENSIREALTIMESERVICE
// ─────────────────────────────────────────────────────────
enum TipeAbsensi { masuk, pulang }

class AbsensiCameraModal extends StatefulWidget {
  /// Callback setelah absensi berhasil disimpan
  final void Function(Map<String, dynamic> result)? onSimpan;

  const AbsensiCameraModal({
    super.key,
    this.onSimpan,
  });

  @override
  State<AbsensiCameraModal> createState() => _AbsensiCameraModalState();
}

class _AbsensiCameraModalState extends State<AbsensiCameraModal>
    with TickerProviderStateMixin {
  _CameraStep _step = _CameraStep.loading;
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  XFile? _fotoFile;
  String? _errorMsg;

  // ── Dinamis Tipe dari AbsensiRealtimeService ────────────
  TipeAbsensi _tipe = TipeAbsensi.masuk;
  bool _loadingStatus = true;
  String _statusText = 'Mengecek status absensi...';

  // Upload state
  bool _isUploading = false;
  String _uploadStatus = 'Memproses foto...';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _dotsCtrl;

  // 🔥 Stream subscription dari AbsensiRealtimeService
  StreamSubscription<AbsensiRealtimeState>? _realtimeSub;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    // 🔥 STEP 1: Start AbsensiRealtimeService
    AbsensiRealtimeService.start();

    // 🔥 STEP 2: Listen stream dari AbsensiRealtimeService
 _realtimeSub = AbsensiRealtimeService.stream.listen((state) {
  if (!mounted) return;

  // ✅ DEBUG WAJIB
  print("=== REALTIME MODAL ===");
  print("ACTION: ${state.action}");
  print("TEXT: ${state.statusText}");

  setState(() {
    _loadingStatus = false;
    _statusText = state.statusText;

    switch (state.action) {
      case AbsensiAction.masuk:
        _tipe = TipeAbsensi.masuk;
        break;
      case AbsensiAction.pulang:
        _tipe = TipeAbsensi.pulang;
        break;
      case AbsensiAction.none:
        // 🔥 INI MASALAH UTAMA KAMU
        // tambahkan ini 👇
        _tipe = TipeAbsensi.pulang;
        break;
    }
  });
});

    // 🔥 STEP 3: Init kamera setelah setup listener
    WidgetsBinding.instance.addPostFrameCallback((_) => _initKamera());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    _controller?.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // ❌ _loadStatus() DIHAPUS — SEMUA LOGIKA DI ABSENSIREALTIMESERVICE
  // ════════════════════════════════════════════════════════

  // ── Init Kamera ──────────────────────────────────────────
  Future<void> _initKamera({int index = 0}) async {
    setState(() {
      _step = _CameraStep.loading;
      _errorMsg = null;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMsg = 'Tidak ada kamera yang tersedia.';
            _step = _CameraStep.error;
          });
        }
        return;
      }

      final camIndex = index.clamp(0, _cameras.length - 1);
      _currentCameraIndex = camIndex;

      await _controller?.dispose();

      final ctrl = CameraController(
        _cameras[camIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();

      // 🔥 Set zoom minimum = tidak zoom
      final minZoom = await ctrl.getMinZoomLevel();
      await ctrl.setZoomLevel(minZoom);

      if (!mounted) return;

      setState(() {
        _controller = ctrl;
        _step = _CameraStep.viewfinder;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg =
              'Gagal membuka kamera.\nPastikan izin kamera sudah diberikan.';
          _step = _CameraStep.error;
        });
      }
    }
  }

  Future<void> _switchKamera() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();
    await _initKamera(index: (_currentCameraIndex + 1) % _cameras.length);
  }

  Future<void> _ambilFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;
    HapticFeedback.mediumImpact();
    try {
      final file = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _fotoFile = file;
          _step = _CameraStep.preview;
        });
      }
    } catch (_) {}
  }

  void _reload() {
    HapticFeedback.lightImpact();
    setState(() {
      _fotoFile = null;
      _step = _CameraStep.viewfinder;
    });
  }

  // ── SIMPAN: Compress → Absen ─────────────────────────────
  Future<void> _simpan() async {
    if (_fotoFile == null || _isUploading) return;
    HapticFeedback.heavyImpact();

    // Ambil GPS
    double lat = 0.0;
    double lng = 0.0;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
    } catch (_) {
      // GPS gagal → koordinat 0,0 → backend akan tolak karena di luar area
    }

    setState(() {
      _isUploading  = true;
      _uploadStatus = 'Mengompresi foto...';
    });

    try {
      // ── STEP 1: Compress ──────────────────────────────
      final compressResult =
          await AbsensiService.compressPhoto(_fotoFile!.path);

      if (compressResult['success'] != true) {
        _showError(compressResult['message'] ?? 'Gagal mengompres foto');
        return;
      }

      final tempPath =
          compressResult['data']?['temp_path']?.toString() ?? '';
      if (tempPath.isEmpty) {
        _showError('Path foto tidak valid dari server');
        return;
      }

      // ── STEP 2: Absen ─────────────────────────────────
      setState(() => _uploadStatus = 'Menyimpan absensi...');

      final Map<String, dynamic> absenResult;

      // 🔥 DINAMIS: Masuk atau Pulang berdasarkan _tipe dari service
      if (_tipe == TipeAbsensi.masuk) {
        absenResult = await AbsensiService.absenMasukCamera(
          tempPath  : tempPath,
          lat       : lat,
          lng       : lng,
          keterangan: 'Absen via Kamera',
        );
      } else {
        absenResult = await AbsensiService.absenPulangCamera(
          tempPath: tempPath,
          lat     : lat,
          lng     : lng,
        );
      }

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (absenResult['success'] == true) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        widget.onSimpan?.call(absenResult);
      } else {
        _showError(absenResult['message'] ?? 'Gagal menyimpan absensi');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Terjadi kesalahan: $e');
      }
    }
  }

  void _showError(String pesan) {
    if (!mounted) return;
    setState(() => _isUploading = false);
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'Gagal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: Text(
          pesan,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔥 Loading status absensi dari AbsensiRealtimeService
    if (_loadingStatus) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1D4ED8),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(size),
              ),

              // Close
              if (!_isUploading)
                Positioned(
                  top: 12,
                  right: 16,
                  child: _BtnIconRound(
                    ikon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),

              // Switch kamera
              if (_step == _CameraStep.viewfinder &&
                  _cameras.length > 1 &&
                  !_isUploading)
                Positioned(
                  top: 12,
                  left: 16,
                  child: _BtnIconRound(
                    ikon: Icons.flip_camera_ios_rounded,
                    onTap: _switchKamera,
                  ),
                ),

              // 🔥 Label tipe absensi — DINAMIS dari service
              if (_step == _CameraStep.viewfinder && !_isUploading)
                Positioned(
                  bottom: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tipe == TipeAbsensi.masuk
                            ? const Color(0xFF1D4ED8).withOpacity(0.88)
                            : const Color(0xFF1D4ED8).withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tipe == TipeAbsensi.masuk
                                ? Icons.camera_alt_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _tipe == TipeAbsensi.masuk
                                ? 'Absen Masuk'
                                : 'Absen Pulang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Upload overlay
              if (_isUploading) _buildUploadOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(Size size) {
    switch (_step) {
      case _CameraStep.loading:
        return _buildLoading();
      case _CameraStep.viewfinder:
        return _buildViewfinder(size);
      case _CameraStep.preview:
        return _buildPreview(size);
      case _CameraStep.error:
        return _buildError();
    }
  }

  // ── Upload overlay ───────────────────────────────────────
  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: const Color(0xFF3B82F6),
                  backgroundColor:
                      const Color(0xFF3B82F6).withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _dotsCtrl,
                builder: (_, __) {
                  final dots =
                      '.' * ((_dotsCtrl.value * 3).floor() % 4);
                  return Text(
                    '$_uploadStatus$dots',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8).withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Color(0xFF1D4ED8), size: 34),
          ),
          const SizedBox(height: 20),
          const Text('Membuka Kamera...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text('Mohon izinkan akses kamera',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 24),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Color(0xFF1D4ED8), strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_rounded,
                  color: Color(0xFFDC2626), size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMsg ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _initKamera(index: _currentCameraIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(14)),
                child: const Text('Coba Lagi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Viewfinder ───────────────────────────────────────────
  Widget _buildViewfinder(Size size) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
          key: ValueKey('vf-init'),
          child: CircularProgressIndicator(color: Color(0xFF1D4ED8)));
    }

    return Stack(
      key: const ValueKey('viewfinder'),
      fit: StackFit.expand,
      children: [
        // 🔥 Tidak pakai FittedBox cover → tidak zoom
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: ctrl.value.aspectRatio,
              child: CameraPreview(ctrl),
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.35),
              ],
            ),
          ),
        ),

        // Corner guide
        Center(
          child: SizedBox(
            width: size.width * 0.72,
            height: size.width * 0.72,
            child: CustomPaint(
              painter: _CornerGuidePainter(
                  warna: _tipe == TipeAbsensi.masuk
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF1D4ED8)),
            ),
          ),
        ),

        // 🔥 Label kamera — DINAMIS
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _tipe == TipeAbsensi.masuk
                    ? const Color(0xFF1D4ED8).withOpacity(0.75)
                    : const Color(0xFF1D4ED8).withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _tipe == TipeAbsensi.masuk
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFFA78BFA),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    _cameras.isNotEmpty &&
                            _cameras[_currentCameraIndex]
                                    .lensDirection ==
                                CameraLensDirection.front
                        ? 'Kamera Depan Aktif'
                        : 'Kamera Belakang Aktif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 🔥 Petunjuk — DINAMIS dari service
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: size.width * 0.72 + 16),
            child: Text(
              _tipe == TipeAbsensi.masuk
                  ? 'Posisikan wajah dalam bingkai'
                  : 'Posisikan wajah dalam bingkai',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  fontFamily: 'Poppins'),
            ),
          ),
        ),

        // Tombol ambil foto
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) =>
                  Transform.scale(scale: _pulseAnim.value, child: child),
              child: GestureDetector(
                onTap: _ambilFoto,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _tipe == TipeAbsensi.masuk
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFA78BFA),
                        width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: BoxDecoration(
                          color: _tipe == TipeAbsensi.masuk
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF1D4ED8),
                          shape: BoxShape.circle),
                      child: Icon(
                        _tipe == TipeAbsensi.masuk
                            ? Icons.camera_alt_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Preview foto ─────────────────────────────────────────
  Widget _buildPreview(Size size) {
    return Stack(
      key: const ValueKey('preview'),
      fit: StackFit.expand,
      children: [
        _fotoFile != null
            ? Transform(
                alignment: Alignment.center,
                transform: _cameras.isNotEmpty &&
                        _cameras[_currentCameraIndex].lensDirection ==
                            CameraLensDirection.front
                    ? Matrix4.rotationY(3.14159)
                    : Matrix4.identity(),
                child: Image.file(
                  File(_fotoFile!.path),
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF111827),
                    child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.white.withOpacity(0.15),
                            size: 80)),
                  ),
                ),
              )
            : Container(color: const Color(0xFF111827)),

        // Gradient bawah
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.88),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    ikon: Icons.replay_rounded,
                    label: 'Foto Ulang',
                    warna: Colors.white.withOpacity(0.12),
                    warnaText: Colors.white,
                    onTap: _reload,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ActionBtn(
                    ikon: Icons.check_rounded,
                    label: _tipe == TipeAbsensi.masuk
                        ? 'Simpan Masuk'
                        : 'Simpan Pulang',
                    warna: _tipe == TipeAbsensi.masuk
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF1D4ED8),
                    warnaText: Colors.white,
                    onTap: _simpan,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔥 Label sukses — DINAMIS
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _tipe == TipeAbsensi.masuk
                    ? const Color(0xFF16A34A).withOpacity(0.88)
                    : const Color(0xFF16A34A).withOpacity(0.88),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tipe == TipeAbsensi.masuk
                        ? Icons.check_circle_rounded
                        : Icons.logout_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _tipe == TipeAbsensi.masuk
                        ? 'Foto Berhasil Diambil'
                        : 'Foto Pulang Berhasil',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Enum Step ─────────────────────────────────────────────
enum _CameraStep { loading, viewfinder, preview, error }

class _BtnIconRound extends StatelessWidget {
  final IconData ikon;
  final VoidCallback onTap;
  const _BtnIconRound({required this.ikon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.52),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Icon(ikon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData ikon;
  final String label;
  final Color warna;
  final Color warnaText;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.ikon,
    required this.label,
    required this.warna,
    required this.warnaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withOpacity(0.13), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, color: warnaText, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: warnaText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  final Color warna;
  const _CornerGuidePainter({required this.warna});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = warna
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(0, len), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
