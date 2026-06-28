import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class SocketService {
  static WebSocketChannel? channel;

  // 🔥 CALLBACK GLOBAL (dipakai semua service)
    static Function(dynamic data)? onStudentUpdate;

    // 📢 CALLBACK KHUSUS CMS
    static Function()? onCmsUpdated;

  static void connect() {
    print("🔌 SOCKET: Connecting to ${AppConfig.socketUrl}");
    channel = WebSocketChannel.connect(
      Uri.parse(AppConfig.socketUrl),
    );

   print("🔌 SOCKET: Connected!");

    // 🔥 Subscribe ke channel cms-home
    channel!.sink.add(jsonEncode({
      "event": "pusher:subscribe",
      "data": {
        "channel": "cms-home"
      }
    }));

    channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);

          print("🔥 REALTIME EVENT NAME: ${data['event']}");
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

        if (data['event'] == 'cms.home.updated' || data['event'] == 'home.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("🏠 CMS HOME UPDATED:");
          print(payload);

          if (onStudentUpdate != null) onStudentUpdate!(payload);
          if (onCmsUpdated != null) onCmsUpdated!();
        }

        // =========================
        // 🟪 CMS EVENT REALTIME
        // =========================

if (data['event'] == 'cms.event.updated' || data['event'] == 'event.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("🎉 CMS EVENT:");
          print(payload);

          if (onStudentUpdate != null) onStudentUpdate!(payload);
          if (onCmsUpdated != null) onCmsUpdated!();
        }

        // =========================
        // 📢 CMS PENGUMUMAN REALTIME
        // =========================
if (data['event'] == 'cms.pengumuman.updated' || data['event'] == 'pengumuman.updated') {
          final payload = jsonDecode(data['data'] ?? '{}');

          print("📢 CMS PENGUMUMAN:");
          print(payload);

          if (onStudentUpdate != null) onStudentUpdate!(payload);
          if (onCmsUpdated != null) onCmsUpdated!();
        }
     } catch (e) {
        print("❌ SOCKET PARSE ERROR: $e");
      }
    },
    onError: (error) {
      print("❌ SOCKET CONNECTION ERROR: $error");
    },
    onDone: () {
      print("🔌 SOCKET CLOSED / DISCONNECTED");
    },
  );
  }

  static void disconnect() {
    channel?.sink.close();
  }
}