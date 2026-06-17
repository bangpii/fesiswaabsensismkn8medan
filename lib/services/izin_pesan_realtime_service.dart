import 'dart:async';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'socket_service.dart';

enum PesanAction {
  none,
  message,
  read,
}

class IzinPesanRealtimeState {
  final int izinId;
  final PesanAction action;
  final Map<String, dynamic>? pesan;

  IzinPesanRealtimeState({
    required this.izinId,
    required this.action,
    this.pesan,
  });
}

class IzinPesanRealtimeService {
  static final _controller =
      StreamController<IzinPesanRealtimeState>.broadcast();

  static Stream<IzinPesanRealtimeState> get stream =>
      _controller.stream;

  static bool _started = false;

  // ═══════════════════════════════════════
  // 🚀 START LISTENER (REALTIME)
  // ═══════════════════════════════════════
 static void start() {
  if (_started) return;

  // 🔥 AMBIL CALLBACK LAMA (JANGAN DIMATIKAN)
  final oldCallback = SocketService.onStudentUpdate;

  SocketService.onStudentUpdate = (data) {
    // 🔥 JALANKAN SERVICE LAMA (izin_realtime_service)
    if (oldCallback != null) {
      oldCallback(data);
    }

    try {
      // 🔥 FILTER KHUSUS PESAN
      if (data['type'] == null) return;

      final type = data['type'];
      final pesan = data['pesan'];

      if (pesan == null) return;

      _controller.add(
        IzinPesanRealtimeState(
          izinId: pesan['izin_id'],
          action: type == 'read'
              ? PesanAction.read
              : PesanAction.message,
          pesan: pesan,
        ),
      );
    } catch (e) {
      print("❌ IZIN PESAN CALLBACK ERROR: $e");
    }
  };

  _started = true;
}
  // ═══════════════════════════════════════
  // 🔥 KIRIM PESAN
  // ═══════════════════════════════════════
  static Future<Map<String, dynamic>> kirimPesan({
    required int izinId,
    required String pesan,
  }) async {
    try {
      await ApiService.loadToken();

      final res = await ApiService.dio.post(
        '/izin/$izinId/pesan',
        data: {'pesan': pesan},
      );

      return res.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {
          'success': false,
          'message': 'Gagal kirim pesan'
        };
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══════════════════════════════════════
  // 🔥 MARK AS READ
  // ═══════════════════════════════════════
  static Future<void> markAsRead(int izinId) async {
    try {
      await ApiService.loadToken();

      await ApiService.dio.post('/izin/$izinId/read');
    } catch (e) {
      print("❌ MARK AS READ ERROR: $e");
    }
  }

  // ═══════════════════════════════════════
  // 🔥 LOAD PESAN AWAL (API)
  // ═══════════════════════════════════════
  static Future<List<dynamic>> loadPesan(int izinId) async {
    try {
      await ApiService.loadToken();

      final res = await ApiService.dio.get('/izin');

      final List data = res.data['data'] ?? [];

      final izin =
          data.firstWhere((e) => e['id'] == izinId);

      return izin['pesans'] ?? [];
    } catch (e) {
      print("❌ LOAD PESAN ERROR: $e");
      return [];
    }
  }

  // ═══════════════════════════════════════
  // 🔥 DISPOSE
  // ═══════════════════════════════════════
  static void dispose() {
    _controller.close();
  }
}