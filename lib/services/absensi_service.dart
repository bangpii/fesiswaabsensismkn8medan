// lib/services/absensi_service.dart
//
// 🔥 ABSENSI SERVICE — Semua API call untuk fitur absensi
//
// Endpoint:
//   POST /absensi/compress-photo
//   POST /absensi/masuk
//   POST /absensi/pulang
//   POST /absensi/scan-barcode-masuk
//   POST /absensi/scan-barcode-pulang
//   GET  /absensi/hari-ini
//   POST /barcode/generate
//   GET  /barcode/status
//   GET  /barcode/download
//
// 🔥 LOGIKA BARCODE BARU:
//   QR berisi URL: "https://domain/redirect?code=SMKN8-{nisn}-{random}"
//   → Scan DALAM app  : extractBarcodeCode() → ambil ?code= → kirim ke backend
//   → Scan LUAR app   : browser buka URL → redirect ke Maps (handled backend)
//

import 'package:dio/dio.dart';
import 'api_service.dart';
import 'location_service.dart';

class AbsensiService {
  // ══════════════════════════════════════════════════════
  // 📸 COMPRESS FOTO
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> compressPhoto(String filePath) async {
    try {
      await ApiService.loadToken();

      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          filePath,
          filename: 'absensi_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await ApiService.dio.post(
        '/absensi/compress-photo',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Response tidak valid'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
        return {'success': false, 'message': 'Gagal upload foto: ${e.message}'};
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 📸 ABSEN MASUK DENGAN FOTO
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> absenMasukCamera({
    required String tempPath,
    required double lat,
    required double lng,
    String? keterangan,
  }) async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.post(
        '/absensi/masuk',
        data: {
          'temp_path' : tempPath,
          'lat'       : lat,
          'lng'       : lng,
          if (keterangan != null) 'keterangan': keterangan,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Response tidak valid'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
        final status = e.response?.statusCode;
      if (status == 403) {
        return {
          'success': false,
          'message': d?['message'] ?? 'Tidak diizinkan melakukan absensi'
        };
      }
        if (status == 400) {
          return {'success': false, 'message': d?['message'] ?? 'Tidak dapat absen saat ini'};
        }
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 📸 ABSEN PULANG DENGAN FOTO
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> absenPulangCamera({
    required String tempPath,
    required double lat,
    required double lng,
  }) async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.post(
        '/absensi/pulang',
        data: {
          'temp_path' : tempPath,
          'lat'       : lat,
          'lng'       : lng,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Response tidak valid'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 📲 ABSEN MASUK VIA BARCODE
  // Menerima raw barcode value (sudah di-extract dari URL oleh modal)
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> absenMasukBarcode({
    required String barcodeValue,
    required double lat,
    required double lng,
  }) async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.post(
        '/absensi/scan-barcode-masuk',
        data: {
          'barcode_value' : barcodeValue,
          'lat'           : lat,
          'lng'           : lng,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Response tidak valid'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
        final status = e.response?.statusCode;
        if (status == 403) {
          return {
            'success': false,
            'message': d?['message'] ?? 'Tidak diizinkan melakukan absensi'
          };
        }
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 📲 ABSEN PULANG VIA BARCODE
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> absenPulangBarcode({
    required String barcodeValue,
    required double lat,
    required double lng,
  }) async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.post(
        '/absensi/scan-barcode-pulang',
        data: {
          'barcode_value' : barcodeValue,
          'lat'           : lat,
          'lng'           : lng,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Response tidak valid'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 📋 CEK STATUS ABSENSI HARI INI
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> hariIni() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.get('/absensi/hari-ini');
      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'data': null};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'data': null};
    }
  }

  // ══════════════════════════════════════════════════════
  // 🔲 BARCODE — CEK STATUS
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> barcodeStatus() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.get('/barcode/status');
      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'has_barcode': false};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'success': false, 'has_barcode': false};
    }
  }

  // ══════════════════════════════════════════════════════
  // 🔲 BARCODE — GENERATE
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> barcodeGenerate() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.post('/barcode/generate');
      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Gagal generate barcode'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ══════════════════════════════════════════════════════
  // 🔲 BARCODE — DOWNLOAD
  // ══════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> barcodeDownload() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.get('/barcode/download');
      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {'success': false, 'message': 'Barcode tidak ditemukan'};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

// ══════════════════════════════════════════════════════
  // 🗺️ DEEP LINK — URL Maps sekolah
  // 🆕 Sekarang sumbernya dari backend (tabel lokasis.maps_url),
  // ditarik via LocationService.loadSchoolLocation()
  // ══════════════════════════════════════════════════════
  static String get mapsUrlSekolah => LocationService.mapsUrlSekolah;

  // ══════════════════════════════════════════════════════
  // 🆕 HELPER LOKASI
  // ══════════════════════════════════════════════════════
  static Future<UserLocation?> getLocationForAbsensi() async {
    return await LocationService.getCurrentLocation();
  }

  static double hitungJarakKeSekolah(double lat, double lng) {
    return LocationService.calculateDistance(
      lat, lng,
      LocationService.schoolCenterLat,
      LocationService.schoolCenterLng,
    );
  }

  static bool isInsideSchoolArea(double lat, double lng) {
    return LocationService.isInsideSchoolArea(lat, lng);
  }

  // ══════════════════════════════════════════════════════
  // 🔍 PARSER BARCODE — DUAL PURPOSE
  //
  // QR bisa berisi dua format:
  //   Format LAMA (legacy): "SMKN8-{nisn}-{random}"
  //   Format BARU (URL)   : "https://domain/redirect?code=SMKN8-{nisn}-{random}"
  //
  // extractBarcodeCode() akan mengembalikan raw code "SMKN8-..."
  // apapun format input-nya. Return null jika tidak valid.
  // ══════════════════════════════════════════════════════

  /// Extract raw barcode code dari QR content.
  /// Support dua format:
  ///   1. Raw   : "SMKN8-12345-AbCdEfGh"
  ///   2. URL   : "https://domain/redirect?code=SMKN8-12345-AbCdEfGh"
  /// Return null jika format tidak dikenali.
  static String? extractBarcodeCode(String rawQrContent) {
    final trimmed = rawQrContent.trim();

    // ── Format 1: langsung raw code ───────────────────────
    if (trimmed.startsWith('SMKN8-')) {
      final parts = trimmed.split('-');
      if (parts.length >= 3) return trimmed;
    }

    // ── Format 2: URL dengan query param ?code= ───────────
    try {
      final uri = Uri.parse(trimmed);
      final code = uri.queryParameters['code'];
      if (code != null && code.startsWith('SMKN8-')) {
        final parts = code.split('-');
        if (parts.length >= 3) return code;
      }
    } catch (_) {
      // Bukan URL valid, abaikan
    }

    return null; // Format tidak dikenali
  }

  /// Cek apakah QR content adalah barcode absensi yang valid
  /// (support raw code & URL format)
  static bool isValidAbsensiBarcode(String rawQrContent) {
    return extractBarcodeCode(rawQrContent) != null;
  }

  /// Cek apakah string adalah URL Google Maps
  static bool isMapsUrl(String value) {
    return value.contains('google.com/maps') ||
        value.contains('maps.google') ||
        value.contains('goo.gl/maps') ||
        value.contains('maps.app.goo.gl');
  }
}