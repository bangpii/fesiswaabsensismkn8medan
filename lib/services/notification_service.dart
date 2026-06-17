// lib/services/notification_service.dart
import 'dart:async';
import '../services/student_data_cache.dart';
import '../services/absensi_realtime_service.dart';
import '../services/cms_service.dart';

enum NotifType { absensi, jadwal, event, pengumuman }

class AppNotification {
  final String id;
  final NotifType type;
  final String judul;
  final String isi;
  final DateTime waktu;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.judul,
    required this.isi,
    required this.waktu,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        judul: judul,
        isi: isi,
        waktu: waktu,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get stream => _controller.stream;

  List<AppNotification> _notifications = [];
  final Set<String> _readIds = {};

  StreamSubscription? _absensiSub;
  Timer? _refreshTimer;

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  // ═══════════════════════════════
  // START
  // ═══════════════════════════════
  void start() {
    _refresh();

    // Listen absensi realtime
    _absensiSub?.cancel();
    _absensiSub = AbsensiRealtimeService.stream.listen((_) {
      _refresh();
    });

    // Listen CMS realtime
    CmsService.stream.listen((_) {
      _refresh();
    });

    // Refresh tiap 5 menit
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refresh(),
    );
  }

  // ═══════════════════════════════
  // REFRESH — BUILD NOTIFIKASI
  // ═══════════════════════════════
  void _refresh() {
    final List<AppNotification> result = [];
    final cache = StudentDataCache.instance;
    final now = DateTime.now();

    // ── 1. ABSENSI ─────────────────────────────
    // Cek dari AbsensiRealtimeService state terakhir
    // (kita baca dari raw jika tersedia)
    _buildAbsensiNotif(result, now);

    // ── 2. JADWAL HARI INI ──────────────────────
    if (cache.isLoaded && cache.jadwalHariIni.isNotEmpty) {
      for (final jadwal in cache.jadwalHariIni) {
        final status = jadwal['status'] as String? ?? '';
        final mapel = jadwal['mapel'] as String? ?? '-';
        final jam = jadwal['jam'] as String? ?? '';

        if (status == 'akan datang') {
          result.add(AppNotification(
            id: 'jadwal_${mapel}_$jam',
            type: NotifType.jadwal,
            judul: 'Jadwal: $mapel',
            isi: 'Pukul $jam — Segera dimulai',
            waktu: now,
            isRead: _readIds.contains('jadwal_${mapel}_$jam'),
          ));
        } else if (status == 'aktif') {
          result.add(AppNotification(
            id: 'jadwal_aktif_${mapel}',
            type: NotifType.jadwal,
            judul: 'Sedang Berlangsung',
            isi: '$mapel — $jam',
            waktu: now,
            isRead: _readIds.contains('jadwal_aktif_${mapel}'),
          ));
        }
      }
    }

    // ── 3. EVENT & PENGUMUMAN dari CMS ──────────
    final cms = CmsService.cache;
    for (final item in cms) {
      final type = item['type'];
      final data = item['data'] as Map<String, dynamic>? ?? {};

      if (type == 'event') {
        final id = 'event_${data['id'] ?? item.hashCode}';
        result.add(AppNotification(
          id: id,
          type: NotifType.event,
          judul: data['judul'] ?? 'Event Sekolah',
          isi: _formatTanggalCms(data['tanggal_mulai']),
          waktu: _parseDate(data['tanggal_mulai']) ?? now,
          isRead: _readIds.contains(id),
        ));
      } else if (type == 'pengumuman') {
        final id = 'pengumuman_${data['id'] ?? item.hashCode}';
        result.add(AppNotification(
          id: id,
          type: NotifType.pengumuman,
          judul: data['judul'] ?? 'Pengumuman',
          isi: data['isi'] ?? '',
          waktu: _parseDate(data['created_at']) ?? now,
          isRead: _readIds.contains(id),
        ));
      }
    }

    // Sort: unread dulu, lalu by waktu
    result.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.waktu.compareTo(a.waktu);
    });

    _notifications = result;
    if (!_controller.isClosed) {
      _controller.add(_notifications);
    }
  }

  void _buildAbsensiNotif(List<AppNotification> result, DateTime now) {
    // Kita tidak punya akses langsung ke last state,
    // jadi pakai AbsensiRealtimeService lewat stream terakhir
    // Untuk initial state, cek dari StudentDataCache atau flag
    // Implementasi: kita expose lastState dari AbsensiRealtimeService
    final lastState = AbsensiRealtimeService.lastState;
    if (lastState == null) return;

    final raw = lastState.raw;
    if (raw == null) return;

    final isLibur = raw['is_libur'] == true;
    if (isLibur) return;

    final data = raw['data'];

    if (data == null) {
      // Belum absen masuk
      result.add(AppNotification(
        id: 'absensi_masuk_${now.day}_${now.month}',
        type: NotifType.absensi,
        judul: 'Belum Absen Masuk',
        isi: 'Jangan lupa absen masuk hari ini',
        waktu: now,
        isRead: _readIds
            .contains('absensi_masuk_${now.day}_${now.month}'),
      ));
    } else if (data['jam_pulang'] == null &&
        data['status'] != 'izin') {
      // Sudah masuk, belum pulang
      result.add(AppNotification(
        id: 'absensi_pulang_${now.day}_${now.month}',
        type: NotifType.absensi,
        judul: 'Belum Absen Pulang',
        isi: 'Jangan lupa absen pulang sebelum meninggalkan sekolah',
        waktu: now,
        isRead: _readIds
            .contains('absensi_pulang_${now.day}_${now.month}'),
      ));
    }
  }

  // ═══════════════════════════════
  // MARK AS READ
  // ═══════════════════════════════
  void markAsRead(String id) {
    _readIds.add(id);
    _notifications = _notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    if (!_controller.isClosed) {
      _controller.add(_notifications);
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      _readIds.add(n.id);
    }
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    if (!_controller.isClosed) {
      _controller.add(_notifications);
    }
  }

  // ═══════════════════════════════
  // HELPERS
  // ═══════════════════════════════
  String _formatTanggalCms(dynamic mulai) {
    if (mulai == null) return '';
    try {
      final dt = DateTime.parse(mulai.toString()).toLocal();
      const bulan = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}';
    } catch (_) {
      return mulai.toString();
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _absensiSub?.cancel();
    _refreshTimer?.cancel();
    _controller.close();
  }
}