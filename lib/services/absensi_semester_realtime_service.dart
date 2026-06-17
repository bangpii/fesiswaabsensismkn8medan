import 'dart:async';

import 'api_service.dart';
import 'socket_service.dart';

class AbsensiSemesterData {
  final int semester;
  final String tahunAjaran;

  final int persentaseHadir;

  final int hadir;
  final int terlambat;
  final int izin;
  final int alpa;

  final int totalMasuk;
  final int totalPertemuan;

  final String tanggalMulai;
  final String tanggalSelesai;

  AbsensiSemesterData({
    required this.semester,
    required this.tahunAjaran,
    required this.persentaseHadir,
    required this.hadir,
    required this.terlambat,
    required this.izin,
    required this.alpa,
    required this.totalMasuk,
    required this.totalPertemuan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
  });

  factory AbsensiSemesterData.fromJson(Map<String, dynamic> json) {
    return AbsensiSemesterData(
      semester: json['semester'] ?? 0,

      tahunAjaran: json['tahun_ajaran'] ?? '',

      persentaseHadir: json['persentase_hadir'] ?? 0,

      hadir: json['hadir'] ?? 0,

      terlambat: json['terlambat'] ?? 0,

      izin: json['izin'] ?? 0,

      alpa: json['alpa'] ?? 0,

      totalMasuk: json['total_masuk'] ?? 0,

      totalPertemuan: json['total_pertemuan'] ?? 0,

      tanggalMulai: json['tanggal_mulai'] ?? '',

      tanggalSelesai: json['tanggal_selesai'] ?? '',
    );
  }
}

class AbsensiSemesterRealtimeService {
  static final _controller =
      StreamController<AbsensiSemesterData>.broadcast();

  static Stream<AbsensiSemesterData> get stream =>
      _controller.stream;

  static bool _isStarted = false;

  static Timer? _timer;

  static AbsensiSemesterData? latestData;

  // ============================================
  // 🚀 START REALTIME
  // ============================================

  static Future<void> start({
    int? semester,
    String? tahunAjaran,
  }) async {
    if (_isStarted) return;

    await load(
      semester: semester,
      tahunAjaran: tahunAjaran,
    );

    // ============================================
    // 🔥 REALTIME REVERB
    // ============================================

    SocketService.onStudentUpdate = (data) {

      print("🔥 REALTIME SEMESTER UPDATE");
      print(data);

      load(
        semester: semester,
        tahunAjaran: tahunAjaran,
      );
    };

    // ============================================
    // ⏱ AUTO REFRESH
    // ============================================

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        load(
          semester: semester,
          tahunAjaran: tahunAjaran,
        );
      },
    );

    _isStarted = true;
  }

  // ============================================
  // 📦 LOAD DATA BACKEND
  // ============================================

  static Future<void> load({
    int? semester,
    String? tahunAjaran,
  }) async {
    try {

      await ApiService.loadToken();

      final response = await ApiService.dio.get(
        '/absensi/statistik-semester',

        queryParameters: {

          if (semester != null)
            'semester': semester,

          if (tahunAjaran != null)
            'tahun_ajaran': tahunAjaran,
        },
      );

      final raw = response.data;

      if (raw is! Map<String, dynamic>) {
        return;
      }

      final success = raw['success'] == true;

      if (!success) {
        return;
      }

      final data = raw['data'];

      if (data == null) {
        return;
      }

      final result =
          AbsensiSemesterData.fromJson(data);

      latestData = result;

      _controller.add(result);

    } catch (e) {

      print("❌ ERROR SEMESTER REALTIME:");
      print(e);
    }
  }

  // ============================================
  // 📥 GET ONCE
  // ============================================

  static Future<AbsensiSemesterData?> getOnce({
    int? semester,
    String? tahunAjaran,
  }) async {

    try {

      await ApiService.loadToken();

      final response = await ApiService.dio.get(
        '/absensi/statistik-semester',

        queryParameters: {

          if (semester != null)
            'semester': semester,

          if (tahunAjaran != null)
            'tahun_ajaran': tahunAjaran,
        },
      );

      final raw = response.data;

      if (raw is! Map<String, dynamic>) {
        return null;
      }

      final success = raw['success'] == true;

      if (!success) {
        return null;
      }

      final data = raw['data'];

      if (data == null) {
        return null;
      }

      return AbsensiSemesterData.fromJson(data);

    } catch (e) {

      print("❌ ERROR GET ONCE SEMESTER:");
      print(e);

      return null;
    }
  }

  // ============================================
  // 🛑 STOP
  // ============================================

  static void stop() {

    _timer?.cancel();
  }

  // ============================================
  // 🧹 DISPOSE
  // ============================================

  static void dispose() {

    _timer?.cancel();

    _controller.close();
  }
}