import 'dart:async';
import 'absensi_service.dart';
import 'socket_service.dart';

enum AbsensiAction {
  none,
  masuk,
  pulang,
}

class AbsensiRealtimeState {
  final AbsensiAction action;
  final String statusText;
  final Map<String, dynamic>? raw;

  AbsensiRealtimeState({
    required this.action,
    required this.statusText,
    this.raw,
  });
}

class AbsensiRealtimeService {
  static final _controller =
      StreamController<AbsensiRealtimeState>.broadcast();

  static Stream<AbsensiRealtimeState> get stream => _controller.stream;

  static AbsensiRealtimeState? lastState;

  static Timer? _timer;

  // ═══════════════════════════════════════════════
  // 🚀 START REALTIME
  // ═══════════════════════════════════════════════
  static Future<void> start() async {
    await _load();

    // ⏱ refresh tiap 10 detik
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _load();
    });

    // 🔥 Realtime dari Reverb
    SocketService.onStudentUpdate = (data) {
      _load();
    };
  }

  static void stop() {
    _timer?.cancel();
    _controller.close();
  }

  // ═══════════════════════════════════════════════
  // 🔥 LOAD + HITUNG LOGIKA
  // ═══════════════════════════════════════════════
static Future<void> _load() async {
  try {
    final res = await AbsensiService.hariIni();

    final data = res['data'];
    final isLibur = res['is_libur'] == true;
    final hari = res['hari'] ?? '';
    final statusUI = res['status_ui'];

    // 🔥 LIBUR
    if (isLibur) {
      final hariCapital =
          hari.isNotEmpty ? hari[0].toUpperCase() + hari.substring(1) : '';

      _emit(AbsensiAction.none, "$hariCapital Libur");
      return;
    }

    // 🔥 STATUS DARI BACKEND (INI KUNCI UTAMA)
    final label = statusUI?['label'] ?? '';

    AbsensiAction action = AbsensiAction.none;

    // 🔥 ACTION (TIDAK DIUBAH LOGIKA)
final status = data?['status'];

if (label == 'Batas Absensi Pulang Berakhir') {

  action = AbsensiAction.none;

} else if (data == null) {

  // belum ada data absensi
  action = AbsensiAction.masuk;

} else if (
    data['jam_pulang'] == null &&
    status != 'izin'
) {

  // hadir
  // terlambat
  // alpa
  // semua yg belum pulang

  action = AbsensiAction.pulang;

} else {

  // sudah pulang / izin
  action = AbsensiAction.none;
}

final newState = AbsensiRealtimeState(
      action: action,
      statusText: label,
      raw: res,
    );
    lastState = newState;
    _controller.add(newState);

  } catch (e) {
    _emit(AbsensiAction.none, "Gagal ambil data");
  }
}

  // ═══════════════════════════════════════════════
  // 🔧 HELPER
  // ═══════════════════════════════════════════════

  static void _emit(AbsensiAction action, String text) {
    _controller.add(
      AbsensiRealtimeState(
        action: action,
        statusText: text,
      ),
    );
  }
}