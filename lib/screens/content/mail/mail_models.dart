// ═══════════════════════════════════════════════════════════
// MAIL MODELS — Data classes & enums
// ═══════════════════════════════════════════════════════════

enum SenderRole { guru, admin, waliKelas }

class MailMessage {
  final String id;
  final String senderName;
  final String senderInitials;
  final SenderRole senderRole;
  final String subject;
  final String preview;
  final DateTime waktu;
  bool dibaca;
  final List<MailReply> balasan;

  MailMessage({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.senderRole,
    required this.subject,
    required this.preview,
    required this.waktu,
    required this.dibaca,
    required this.balasan,
  });
}

class MailReply {
  final String id;
  final String pengirim;
  final String inisial;
  final String isi;
  final DateTime waktu;
  final bool dariku;

  MailReply({
    required this.id,
    required this.pengirim,
    required this.inisial,
    required this.isi,
    required this.waktu,
    required this.dariku,
  });
}

// ── Dummy Data Factory ────────────────────────────────────
List<MailMessage> buatDataDummyMail() {
  return [
    MailMessage(
      id: '1',
      senderName: 'Pak Rizky Pratama',
      senderInitials: 'RP',
      senderRole: SenderRole.guru,
      subject: 'Tugas Akhir — Deadline Dipercepat',
      preview:
          'Halo Baihaqie, saya ingin menginformasikan bahwa deadline pengumpulan tugas akhir semester untuk mata pelajaran Pemrograman Berorientasi Objek dipercepat menjadi 25 Mei 2025. Pastikan project kamu sudah mencakup: class diagram, implementasi inheritance, dan dokumentasi kode yang lengkap.',
      waktu: DateTime.now().subtract(const Duration(hours: 1)),
      dibaca: false,
      balasan: [
        MailReply(
          id: 'r1a',
          pengirim: 'Baihaqie Ar Rafi',
          inisial: 'BA',
          isi: 'Baik, Pak. Terima kasih informasinya. Saya sudah 80% selesai. Untuk dokumentasi apakah perlu dalam format PDF?',
          waktu: DateTime.now().subtract(const Duration(hours: 1)),
          dariku: true,
        ),
        MailReply(
          id: 'r1b',
          pengirim: 'Pak Rizky Pratama',
          inisial: 'RP',
          isi: 'Iya, format PDF sudah cukup. Nama file: NamaLengkap_TugasAkhirPBO_2025.pdf. Semangat ya!',
          waktu: DateTime.now().subtract(const Duration(minutes: 45)),
          dariku: false,
        ),
      ],
    ),
    MailMessage(
      id: '2',
      senderName: 'Admin Sekolah',
      senderInitials: 'AD',
      senderRole: SenderRole.admin,
      subject: 'Pengumuman Jadwal UAS 2024/2025',
      preview:
          'Kepada seluruh siswa SMKN 8 Medan, berikut adalah jadwal Ujian Akhir Semester (UAS) Genap Tahun Pelajaran 2024/2025:\n\nPelaksanaan: 3–14 Juni 2025\nJam masuk: 07.00 WIB\nWajib membawa kartu ujian yang sah.\n\nJadwal lengkap per mata pelajaran dapat diunduh di papan pengumuman digital sekolah.',
      waktu: DateTime.now().subtract(const Duration(hours: 2)),
      dibaca: false,
      balasan: [],
    ),
    MailMessage(
      id: '3',
      senderName: 'Bu Sari Indah',
      senderInitials: 'SI',
      senderRole: SenderRole.guru,
      subject: 'Nilai Tugas Praktikum Basis Data',
      preview:
          'Baihaqie, nilai tugas praktikum Basis Data kamu sudah saya input ke sistem. Selamat, hasilnya sangat memuaskan! Nilai kamu 92/100.',
      waktu: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      dibaca: true,
      balasan: [
        MailReply(
          id: 'r3a',
          pengirim: 'Baihaqie Ar Rafi',
          inisial: 'BA',
          isi: 'Terima kasih banyak, Bu Sari! Senang sekali mendengarnya. Saya akan terus belajar lebih giat lagi.',
          waktu: DateTime.now()
              .subtract(const Duration(days: 1, hours: 2, minutes: 30)),
          dariku: true,
        ),
        MailReply(
          id: 'r3b',
          pengirim: 'Bu Sari Indah',
          inisial: 'SI',
          isi: 'Bagus! Pertahankan ya. Untuk UAS, fokus di bagian normalisasi dan query JOIN yang kompleks.',
          waktu: DateTime.now()
              .subtract(const Duration(days: 1, hours: 2)),
          dariku: false,
        ),
      ],
    ),
    MailMessage(
      id: '4',
      senderName: 'Bu Dewi Kartika',
      senderInitials: 'BK',
      senderRole: SenderRole.waliKelas,
      subject: 'Rekap Absensi Bulan April',
      preview:
          'Halo Baihaqie, rekap absensi bulan April sudah selesai diproses.\n\nHadir: 22 hari\nSakit: 0\nIzin: 0\nAlpha: 0\n\nAlhamdulillah sempurna! Pertahankan presensi yang baik ini ya.',
      waktu: DateTime.now().subtract(const Duration(days: 3)),
      dibaca: true,
      balasan: [],
    ),
    MailMessage(
      id: '5',
      senderName: 'Pak Ahmad Fauzi',
      senderInitials: 'AF',
      senderRole: SenderRole.guru,
      subject: 'Materi Tambahan Matematika — Bab Integral',
      preview:
          'Halo kelas! Saya lampirkan modul tambahan Bab Integral untuk persiapan UAS. Pelajari soal latihan di halaman 45–60. Ada yang ingin didiskusikan, silakan balas pesan ini.',
      waktu: DateTime.now().subtract(const Duration(days: 5)),
      dibaca: true,
      balasan: [],
    ),
    MailMessage(
      id: '6',
      senderName: 'Admin Sekolah',
      senderInitials: 'AD',
      senderRole: SenderRole.admin,
      subject: 'Peraturan Seragam Sekolah Baru',
      preview:
          'Mulai 1 Juni 2025 berlaku peraturan seragam baru. Setiap siswa wajib mengenakan seragam lengkap sesuai ketentuan yang berlaku. Pelanggaran akan dicatat dalam buku tata tertib.',
      waktu: DateTime.now().subtract(const Duration(days: 6)),
      dibaca: true,
      balasan: [],
    ),
  ];
}