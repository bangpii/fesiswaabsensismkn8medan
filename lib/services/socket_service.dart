import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class SocketService {
  static WebSocketChannel? channel;

  // 🔥 CALLBACK GLOBAL (dipakai semua service)
  static Function(dynamic data)? onStudentUpdate;

  static void connect() {
    channel = WebSocketChannel.connect(
      Uri.parse(AppConfig.socketUrl),
    );

    channel!.stream.listen((message) {
      try {
        final data = jsonDecode(message);

        print("🔥 REALTIME:");
        print(data);

        // =========================
        // 🔐 EXISTING (JANGAN DIUBAH)
        // =========================
        if (data['event'] == 'auth.event') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("TYPE: ${payload['type']}");
          print("USER: ${payload['user']}");
        }

        // =========================
        // 🟦 STUDENT UPDATE
        // =========================
        if (data['event'] == 'student.data.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("📦 STUDENT UPDATE:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
        }

        // =========================
        // 🟩 IZIN REALTIME (BARU)
        // =========================
        if (data['event'] == 'izin.event') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("📩 IZIN UPDATE:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
        }

        // =========================
        // 💬 IZIN PESAN REALTIME
        // =========================
        if (data['event'] == 'izin.pesan') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("💬 IZIN PESAN:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
        }

        // =========================
        // 🟨 CMS HOME REALTIME
        // =========================

        if (data['event'] == 'cms.home.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("🏠 CMS HOME UPDATED:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
        }

        // =========================
        // 🟪 CMS EVENT REALTIME
        // =========================

        if (data['event'] == 'cms.event.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("🎉 CMS EVENT:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
        }

        // =========================
        // 📢 CMS PENGUMUMAN REALTIME
        // =========================

        if (data['event'] == 'cms.pengumuman.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("📢 CMS PENGUMUMAN:");
          print(payload);

          if (onStudentUpdate != null) {
            onStudentUpdate!(payload);
          }
}
      } catch (e) {
        print("❌ SOCKET ERROR: $e");
      }
    });
  }

  static void disconnect() {
    channel?.sink.close();
  }
}