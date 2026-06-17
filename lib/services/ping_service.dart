// lib/services/ping_service.dart
import 'dart:async';
import 'api_service.dart';

class PingService {
  static Timer? _timer;
  static bool _isOnline = false;

  // Callback dipanggil setiap kali status berubah
  static Function(bool isOnline)? onStatusChanged;

  static bool get isOnline => _isOnline;

  // ── START ─────────────────────────────────────────────
  // Aman dipanggil berkali-kali — cancel dulu sebelum buat baru
  static void start() {
    _timer?.cancel();
    _timer = null;

    // Langsung ping pertama kali
    _doPing();

    // Lalu setiap 20 detik (lebih hemat baterai dari 10 detik)
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _doPing());
  }

  // ── STOP ──────────────────────────────────────────────
  static void stop() {
    _timer?.cancel();
    _timer = null;
    // Set offline secara lokal
    _updateStatus(false);
  }

  // ── INTERNAL ──────────────────────────────────────────
  static Future<void> _doPing() async {
    try {
      final response = await ApiService.dio.post(
        '/ping',
        options: _timeoutOptions(),
      );

      final status = response.data?['status'];
      final nowOnline = (status == 'online');
      _updateStatus(nowOnline);
    } catch (_) {
      // Bisa timeout / network error
      // TIDAK set offline saat error jaringan sementara
      // Biarkan status terakhir tetap, agar tidak flicker
    }
  }

  static void _updateStatus(bool nowOnline) {
    if (_isOnline != nowOnline) {
      _isOnline = nowOnline;
      onStatusChanged?.call(_isOnline);
    }
  }

  // Timeout 8 detik — tidak terlalu singkat, tidak terlalu lama
  static dynamic _timeoutOptions() {
    return null; // Pakai default timeout dari ApiService
  }
}