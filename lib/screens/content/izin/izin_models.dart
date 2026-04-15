// ═══════════════════════════════════════════════════════════
// IZIN MODELS — Data class & enum untuk halaman Izin
// ═══════════════════════════════════════════════════════════

enum JenisIzin { sakit, keperluan, keluarga, lainnya }

enum StatusIzin { menunggu, disetujui, ditolak }

class RiwayatIzin {
  final String id;
  final DateTime tanggal;
  final JenisIzin jenis;
  final String keterangan;
  final StatusIzin status;
  final String namaPenerima;

  const RiwayatIzin({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.keterangan,
    required this.status,
    required this.namaPenerima,
  });
}

extension JenisIzinExt on JenisIzin {
  String get label {
    switch (this) {
      case JenisIzin.sakit:
        return 'Sakit';
      case JenisIzin.keperluan:
        return 'Keperluan';
      case JenisIzin.keluarga:
        return 'Keluarga';
      case JenisIzin.lainnya:
        return 'Lainnya';
    }
  }
}

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
}

List<RiwayatIzin> buatDummyRiwayatIzin() {
  return [
    RiwayatIzin(
      id: '1',
      tanggal: DateTime.now().subtract(const Duration(days: 1)),
      jenis: JenisIzin.sakit,
      keterangan: 'Demam dan tidak bisa hadir ke sekolah',
      status: StatusIzin.disetujui,
      namaPenerima: 'Bu Rahma',
    ),
    RiwayatIzin(
      id: '2',
      tanggal: DateTime.now().subtract(const Duration(days: 4)),
      jenis: JenisIzin.keperluan,
      keterangan: 'Ada urusan keluarga mendadak',
      status: StatusIzin.menunggu,
      namaPenerima: 'Pak Budi',
    ),
    RiwayatIzin(
      id: '3',
      tanggal: DateTime.now().subtract(const Duration(days: 10)),
      jenis: JenisIzin.keluarga,
      keterangan: 'Menghadiri acara pernikahan saudara',
      status: StatusIzin.ditolak,
      namaPenerima: 'Bu Sari',
    ),
  ];
}