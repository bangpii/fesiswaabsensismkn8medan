// ═══════════════════════════════════════════════════════════
// PROFILE MODELS — Data siswa dari backend + dummy untuk
// fitur yang belum tersedia (absensi, tabungan)
// ═══════════════════════════════════════════════════════════

enum JenisKelamin { lakiLaki, perempuan }

// ── Data Siswa (dari backend: student + user + class + department) ──

class DataSiswa {
  final String namaLengkap;
  final String nisn;
  final String nis;
  final String kelas;
  final String jurusan;
  final JenisKelamin jenisKelamin;
  final String? fotoUrl;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? agama;
  final String? namaOrangtua;
  final String? noHpOrangtua;
  final String? email;
  final String? tingkat; // X, XI, XII

  const DataSiswa({
    required this.namaLengkap,
    required this.nisn,
    required this.nis,
    required this.kelas,
    required this.jurusan,
    required this.jenisKelamin,
    this.fotoUrl,
    this.tempatLahir,
    this.tanggalLahir,
    this.agama,
    this.namaOrangtua,
    this.noHpOrangtua,
    this.email,
    this.tingkat,
  });

  /// Inisial: ambil huruf pertama setiap kata, maksimal 2 huruf
  String get inisial {
    final parts = namaLengkap.trim().split(' ');
    if (parts.isEmpty) return '?';
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String get labelKelamin =>
      jenisKelamin == JenisKelamin.lakiLaki ? 'Laki-laki' : 'Perempuan';

  /// Factory dari raw backend response
  factory DataSiswa.fromBackend(Map<String, dynamic> raw) {
    final student   = _inner(raw, 'student');
    final user      = _inner(raw, 'user');
    final kelasMap  = _inner(raw, 'class');
    final deptMap   = _inner(raw, 'department');

    final nama = _str(student['name']) ?? _str(user['name']) ?? 'Pengguna';

    final nisn = _str(student['nisn']) ??
        _str(student['nis']) ??
        _str(user['nisn']) ??
        '-';

    final nis = _str(student['nis']) ?? _str(student['nisn']) ?? '-';

    final kelas = _str(kelasMap['name']) ??
        _str(student['student_class']?['name']) ??
        '-';

    final jurusan = _str(deptMap['name']) ??
        _str(student['department']?['name']) ??
        '-';

    final jk = (_str(student['jenis_kelamin']) ?? 'L').toUpperCase();

    final foto = _str(student['photo']) ?? _str(user['photo']);

    final tingkat = _str(kelasMap['tingkat']?['name']) ??
        _str(student['student_class']?['tingkat']?['name']);

    return DataSiswa(
      namaLengkap  : nama,
      nisn         : nisn,
      nis          : nis,
      kelas        : kelas,
      jurusan      : jurusan,
      jenisKelamin : jk == 'P' ? JenisKelamin.perempuan : JenisKelamin.lakiLaki,
      fotoUrl      : foto,
      tempatLahir  : _str(student['tempat_lahir']),
      tanggalLahir : _str(student['tanggal_lahir']),
      agama        : _str(student['agama']),
      namaOrangtua : _str(student['nama_orangtua']),
      noHpOrangtua : _str(student['no_hp_orangtua']),
      email        : _str(student['email']) ?? _str(user['email']),
      tingkat      : tingkat,
    );
  }

  static Map<String, dynamic> _inner(Map<String, dynamic> raw, String key) {
    final v = raw[key];
    return (v is Map<String, dynamic>) ? v : {};
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

// ── Data Nilai dari nilai_ujian (backend) ───────────────────

class DataNilai {
  final String mapel;
  final double nilai;
  final String grade;
  final String? quizTitle;

  // 🆕 Field baru: status lulus/tidak lulus dari backend
  final bool isPassed;

  const DataNilai({
    required this.mapel,
    required this.nilai,
    required this.grade,
    this.quizTitle,
    this.isPassed = false,
  });

  /// Hitung grade dari angka nilai
  static String hitungGrade(double nilai) {
    if (nilai >= 90) return 'A';
    if (nilai >= 85) return 'A-';
    if (nilai >= 80) return 'B+';
    if (nilai >= 75) return 'B';
    if (nilai >= 70) return 'B-';
    if (nilai >= 65) return 'C+';
    if (nilai >= 60) return 'C';
    return 'D';
  }
}

// ── Data Kehadiran Bulan (belum dari backend, pakai dummy dulu) ──

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
      '',
      'Januari', 'Februari', 'Maret',    'April',    'Mei',      'Juni',
      'Juli',    'Agustus',  'September', 'Oktober',  'November', 'Desember'
    ];
    return bulan >= 1 && bulan <= 12 ? bulanList[bulan] : '-';
  }
}

// ── Data Tabungan (belum dari backend, pakai dummy dulu) ──

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
    final s      = jumlah.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }
}

// ══════════════════════════════════════════════════════════
// DUMMY FALLBACK
// ══════════════════════════════════════════════════════════

DataSiswa buatDummySiswa() {
  return const DataSiswa(
    namaLengkap  : 'Pengguna',
    nisn         : '-',
    nis          : '-',
    kelas        : '-',
    jurusan      : '-',
    jenisKelamin : JenisKelamin.lakiLaki,
  );
}

DataKehadiranBulan buatDummyKehadiran() {
  final now = DateTime.now();
  final minggu = ((now.day - 1) ~/ 7) + 1;
  return DataKehadiranBulan(
    bulan             : now.month,
    tahun             : now.year,
    mingguKe          : minggu.clamp(1, 5),
    totalHadir        : 0,
    totalIzin         : 0,
    totalTerlambat    : 0,
    totalHariEfektif  : 0,
  );
}

List<DataNilai> buatDummyNilai() => [];

DataTabungan buatDummyTabungan() {
  return const DataTabungan(
    label         : 'Saldo Tabungan',
    jumlah        : 0,
    tanggalUpdate : '-',
  );
}