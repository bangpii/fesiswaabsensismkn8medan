// lib/services/absensi_history_service.dart

import 'dart:async';
// import 'package:dio/dio.dart';
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

      // 🔥 PARSE
      final allData = dataRaw
          .map((e) => RiwayatAbsensi.fromJson(e))
          .toList();

      // 🔥 FILTER HARI KERJA (Senin - Jumat)
      final filtered = allData.where((item) {
        return [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat'
        ].contains(item.hari);
      }).toList();

      // 🔥 URUTKAN SESUAI HARI
      final urutan = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat'
      ];

      filtered.sort((a, b) =>
          urutan.indexOf(a.hari).compareTo(urutan.indexOf(b.hari)));

      // 🔥 AMBIL MAX 5 HARI
      final finalData = filtered.take(5).toList();

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
        data: finalData,
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

      final filtered = allData.where((item) {
        return [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat'
        ].contains(item.hari);
      }).toList();

      final urutan = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat'
      ];

      filtered.sort((a, b) =>
          urutan.indexOf(a.hari).compareTo(urutan.indexOf(b.hari)));

      final meta = raw['meta'] ?? {};
      final rekapRaw = meta['rekap'] ?? {};

      final rekap = {
        'hadir': (rekapRaw['hadir'] ?? 0) as int,
        'terlambat': (rekapRaw['terlambat'] ?? 0) as int,
        'alpa': (rekapRaw['alpa'] ?? 0) as int,
        'izin': (rekapRaw['izin'] ?? 0) as int,
      };

      return AbsensiHistoryResponse(
        data: filtered,
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