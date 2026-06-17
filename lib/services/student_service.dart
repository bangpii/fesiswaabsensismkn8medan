import 'package:dio/dio.dart';
import 'api_service.dart';

class StudentService {
  // 🔥 GET DATA SISWA — pastikan token sudah di-load sebelum call ini
  static Future<Map<String, dynamic>> getStudentData(String login) async {
    try {
      // Pastikan token selalu ada di header (penting setelah hot restart)
      await ApiService.loadToken();

      final response = await ApiService.dio.post(
        '/siswa/data',
        data: {"login": login},
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      return {};
    } catch (e) {
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) return d;
      }
      return {"message": "Terjadi kesalahan: $e"};
    }
  }

  // ── Inner data helper ─────────────────────────────────
  // Response: { "status": "success", "data": { user, student, ... } }
  static Map<String, dynamic> _inner(Map<String, dynamic> raw) {
    final d = raw['data'];
    return (d is Map<String, dynamic>) ? d : {};
  }

  // ── Extractors — semua non-null ───────────────────────

  static Map<String, dynamic> extractUser(Map<String, dynamic> raw) {
    final u = _inner(raw)['user'];
    return (u is Map<String, dynamic>) ? u : {};
  }

  static Map<String, dynamic> extractStudent(Map<String, dynamic> raw) {
    final s = _inner(raw)['student'];
    return (s is Map<String, dynamic>) ? s : {};
  }

  static Map<String, dynamic> extractClass(Map<String, dynamic> raw) {
    final c = _inner(raw)['class'];
    return (c is Map<String, dynamic>) ? c : {};
  }

  static Map<String, dynamic> extractDepartment(Map<String, dynamic> raw) {
    final d = _inner(raw)['department'];
    return (d is Map<String, dynamic>) ? d : {};
  }

  static List<dynamic> extractModules(Map<String, dynamic> raw) {
    final m = _inner(raw)['modules'];
    return (m is List) ? m : [];
  }

  // 🔥 KEY — today_schedule: List<{ module, teacher, jam_masuk, jam_selesai }>
  static List<Map<String, dynamic>> extractTodaySchedule(
      Map<String, dynamic> raw) {
    final ts = _inner(raw)['today_schedule'];
    if (ts is List) {
      return ts
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // ══════════════════════════════════════════════════════
  // 🆕 EXTRACTORS UNTUK PROFILE
  // ══════════════════════════════════════════════════════

  /// Ambil full inner data (user + student + class + department + modules)
  /// sebagai satu map flat, siap dipakai DataSiswa.fromBackend()
  static Map<String, dynamic> extractProfileData(Map<String, dynamic> raw) {
    return _inner(raw);
  }

  // ══════════════════════════════════════════════════════
  // 🔥 EXTRACTOR NILAI UJIAN — BACA DARI nilai_ujian ROOT
  // ══════════════════════════════════════════════════════
  // Response backend:
  // {
  //   "status": "success",
  //   "data": {
  //     "nilai_ujian": [
  //       {
  //         "quiz_id": 195,
  //         "msc_id": 15,
  //         "module": "Dasar Dasar Kejuruan (DDK) - TKKR",
  //         "quiz": "ujian",
  //         "score": "100",
  //         "is_passed": true
  //       }
  //     ]
  //   }
  // }

  /// Extract nilai dari field `nilai_ujian` di dalam data
  /// Return: List<{ mapel, nilai, grade, quizTitle, isPassed }>
  static List<Map<String, dynamic>> extractNilaiUjian(
      Map<String, dynamic> raw) {
    final inner = _inner(raw);
    final nilaiUjian = inner['nilai_ujian'];

    if (nilaiUjian is! List || nilaiUjian.isEmpty) return [];

    final List<Map<String, dynamic>> result = [];

    for (final item in nilaiUjian) {
      if (item is! Map) continue;

      final mapelNama =
          item['module']?.toString() ?? 'Mata Pelajaran';
      final scoreRaw = item['score'];
      final double nilai =
          double.tryParse(scoreRaw?.toString() ?? '') ?? 0.0;
      final String quizTitle = item['quiz']?.toString() ?? 'Ujian';
      final bool isPassed = item['is_passed'] == true;
      final String grade = _hitungGrade(nilai);

      result.add({
        'mapel': mapelNama,
        'nilai': nilai,
        'grade': grade,
        'quizTitle': quizTitle,
        'isPassed': isPassed,
        'quiz_id': item['quiz_id'],
        'msc_id': item['msc_id'],
      });
    }

    return result;
  }

  /// [DEPRECATED — tidak dipakai lagi, diganti extractNilaiUjian]
  /// Dulu baca dari quizzes di dalam modules, sekarang pakai nilai_ujian
  static List<Map<String, dynamic>> extractNilaiFromQuizzes(
      Map<String, dynamic> raw) {
    // Redirect ke extractor baru
    return extractNilaiUjian(raw);
  }

  static String _hitungGrade(double nilai) {
    if (nilai >= 90) return 'A';
    if (nilai >= 85) return 'A-';
    if (nilai >= 80) return 'B+';
    if (nilai >= 75) return 'B';
    if (nilai >= 70) return 'B-';
    if (nilai >= 65) return 'C+';
    if (nilai >= 60) return 'C';
    return 'D';
  }
}