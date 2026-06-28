// lib/services/absensi_history_service.dart

import 'dart:async';
import 'api_service.dart';
import 'socket_service.dart';

class AbsensiHistoryResponse {
  final List<RiwayatAbsensi> data;
  final Map<String, int> rekap;
  final int total;

  AbsensiHistoryResponse({
    required this.data,
    required this.rekap,
    required this.total,
  });
}

class RiwayatAbsensi {
  final int id;
  final String tanggal;
  final String hari;
  final int mingguKe;

  final String? jamMasuk;
  final String? jamPulang;

  final String status;
  final String? keterangan;

  final String? fotoMasuk;
  final String? fotoPulang;

  // 🔥 BARU: tipe media untuk masuk & pulang
  final String? tipeMasuk;
  final String? tipePulang;

  final bool sudahMasuk;
  final bool sudahPulang;

  RiwayatAbsensi({
    required this.id,
    required this.tanggal,
    required this.hari,
    required this.mingguKe,
    required this.jamMasuk,
    required this.jamPulang,
    required this.status,
    required this.keterangan,
    required this.fotoMasuk,
    required this.fotoPulang,
    required this.tipeMasuk,
    required this.tipePulang,
    required this.sudahMasuk,
    required this.sudahPulang,
  });

  factory RiwayatAbsensi.fromJson(Map<String, dynamic> json) {
    return RiwayatAbsensi(
      id: json['id'],
      tanggal: json['tanggal'],
      hari: _capitalize(json['hari']),
      mingguKe: json['minggu_ke'] ?? 0,
      jamMasuk: json['jam_masuk'],
      jamPulang: json['jam_pulang'],
      status: json['status'] ?? '',
      keterangan: json['keterangan'],
      fotoMasuk: json['foto_masuk'],
      fotoPulang: json['foto_pulang'],
      // 🔥 parse tipe_masuk & tipe_pulang dari backend
      tipeMasuk: json['tipe_masuk'],
      tipePulang: json['tipe_pulang'],
      sudahMasuk: json['sudah_masuk'] ?? false,
      sudahPulang: json['sudah_pulang'] ?? false,
    );
  }

  static String _capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}

class AbsensiHistoryService {
  static final _controller =
      StreamController<AbsensiHistoryResponse>.broadcast();

  static Stream<AbsensiHistoryResponse> get stream => _controller.stream;

  static bool _isStarted = false;

  // ═══════════════════════════════════════════════
  // 🚀 START REALTIME (REVERB)
  // ═══════════════════════════════════════════════
  static Future<void> start() async {
    if (_isStarted) return;

    await load();

    // 🔥 Realtime dari Laravel Reverb
    SocketService.onStudentUpdate = (data) {
      load();
    };

    _isStarted = true;
  }

  // ═══════════════════════════════════════════════
  // 🔥 LOAD DATA DARI BACKEND
  // ═══════════════════════════════════════════════
  static Future<void> load() async {
    try {
      await ApiService.loadToken();

      final now = DateTime.now();

      final response = await ApiService.dio.get(
        '/absensi/riwayat',
        queryParameters: {
          'bulan': now.month,
          'tahun': now.year,
        },
      );

      final raw = response.data;

      if (raw is! Map<String, dynamic>) return;

      final List dataRaw = raw['data'] ?? [];

      // 🔥 PARSE SEMUA DATA — jangan filter/sort/take di sini
      // Biarkan tile yang filter berdasarkan minggu
      final allData = dataRaw
          .map((e) => RiwayatAbsensi.fromJson(e))
          .toList();

      // 🔥 REKAP
      final meta = raw['meta'] ?? {};
      final rekapRaw = meta['rekap'] ?? {};

      final rekap = {
        'hadir': (rekapRaw['hadir'] ?? 0) as int,
        'terlambat': (rekapRaw['terlambat'] ?? 0) as int,
        'alpa': (rekapRaw['alpa'] ?? 0) as int,
        'izin': (rekapRaw['izin'] ?? 0) as int,
      };

      final result = AbsensiHistoryResponse(
        data: allData,
        rekap: rekap,
        total: meta['total_data'] ?? 0,
      );

      _controller.add(result);
    } catch (e) {
      print("❌ ERROR HISTORY: $e");
    }
  }

  // ═══════════════════════════════════════════════
  // 📦 GET ONCE (optional)
  // ═══════════════════════════════════════════════
  static Future<AbsensiHistoryResponse?> getOnce() async {
    try {
      await ApiService.loadToken();

      final now = DateTime.now();

      final response = await ApiService.dio.get(
        '/absensi/riwayat',
        queryParameters: {
          'bulan': now.month,
          'tahun': now.year,
        },
      );

      final raw = response.data;

      if (raw is! Map<String, dynamic>) return null;

      final List dataRaw = raw['data'] ?? [];

      final allData = dataRaw
          .map((e) => RiwayatAbsensi.fromJson(e))
          .toList();

      final meta = raw['meta'] ?? {};
      final rekapRaw = meta['rekap'] ?? {};

      final rekap = {
        'hadir': (rekapRaw['hadir'] ?? 0) as int,
        'terlambat': (rekapRaw['terlambat'] ?? 0) as int,
        'alpa': (rekapRaw['alpa'] ?? 0) as int,
        'izin': (rekapRaw['izin'] ?? 0) as int,
      };

      return AbsensiHistoryResponse(
        data: allData,
        rekap: rekap,
        total: meta['total_data'] ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  // 🧹 DISPOSE
  // ═══════════════════════════════════════════════
  static void dispose() {
    _controller.close();
  }
}