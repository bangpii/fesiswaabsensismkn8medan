import 'dart:async';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'socket_service.dart';

enum IzinAction {
  none,
  created,
  updated,
  message,
}

class IzinRealtimeState {
  final IzinAction action;
  final List<dynamic> izins;
  final Map<String, dynamic>? raw;

  IzinRealtimeState({
    required this.action,
    required this.izins,
    this.raw,
  });
}

class IzinRealtimeService {
  static final _controller =
      StreamController<IzinRealtimeState>.broadcast();

  static Stream<IzinRealtimeState> get stream => _controller.stream;

  static bool _started = false;

  // ═══════════════════════════════════════════════
  // 🚀 START REALTIME
  // ═══════════════════════════════════════════════
static Future<void> start() async {
  // 🔥 SELALU LOAD DATA SETIAP MASUK HALAMAN
  await load();

  // 🔥 LISTENER SOCKET HANYA SEKALI
  if (!_started) {
    SocketService.onStudentUpdate = (data) {
      load();
    };

    _started = true;
  }
}

  // ═══════════════════════════════════════════════
  // 🔥 LOAD DATA IZIN
  // ═══════════════════════════════════════════════
  static Future<void> load() async {
    try {
      await ApiService.loadToken();

      final response = await ApiService.dio.get('/izin');

      final raw = response.data;

      if (raw is! Map<String, dynamic>) return;

      final List list = raw['data'] ?? [];

      _controller.add(
        IzinRealtimeState(
          action: IzinAction.none,
          izins: list,
          raw: raw,
        ),
      );
    } catch (e) {
      print("❌ IZIN REALTIME ERROR: $e");
    }
  }

  // ═══════════════════════════════════════════════
  // 🔥 CREATE IZIN
  // ═══════════════════════════════════════════════
  static Future<Map<String, dynamic>> create({
    required String tanggal,
    required String jenis,
    String? keterangan,
  }) async {
    try {
      await ApiService.loadToken();

      final res = await ApiService.dio.post(
        '/izin',
        data: {
          'tanggal_izin': tanggal,
          'jenis_izin': jenis,
          if (keterangan != null) 'keterangan': keterangan,
        },
      );

      await load(); // refresh realtime

      return res.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {
          'success': false,
          'message': 'Gagal kirim izin'
        };
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // 🔥 KIRIM PESAN
  // ═══════════════════════════════════════════════
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

      await load();

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

  // ═══════════════════════════════════════════════
  // 🔥 DISPOSE
  // ═══════════════════════════════════════════════
  static void dispose() {
    _controller.close();
  }
}