import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// MODELS — Data structures untuk Absensi
// ═══════════════════════════════════════════════════════════

enum StatusAbsensi {
  belumAbsen,
  sudahMasuk,
  sudahPulang,
}

extension StatusAbsensiExt on StatusAbsensi {
  String get label {
    switch (this) {
      case StatusAbsensi.belumAbsen:
        return 'Belum Absen';
      case StatusAbsensi.sudahMasuk:
        return 'Sudah Masuk';
      case StatusAbsensi.sudahPulang:
        return 'Sudah Pulang';
    }
  }

  String get labelTombol {
    switch (this) {
      case StatusAbsensi.belumAbsen:
        return 'Absen Masuk';
      case StatusAbsensi.sudahMasuk:
        return 'Absen Pulang';
      case StatusAbsensi.sudahPulang:
        return 'Selesai Hari Ini';
    }
  }

  Color get warna {
    switch (this) {
      case StatusAbsensi.belumAbsen:
        return const Color(0xFF1D4ED8);
      case StatusAbsensi.sudahMasuk:
        return const Color(0xFF16A34A);
      case StatusAbsensi.sudahPulang:
        return const Color(0xFF7C3AED);
    }
  }

  Color get warnaLatar {
    switch (this) {
      case StatusAbsensi.belumAbsen:
        return const Color(0xFFEFF6FF);
      case StatusAbsensi.sudahMasuk:
        return const Color(0xFFF0FDF4);
      case StatusAbsensi.sudahPulang:
        return const Color(0xFFF5F3FF);
    }
  }

  IconData get ikon {
    switch (this) {
      case StatusAbsensi.belumAbsen:
        return Icons.camera_alt_rounded;
      case StatusAbsensi.sudahMasuk:
        return Icons.login_rounded;
      case StatusAbsensi.sudahPulang:
        return Icons.check_circle_rounded;
    }
  }
}

// ─── Model Riwayat ────────────────────────────────────────
class RiwayatAbsensi {
  final String tanggal;
  final String hari;
  final String jamMasuk;
  final String jamPulang;
  final StatusKehadiran statusKehadiran;

  const RiwayatAbsensi({
    required this.tanggal,
    required this.hari,
    required this.jamMasuk,
    required this.jamPulang,
    required this.statusKehadiran,
  });
}

enum StatusKehadiran { hadir, terlambat, izin, alpa }

extension StatusKehadiranExt on StatusKehadiran {
  String get label {
    switch (this) {
      case StatusKehadiran.hadir:
        return 'Hadir';
      case StatusKehadiran.terlambat:
        return 'Terlambat';
      case StatusKehadiran.izin:
        return 'Izin';
      case StatusKehadiran.alpa:
        return 'Alpa';
    }
  }

  Color get warna {
    switch (this) {
      case StatusKehadiran.hadir:
        return const Color(0xFF16A34A);
      case StatusKehadiran.terlambat:
        return const Color(0xFFF59E0B);
      case StatusKehadiran.izin:
        return const Color(0xFF0891B2);
      case StatusKehadiran.alpa:
        return const Color(0xFFDC2626);
    }
  }

  Color get warnaLatar {
    switch (this) {
      case StatusKehadiran.hadir:
        return const Color(0xFFF0FDF4);
      case StatusKehadiran.terlambat:
        return const Color(0xFFFFFBEB);
      case StatusKehadiran.izin:
        return const Color(0xFFECFEFF);
      case StatusKehadiran.alpa:
        return const Color(0xFFFEF2F2);
    }
  }

  IconData get ikon {
    switch (this) {
      case StatusKehadiran.hadir:
        return Icons.check_circle_rounded;
      case StatusKehadiran.terlambat:
        return Icons.schedule_rounded;
      case StatusKehadiran.izin:
        return Icons.description_rounded;
      case StatusKehadiran.alpa:
        return Icons.cancel_rounded;
    }
  }
}

// ─── Dummy Data ───────────────────────────────────────────
List<RiwayatAbsensi> buatDummyRiwayat() {
  return [
    const RiwayatAbsensi(
      tanggal: '09 Apr 2025',
      hari: 'Rabu',
      jamMasuk: '07:12',
      jamPulang: '15:30',
      statusKehadiran: StatusKehadiran.hadir,
    ),
    const RiwayatAbsensi(
      tanggal: '08 Apr 2025',
      hari: 'Selasa',
      jamMasuk: '07:45',
      jamPulang: '15:28',
      statusKehadiran: StatusKehadiran.terlambat,
    ),
    const RiwayatAbsensi(
      tanggal: '07 Apr 2025',
      hari: 'Senin',
      jamMasuk: '—',
      jamPulang: '—',
      statusKehadiran: StatusKehadiran.izin,
    ),
    const RiwayatAbsensi(
      tanggal: '04 Apr 2025',
      hari: 'Jumat',
      jamMasuk: '07:05',
      jamPulang: '15:35',
      statusKehadiran: StatusKehadiran.hadir,
    ),
    const RiwayatAbsensi(
      tanggal: '03 Apr 2025',
      hari: 'Kamis',
      jamMasuk: '—',
      jamPulang: '—',
      statusKehadiran: StatusKehadiran.alpa,
    ),
    const RiwayatAbsensi(
      tanggal: '02 Apr 2025',
      hari: 'Rabu',
      jamMasuk: '07:08',
      jamPulang: '15:30',
      statusKehadiran: StatusKehadiran.hadir,
    ),
  ];
}