// lib/screens/content/absensi/absensi_barcode_modal.dart
//
// 🔥 ABSENSI BARCODE MODAL — DINAMIS MASUK / PULANG (FIXED — REAL SCAN)
//
// 🔧 PERBAIKAN UTAMA:
//   Sebelumnya tombol "scan" hanya mengirim _barcodeValue (barcode milik
//   akun yang login dari /barcode/status) TANPA pernah membaca kamera.
//   Sekarang pakai mobile_scanner untuk benar-benar mendecode QR yang
//   ada di depan kamera secara real-time, lalu HASIL DECODE itulah yang
//   dikirim ke backend — bukan barcode milik akun sendiri.
//
//   Backend (AbsensiController::scanBarcodeMasuk/scanBarcodePulang) juga
//   sudah ditambahkan validasi kepemilikan: barcode yang di-scan WAJIB
//   milik akun yang sedang login, kalau tidak → 403 ditolak.
//
// Logika Barcode:
//   QR berisi URL: "https://domain/redirect?code=SMKN8-{nisn}-{random}"
//   → Scan DALAM app  : extractBarcodeCode() → ambil ?code= → kirim ke backend
//   → Scan LUAR app   : browser buka URL → redirect ke Maps (handled backend)
//
// ═══ DINAMIS ═══════════════════════════════════════════════
// Saat modal dibuka → start AbsensiRealtimeService
// Listen stream → update tipe & status text otomatis
// ═══════════════════════════════════════════════════════════
//
// Tombol Barcode Siswa:
//   Belum punya → "Generate Barcode" (POST /barcode/generate)
//   Sudah punya → "Download Barcode" (GET /barcode/download → tampil QR)
//
// Alur Absensi (BARU):
//   1. Buka modal → start AbsensiRealtimeService → listen stream
//   2. Update tipe (masuk/pulang) dari stream service
//   3. Minta GPS
//   4. Kamera scanner aktif (mobile_scanner)
//   5. QR terdeteksi otomatis di depan kamera → onDetect dipanggil
//   6. Validasi format SMKN8-... → extract code dari hasil DECODE REAL
//   7. Kirim ke backend sesuai tipe (scan-barcode-masuk / scan-barcode-pulang)
//   8. Backend cross-check: barcode harus milik akun yang login
//   9. Berhasil → tampilkan sukses card. Gagal (barcode bukan milik dia
//      / tidak valid / dll) → tampilkan pesan gagal, TIDAK auto-retry.
//
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../services/absensi_service.dart';
import '../../../services/absensi_realtime_service.dart';

// ─────────────────────────────────────────────────────────
// TIPE ABSENSI — DIAMBIL OTOMATIS DARI ABSENSIREALTIMESERVICE
// ─────────────────────────────────────────────────────────
enum TipeAbsensiBarcode { masuk, pulang }

class AbsensiBarcodesModal extends StatefulWidget {
  final void Function(Map<String, dynamic> result)? onAbsensi;

  const AbsensiBarcodesModal({
    super.key,
    this.onAbsensi,
  });

  @override
  State<AbsensiBarcodesModal> createState() =>
      _AbsensiBarcodesModalState();
}

