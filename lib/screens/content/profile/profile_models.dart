// ═══════════════════════════════════════════════════════════
// PROFILE MODELS — Data siswa & kehadiran
// ═══════════════════════════════════════════════════════════

enum JenisKelamin { lakiLaki, perempuan }

class DataSiswa {
  final String namaLengkap;
  final String nisn;
  final String nis;
  final String kelas;
  final String jurusan;
  final JenisKelamin jenisKelamin;
  final String? fotoUrl;

  const DataSiswa({
    required this.namaLengkap,
    required this.nisn,
    required this.nis,
    required this.kelas,
    required this.jurusan,
    required this.jenisKelamin,
    this.fotoUrl,
  });

  String get inisial {
    final parts = namaLengkap.trim().split(' ');
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : '?';
  }

  String get labelKelamin =>
      jenisKelamin == JenisKelamin.lakiLaki ? 'Laki-laki' : 'Perempuan';
}

class DataKehadiranBulan {
  final int bulan;
  final int tahun;
  final int mingguKe;
  final int totalHadir;
  final int totalIzin;
  final int totalTerlambat;
  final int totalHariEfektif;

  const DataKehadiranBulan({
    required this.bulan,
    required this.tahun,
    required this.mingguKe,
    required this.totalHadir,
    required this.totalIzin,
    required this.totalTerlambat,
    required this.totalHariEfektif,
  });

  String get namaBulan {
    const bulanList = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return bulan >= 1 && bulan <= 12 ? bulanList[bulan] : '-';
  }
}

class DataNilai {
  final String mapel;
  final double nilai;
  final String grade;

  const DataNilai({
    required this.mapel,
    required this.nilai,
    required this.grade,
  });
}

class DataTabungan {
  final String label;
  final int jumlah;
  final String tanggalUpdate;

  const DataTabungan({
    required this.label,
    required this.jumlah,
    required this.tanggalUpdate,
  });

  String get formatRupiah {
    final s = jumlah.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }
}

// ── Dummy data ───────────────────────────────────────────

DataSiswa buatDummySiswa() {
  return const DataSiswa(
    namaLengkap: 'Baihaqie Ar Rafi',
    nisn: '0087654321',
    nis: '2324001',
    kelas: 'XI RPL 1',
    jurusan: 'Rekayasa Perangkat Lunak',
    jenisKelamin: JenisKelamin.lakiLaki,
  );
}

DataKehadiranBulan buatDummyKehadiran() {
  return const DataKehadiranBulan(
    bulan: 4,
    tahun: 2025,
    mingguKe: 3,
    totalHadir: 14,
    totalIzin: 2,
    totalTerlambat: 1,
    totalHariEfektif: 17,
  );
}

List<DataNilai> buatDummyNilai() {
  return const [
    DataNilai(mapel: 'Pemrograman Berorientasi Objek', nilai: 91.5, grade: 'A'),
    DataNilai(mapel: 'Basis Data', nilai: 87.0, grade: 'A'),
    DataNilai(mapel: 'Matematika', nilai: 78.5, grade: 'B+'),
    DataNilai(mapel: 'Bahasa Inggris', nilai: 85.0, grade: 'A'),
    DataNilai(mapel: 'Desain Grafis', nilai: 92.0, grade: 'A'),
  ];
}

DataTabungan buatDummyTabungan() {
  return const DataTabungan(
    label: 'Saldo Tabungan',
    jumlah: 475000,
    tanggalUpdate: '14 Apr 2025',
  );
}