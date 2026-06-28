import 'dart:async';

import 'api_service.dart';
import 'socket_service.dart';

class CmsService {
  // ═══════════════════════════════════════
  // 🔥 STREAM REALTIME
  // ═══════════════════════════════════════

  static final StreamController<List<dynamic>> _controller =
      StreamController<List<dynamic>>.broadcast();

  static Stream<List<dynamic>> get stream =>
      _controller.stream;

  // cache data
  static List<dynamic> _cache = [];

  // ═══════════════════════════════════════
  // 🔥 GET HOME CMS
  // ═══════════════════════════════════════

  static Future<List<dynamic>> getHome() async {
    try {
      final response =
          await ApiService.dio.get('/cms/home');

      final data = response.data['data'] ?? [];

      _cache = List<dynamic>.from(data);

      return _cache;
    } catch (e) {
      print("❌ CMS GET ERROR: $e");

      return [];
    }
  }

  // ═══════════════════════════════════════
  // 🔥 LOAD + EMIT
  // ═══════════════════════════════════════

  static Future<void> load() async {
    final data = await getHome();

    _controller.add(data);
  }

  // ═══════════════════════════════════════
  // 🔥 START REALTIME
  // ═══════════════════════════════════════

  static Future<void> startRealtime() async {
    // load pertama
    await load();

    // 📢 listen khusus CMS — tidak bentrok dengan onStudentUpdate
    SocketService.onCmsUpdated = () async {
      print("🔥 CMS REALTIME: reload...");
      await load();
    };
  }

  // ═══════════════════════════════════════
  // 🔥 STOP
  // ═══════════════════════════════════════

  static void dispose() {
    _controller.close();
  }

  // ═══════════════════════════════════════
  // 🔥 CACHE
  // ═══════════════════════════════════════

  static List<dynamic> get cache => _cache;
}