class _AbsensiBarcodesModalState extends State<AbsensiBarcodesModal>
    with TickerProviderStateMixin {
  // ── 🔥 Scanner kamera REAL (mobile_scanner) ───────────────
  MobileScannerController? _scannerController;
  bool _scannerReady = false;
  String? _scannerError;

  // ── Dinamis Tipe dari AbsensiRealtimeService ─────────────
  TipeAbsensiBarcode _tipe = TipeAbsensiBarcode.masuk;
  bool _loadingStatus = true;
  String _statusText = 'Mengecek status absensi...';

  // ── Barcode siswa (HANYA untuk fitur Generate/Download) ──
  bool _loadingBarcode   = true;
  bool _hasBarcode       = false;
  String? _barcodeValue;
  String? _barcodeImageUrl;

  // ── Scan state ───────────────────────────────────────────
  bool _scanSuccess    = false;
  bool _isProcessing   = false;
  String? _scanMessage;
  bool _scanLocked     = false; // 🔥 cegah double-trigger saat sedang proses

  // ── GPS ──────────────────────────────────────────────────
  double _lat = 0.0;
  double _lng = 0.0;

  // ── Animasi ───────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
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

      setState(() {
        _loadingStatus = false;
        _statusText = state.statusText;

        switch (state.action) {
          case AbsensiAction.masuk:
            _tipe = TipeAbsensiBarcode.masuk;
            break;
          case AbsensiAction.pulang:
            _tipe = TipeAbsensiBarcode.pulang;
            break;
          case AbsensiAction.none:
            _tipe = TipeAbsensiBarcode.pulang;
            break;
        }
      });
    });

    // 🔥 STEP 3: Init scanner & barcode setelah setup listener
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initScanner();
      await _loadBarcodeStatus();
      await _loadGps();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    _scannerController?.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  // ── 🔥 Init scanner kamera REAL ───────────────────────────
  Future<void> _initScanner() async {
    setState(() {
      _scannerReady = false;
      _scannerError = null;
    });

    try {
      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );

      if (mounted) {
        setState(() => _scannerReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _scannerError =
              'Gagal membuka kamera.\nIzinkan akses kamera terlebih dahulu.';
        });
      }
    }
  }

  // ── Load barcode status dari backend (HANYA utk Generate/Download) ──
  Future<void> _loadBarcodeStatus() async {
    setState(() => _loadingBarcode = true);
    try {
      final result = await AbsensiService.barcodeStatus();
      if (!mounted) return;

      final hasBarcode = result['has_barcode'] == true;
      final data       = result['data'];

      setState(() {
        _loadingBarcode  = false;
        _hasBarcode      = hasBarcode;
        _barcodeValue    = data?['barcode_value']?.toString();
        _barcodeImageUrl = data?['qr_image_url']?.toString();
      });
    } catch (_) {
      if (mounted) setState(() => _loadingBarcode = false);
    }
  }

  // ── Ambil GPS ─────────────────────────────────────────────
  Future<void> _loadGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

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
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
      }
    } catch (_) {}
  }

  // ── Generate barcode ──────────────────────────────────────
  Future<void> _generateBarcode() async {
    HapticFeedback.mediumImpact();
    _showLoadingDialog('Membuat barcode...');

    final result = await AbsensiService.barcodeGenerate();

    if (!mounted) return;
    Navigator.of(context).pop(); // tutup loading dialog

    if (result['success'] == true) {
      final data = result['data'];
      HapticFeedback.heavyImpact();
      setState(() {
        _hasBarcode      = true;
        _barcodeValue    = data?['barcode_value']?.toString();
        _barcodeImageUrl = data?['qr_image_url']?.toString();
      });
      _showBarcodeDialog();
    } else {
      if (result['data'] != null) {
        final data = result['data'];
        setState(() {
          _hasBarcode      = true;
          _barcodeValue    = data['barcode_value']?.toString();
          _barcodeImageUrl = data['qr_image_url']?.toString();
        });
        _showBarcodeDialog();
      } else {
        _showErrorSnack(result['message'] ?? 'Gagal membuat barcode');
      }
    }
  }

  // ── Download barcode ──────────────────────────────────────
  Future<void> _downloadBarcode() async {
    HapticFeedback.lightImpact();

    if (_barcodeImageUrl != null && _barcodeValue != null) {
      _showBarcodeDialog();
      return;
    }

    _showLoadingDialog('Mengambil barcode...');
    final result = await AbsensiService.barcodeDownload();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _barcodeValue    = data?['barcode_value']?.toString();
        _barcodeImageUrl = data?['qr_image_url']?.toString();
      });
      _showBarcodeDialog();
    } else {
      _showErrorSnack(result['message'] ?? 'Barcode tidak ditemukan');
    }
  }

  // 🔥 Save barcode ke galeri
  Future<void> _saveBarcodeToGallery() async {
    if (_barcodeImageUrl == null) return;

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted && !status.isLimited) {
        _showErrorSnack('Izin penyimpanan diperlukan untuk menyimpan barcode');
        return;
      }

      _showLoadingDialog('Menyimpan ke galeri...');

      final response = await http.get(Uri.parse(_barcodeImageUrl!));

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode != 200) {
        _showErrorSnack('Gagal mengunduh barcode dari server');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'barcode_absensi_${_barcodeValue ?? "siswa"}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      final result = await GallerySaver.saveImage(
        tempFile.path,
        albumName: 'Absensi SMKN 8',
      );

      await tempFile.delete();

      if (result == true) {
        _showSuccessSnack('Barcode berhasil disimpan ke galeri ✅');
      } else {
        _showErrorSnack('Gagal menyimpan barcode ke galeri');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnack('Terjadi kesalahan: $e');
    }
  }

  // ── Dialog loading sementara ──────────────────────────────
  void _showLoadingDialog(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 16),
            Text(pesan,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  // ── Dialog tampilkan barcode QR (milik sendiri) ───────────
  void _showBarcodeDialog() {
    if (_barcodeImageUrl == null) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF1D4ED8).withOpacity(0.3),
                width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Barcode Absensi Saya',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tunjukkan ke scanner absensi di sekolah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _barcodeImageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D4ED8)),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.qr_code_2_rounded,
                          size: 80, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_barcodeValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF1D4ED8).withOpacity(0.2)),
                  ),
                  child: Text(
                    _barcodeValue!,
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika di-scan dari kamera lain, akan redirect ke lokasi sekolah di Maps',
                        style: TextStyle(
                          color: Colors.amber.withOpacity(0.85),
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _saveBarcodeToGallery,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded,
                          color: Color(0xFF4ADE80), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Simpan ke Galeri',
                        style: TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Tutup',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔥🔥🔥 INTI PERBAIKAN — HANDLER HASIL DECODE QR REAL 🔥🔥🔥
  // Dipanggil otomatis oleh MobileScanner setiap kali ada QR
  // terdeteksi di depan kamera. INI yang dikirim ke backend,
  // BUKAN _barcodeValue milik akun sendiri.
  // ════════════════════════════════════════════════════════
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _scanSuccess || _scanLocked) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    // 🔒 lock supaya tidak ke-trigger berkali-kali selagi 1 frame
    // masih mengandung QR yang sama
    _scanLocked = true;

    HapticFeedback.heavyImpact();

    setState(() {
      _isProcessing = true;
      _scanMessage  = null;
    });

    // ── Extract & validasi format dari HASIL DECODE KAMERA ───
    final String? extractedCode =
        AbsensiService.extractBarcodeCode(rawValue);

    if (extractedCode == null) {
      setState(() {
        _isProcessing = false;
        _scanMessage  = 'QR yang di-scan bukan barcode absensi yang valid ❌';
      });
      _unlockAfterDelay();
      return;
    }

    // ── Kirim ke backend sesuai tipe (masuk/pulang) ──────────
    // Backend akan memvalidasi:
    //   1. Apakah barcode_value ini terdaftar di database
    //   2. Apakah barcode ini MILIK akun yang sedang login
    // Kalau salah satu gagal → response success:false dengan
    // pesan yang jelas, dan kita TAMPILKAN APA ADANYA ke user.
    Map<String, dynamic> result;
    if (_tipe == TipeAbsensiBarcode.masuk) {
      result = await AbsensiService.absenMasukBarcode(
        barcodeValue: extractedCode,
        lat          : _lat,
        lng          : _lng,
      );
    } else {
      result = await AbsensiService.absenPulangBarcode(
        barcodeValue: extractedCode,
        lat          : _lat,
        lng          : _lng,
      );
    }

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      HapticFeedback.heavyImpact();
      // hentikan scanner biar tidak terus mendeteksi
      _scannerController?.stop();
      setState(() {
        _scanSuccess = true;
        _scanMessage = result['message'] ?? 'Absen berhasil ✅';
      });
    } else {
      // 🔥 GAGAL — termasuk kasus "barcode bukan milik Anda"
      setState(() {
        _scanMessage = result['message'] ?? 'Gagal melakukan absensi';
      });
      _unlockAfterDelay();
    }
  }

  // Beri jeda sebelum mengizinkan deteksi berikutnya, supaya
  // user sempat membaca pesan gagal & tidak langsung spam scan.
  void _unlockAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _scanLocked = false;
      }
    });
  }

  void _showErrorSnack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(pesan,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(pesan,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            fit: StackFit.expand,
            children: [
              // ── 🔥 Kamera scanner REAL ─────────────────
              if (_scannerReady &&
                  _scannerController != null &&
                  !_scanSuccess)
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onBarcodeDetected,
                      errorBuilder: (context, error, child) {
                        return Container(
                          color: const Color(0xFF040D1A),
                          child: Center(
                            child: Text(
                              'Gagal mengakses kamera.\nIzinkan akses kamera terlebih dahulu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(color: const Color(0xFF040D1A)),

              // Overlay gelap
              Container(color: Colors.black.withOpacity(0.38)),

              // ── Konten tengah ──────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label tipe absensi — DINAMIS dari service
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            _tipe == TipeAbsensiBarcode.masuk
                                ? 'Scan Barcode Masuk'
                                : 'Scan Barcode Pulang',
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

                    const SizedBox(height: 14),

                    // Panduan / pesan error
                    AnimatedOpacity(
                      opacity: _scanSuccess ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _scannerError != null
                            ? _scannerError!
                            : _scanMessage != null
                                ? _scanMessage!
                                : _isProcessing
                                    ? 'Memproses absensi...'
                                    : 'Arahkan kamera ke barcode absensi Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _scanMessage != null &&
                                  !_scanSuccess &&
                                  !_isProcessing
                              ? const Color(0xFFDC2626)
                              : Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Viewfinder
                    SizedBox(
                      width: size.width * 0.72,
                      height: size.width * 0.72,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(size.width * 0.72, size.width * 0.72),
                            painter: _CornerGuidePainter(
                              warna: _scanSuccess
                                  ? const Color(0xFF16A34A)
                                  : _isProcessing
                                      ? Colors.amber
                                      : (_scanMessage != null
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF1D4ED8)),
                            ),
                          ),

                          if (_isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _dotsCtrl,
                                  builder: (_, __) {
                                    final dots =
                                        '.' * ((_dotsCtrl.value * 3).floor() % 4);
                                    return Text(
                                      'Memproses$dots',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                          if (_scanSuccess)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A)
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Color(0xFF4ADE80), size: 52),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_scanSuccess) _buildSuksesCard(),
                    if (!_scanSuccess && !_isProcessing && _scanMessage != null)
                      _buildGagalCard(),
                  ],
                ),
              ),

              // ── Close ──────────────────────────────────
              Positioned(
                top: 12,
                right: 16,
                child: _BtnIconRound(
                  ikon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),

              // ── Tombol barcode siswa (kiri atas) ───────
              Positioned(
                top: 12,
                left: 16,
                child: _loadingBarcode
                    ? _buildBarcodeButtonLoading()
                    : _hasBarcode
                        ? _BarcodeActionBtn(
                            label: 'Download Barcode',
                            ikon: Icons.download_rounded,
                            onTap: _downloadBarcode,
                          )
                        : _BarcodeActionBtn(
                            label: 'Generate Barcode',
                            ikon: Icons.qr_code_rounded,
                            onTap: _generateBarcode,
                            isGenerate: true,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barcode button loading ────────────────────────────────
  Widget _buildBarcodeButtonLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 8),
          Text('Memuat...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // ── 🔥 Kartu pesan GAGAL (mis. "barcode bukan milik Anda") ─
  Widget _buildGagalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded,
              color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coba scan ulang barcode milik Anda sendiri',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sukses card ───────────────────────────────────────────
  Widget _buildSuksesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tipe == TipeAbsensiBarcode.masuk
                      ? 'Absen Masuk Berhasil!'
                      : 'Absen Pulang Berhasil!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (_scanMessage != null)
                  Text(
                    _scanMessage!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              widget.onAbsensi
                  ?.call({'success': true, 'message': _scanMessage});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Selesai',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round icon button ─────────────────────────────────────
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

// ── Barcode action button (generate / download) ───────────
class _BarcodeActionBtn extends StatelessWidget {
  final String label;
  final IconData ikon;
  final VoidCallback onTap;
  final bool isGenerate;

  const _BarcodeActionBtn({
    required this.label,
    required this.ikon,
    required this.onTap,
    this.isGenerate = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isGenerate
              ? const Color(0xFF16A34A).withOpacity(0.82)
              : const Color(0xFF1D4ED8).withOpacity(0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Corner guide painter
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