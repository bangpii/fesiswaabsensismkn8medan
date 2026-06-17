// ═══════════════════════════════════════════════════════════
// IZIN MODELS — Enum & Model untuk halaman Izin
// ═══════════════════════════════════════════════════════════

enum JenisIzin { sakit, izin, lainnya }

extension JenisIzinExt on JenisIzin {
  String get label {
    switch (this) {
      case JenisIzin.sakit:
        return 'Sakit';
      case JenisIzin.izin:
        return 'Izin';
      case JenisIzin.lainnya:
        return 'Lainnya';
    }
  }

  /// Nilai yang dikirim ke backend API
  String get apiValue {
    switch (this) {
      case JenisIzin.sakit:
        return 'sakit';
      case JenisIzin.izin:
        return 'izin';
      case JenisIzin.lainnya:
        return 'lainnya';
    }
  }

  static JenisIzin fromString(String? v) {
    switch (v) {
      case 'sakit':
        return JenisIzin.sakit;
      case 'izin':
        return JenisIzin.izin;
      case 'lainnya':
        return JenisIzin.lainnya;
      default:
        return JenisIzin.izin;
    }
  }
}

enum StatusIzin { menunggu, disetujui, ditolak }

extension StatusIzinExt on StatusIzin {
  String get label {
    switch (this) {
      case StatusIzin.menunggu:
        return 'Menunggu';
      case StatusIzin.disetujui:
        return 'Disetujui';
      case StatusIzin.ditolak:
        return 'Ditolak';
    }
  }

  static StatusIzin fromString(String? v) {
    switch (v) {
      case 'disetujui':
        return StatusIzin.disetujui;
      case 'ditolak':
        return StatusIzin.ditolak;
      default:
        return StatusIzin.menunggu;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Model dari response backend
// ─────────────────────────────────────────────────────────

class RiwayatIzin {
  final int id;
  final String namaLengkap;
  final String? nisn;
  final String? kelas;
  final String? jurusan;
  final DateTime tanggalIzin;
  final JenisIzin jenisIzin;
  final String? keterangan;
  final StatusIzin status;
  final DateTime? disetujuiPada;
  final DateTime createdAt;

  const RiwayatIzin({
    required this.id,
    required this.namaLengkap,
    this.nisn,
    this.kelas,
    this.jurusan,
    required this.tanggalIzin,
    required this.jenisIzin,
    this.keterangan,
    required this.status,
    this.disetujuiPada,
    required this.createdAt,
  });

  factory RiwayatIzin.fromJson(Map<String, dynamic> json) {
    return RiwayatIzin(
      id: json['id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      nisn: json['nisn'],
      kelas: json['kelas'],
      jurusan: json['jurusan'],
      tanggalIzin: DateTime.tryParse(json['tanggal_izin'] ?? '')?.toLocal() ?? DateTime.now(),
      jenisIzin:
          JenisIzinExt.fromString(json['jenis_izin']),
      keterangan: json['keterangan'],
      status: StatusIzinExt.fromString(json['status']),
      disetujuiPada: json['disetujui_pada'] != null
          ? DateTime.tryParse(json['disetujui_pada'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.now(),
    );
  }
}

/// Dummy data sudah tidak diperlukan karena data realtime dari backend
List<RiwayatIzin> buatDummyRiwayatIzin() => [];