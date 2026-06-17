// ═══════════════════════════════════════════════════════════
// MAIL MODELS — Data classes dari API backend (izin + pesans)
// ═══════════════════════════════════════════════════════════

enum IzinStatus { pending, disetujui, ditolak }
enum IzinJenis { izin, sakit, lainnya }
enum SenderType { siswa, admin }

class IzinModel {
  final int id;
  final int userId;
  final String namaLengkap;
  final String nisn;
  final String kelas;
  final String jurusan;
  final String tanggalIzin;
  final IzinJenis jenisIzin;
  final String keterangan;
  final IzinStatus status;
  final List<IzinPesanModel> pesans;

  IzinModel({
    required this.id,
    required this.userId,
    required this.namaLengkap,
    required this.nisn,
    required this.kelas,
    required this.jurusan,
    required this.tanggalIzin,
    required this.jenisIzin,
    required this.keterangan,
    required this.status,
    required this.pesans,
  });

  factory IzinModel.fromJson(Map<String, dynamic> json) {
    final pesanList = (json['pesans'] as List<dynamic>? ?? [])
        .map((p) => IzinPesanModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return IzinModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      nisn: json['nisn']?.toString() ?? '',
      kelas: json['kelas'] ?? '',
      jurusan: json['jurusan'] ?? '',
tanggalIzin: json['tanggal_izin'] != null
    ? DateTime.parse(json['tanggal_izin'])
        .toLocal()
        .toString()
        .split(' ')
        .first
    : '',
      jenisIzin: _parseJenis(json['jenis_izin']),
      keterangan: json['keterangan'] ?? '',
      status: _parseStatus(json['status']),
      pesans: pesanList,
    );
  }

  static IzinStatus _parseStatus(String? s) {
    switch (s) {
      case 'disetujui': return IzinStatus.disetujui;
      case 'ditolak': return IzinStatus.ditolak;
      default: return IzinStatus.pending;
    }
  }

  static IzinJenis _parseJenis(String? j) {
    switch (j) {
      case 'sakit': return IzinJenis.sakit;
      case 'lainnya': return IzinJenis.lainnya;
      default: return IzinJenis.izin;
    }
  }

  int get unreadCount => pesans.where((p) => !p.isRead && p.senderType != SenderType.siswa).length;

  IzinPesanModel? get lastPesan => pesans.isNotEmpty ? pesans.last : null;

  String get statusLabel {
    switch (status) {
      case IzinStatus.disetujui: return 'Disetujui';
      case IzinStatus.ditolak: return 'Ditolak';
      case IzinStatus.pending: return 'Menunggu';
    }
  }

  String get jenisLabel {
    switch (jenisIzin) {
      case IzinJenis.sakit: return 'Sakit';
      case IzinJenis.lainnya: return 'Lainnya';
      case IzinJenis.izin: return 'Izin';
    }
  }
}

class IzinPesanModel {
  final int id;
  final int izinId;
  final int senderId;
  final SenderType senderType;
  final String pesan;
  bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  IzinPesanModel({
    required this.id,
    required this.izinId,
    required this.senderId,
    required this.senderType,
    required this.pesan,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory IzinPesanModel.fromJson(Map<String, dynamic> json) {
    return IzinPesanModel(
      id: json['id'] ?? 0,
      izinId: json['izin_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderType: json['sender_type'] == 'admin'
          ? SenderType.admin
          : SenderType.siswa,
      pesan: json['pesan'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
    readAt: json['read_at'] != null
        ? DateTime.parse(json['read_at']).toLocal()
        : null,
      createdAt: json['created_at'] != null
    ? DateTime.parse(json['created_at']).toLocal()
    : DateTime.now(),
    );
  }

  bool get dariSiswa => senderType == SenderType.siswa;
}