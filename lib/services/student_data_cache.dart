// lib/services/student_data_cache.dart
// ═══════════════════════════════════════════════════════════
// SINGLETON CACHE — data siswa tidak di-fetch ulang saat
// pindah tab, hanya di-refresh sekali saat app start / hot restart
// ═══════════════════════════════════════════════════════════

class StudentDataCache {
  // ── Singleton ─────────────────────────────────────────
  StudentDataCache._();
  static final StudentDataCache instance = StudentDataCache._();

  // ── Cached fields ─────────────────────────────────────
  bool isLoaded = false;

  String namaLengkap = '';
  String? photoUrl;
  List<Map<String, dynamic>> jadwalHariIni = [];

  // Raw response (bisa dipakai screen lain kalau perlu)
  Map<String, dynamic> rawData = {};

  // ── Reset (dipanggil saat logout) ─────────────────────
  void clear() {
    isLoaded        = false;
    namaLengkap     = '';
    photoUrl        = null;
    jadwalHariIni   = [];
    rawData         = {};
  }
}