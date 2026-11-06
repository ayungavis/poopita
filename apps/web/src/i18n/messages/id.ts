import { site } from "../../config/site";
import type { Messages } from "./types";

const effective = "Berlaku sejak 4 November 2026";
const privacyEffective = "Berlaku sejak 6 November 2026";

export const id: Messages = {
  common: {
    skipToContent: "Langsung ke konten",
    switchLanguage: "English",
    homeLabel: "Beranda Poopita",
    nav: { privacy: "Privasi", support: "Bantuan", terms: "Ketentuan" },
    document: { inShort: "Singkatnya", onThisPage: "Di halaman ini" },
    darkTheme: "Tema gelap",
    store: {
      download: "Unduh di App Store",
      comingSoon: "Segera hadir di App Store",
    },
    notFound: {
      title: "Halaman tidak ditemukan",
      body: "Halaman ini tidak ada, atau sudah dipindahkan.",
      home: "Ke beranda",
      calendarLabel:
        "Satu minggu di Poopita. Dua hari tidak pernah dicatat, jadi tampil sebagai tidak diketahui.",
      note: "Hari bergaris tidak dicatat, jadi Poopita menampilkannya sebagai tidak diketahui, bukan nol. Halaman ini salah satunya.",
    },
    footer: {
      tagline: "Catatan Anda tidak pernah keluar dari iPhone Anda.",
      source: "Kode sumber",
      madeBy: "Dibuat di Indonesia oleh",
      writeTo: "Pertanyaan, bug, atau ide",
      openSource: `Sumber terbuka dengan lisensi ${site.licenseName}`,
      trademark: "Apple, logo Apple, iPhone, dan App Store adalah merek dagang Apple Inc.",
      copyright: `© 2026 ${site.owner}`,
    },
  },
  landing: {
    meta: {
      title: "Poopita — Catatan BAB pribadi untuk iPhone",
      description:
        "Catat setiap BAB dalam hitungan detik, lihat rutinitas Anda terbentuk, dan jaga tetap pribadi. Tanpa akun, tanpa iklan, dan catatan Anda tetap di iPhone.",
    },
    hero: {
      title: "Catatan pribadi untuk rutinitas BAB Anda.",
      lead: "Catat setiap BAB dalam hitungan detik. Dalam beberapa minggu Anda akan melihat pola biasa Anda, dan kapan polanya berubah. Semuanya tetap di iPhone Anda.",
      trust: ["Tanpa akun", "Tetap di iPhone Anda", "Tanpa iklan atau pelacakan"],
      iconAlt: "Ikon aplikasi Poopita",
      calendarLabel:
        "Contoh bulan Oktober di Poopita: sebagian besar hari berisi gambar tipe tinja, tiga hari dikonfirmasi tidak BAB, empat hari tidak pernah dicatat dan tetap diarsir, dan hari ini masih terbuka.",
      seeHow: "Lihat cara kerjanya",
    },
    log: {
      title: "Catat dalam hitungan detik",
      body: "Pilih tipe Bristol, jumlahnya, seberapa sulit rasanya, dan ada tidaknya darah. Itu sudah satu catatan lengkap. Tambahkan warna, lama di toilet, atau catatan singkat jika mau.",
      sample: {
        time: "Selasa, 14 Oktober, 07.42",
        fields: [
          { label: "Jenis", value: "4 · halus dan lunak" },
          { label: "Jumlah", value: "Sedang" },
          { label: "Usaha", value: "Mudah" },
          { label: "Darah", value: "Tidak ada darah" },
        ],
      },
    },
    days: {
      title: "Tidak diketahui bukan berarti nol",
      body: "Di hari Anda tidak BAB, catat dengan satu ketukan. Hari yang tidak dicatat tetap tidak diketahui, jadi riwayat Anda tidak pernah berpura-pura tahu lebih dari yang Anda catat.",
      comparison: {
        plainLabel: "Penghitung biasa",
        poopitaLabel: "Poopita",
        rows: [
          { situation: "Hari Anda lupa mencatat", plain: "Dihitung 0", poopita: "Tetap tidak diketahui" },
          {
            situation: "Hari Anda tidak BAB",
            plain: "Sama seperti lupa",
            poopita: "Dikonfirmasi dengan satu ketukan",
          },
          { situation: "Hari ini, sebelum BAB", plain: "Sudah 0", poopita: "Belum BAB" },
        ],
      },
    },
    insights: {
      title: "Lihat apa yang biasa bagi Anda",
      body: "Seberapa sering, seberapa konsisten, dan seberapa nyaman, per minggu, bulan, atau tahun, serta apa yang berbeda dari biasanya. Tanpa skor, tanpa streak. Saat perlu, ekspor PDF untuk dokter Anda.",
      average: "1,2",
      averageLabel: "catatan per hari, pada hari Anda mencatat",
      consistency: { title: "Konsistensi", hard: "Keras 1–2", usual: "Biasa 3–5", loose: "Lembek 6–7" },
    },
    reminders: {
      title: "Satu pengingat yang tenang",
      body: 'Cek harian hanya di hari Anda belum mencatat. Notifikasinya hanya bertuliskan "Cek cepat", jadi orang yang ikut melihat layar Anda tidak tahu untuk apa.',
      notificationTitle: "Cek cepat",
      notificationBody: "Belum ada catatan hari ini. Ketuk untuk mencatat, atau tahan untuk opsi lain.",
    },
    privacy: {
      title: "BAB Anda, urusan Anda.",
      lead: "Poopita dibuat agar tidak ada yang melihat catatan Anda selain Anda. Bukan kami, bukan pengiklan, bukan cloud.",
      items: [
        {
          title: "Tetap di iPhone ini",
          body: "Catatan Anda disimpan di iPhone. Tidak ada server dan tidak ada akun. Cadangan iCloud bersifat opsional dan dienkripsi sebelum keluar dari ponsel.",
        },
        { title: "Tanpa akun", body: "Tidak perlu mendaftar, tanpa email, tanpa kata sandi." },
        {
          title: "Terkunci saat Anda mau",
          body: "Kunci Poopita dengan Face ID, Touch ID, atau kode sandi, dan sembunyikan di pengalih aplikasi.",
        },
        {
          title: "Hanya laporan crash anonim",
          body: "Jika aplikasi crash, aplikasi dapat mengirim laporan teknis tanpa isi catatan dan tanpa apa pun yang mengidentifikasi Anda.",
        },
      ],
      policyLink: "Baca kebijakan privasi",
      sourceLink: "Periksa kode sumbernya",
    },
    why: {
      title: "Kenapa perlu mencatat BAB?",
      items: [
        {
          title: "Kenali pola normal Anda",
          body: "Normal setiap orang berbeda. Catatan beberapa minggu menunjukkan seperti apa normal Anda.",
        },
        {
          title: "Sadari perubahan",
          body: "Perubahan setelah makanan baru, obat, perjalanan, atau stres lebih mudah terlihat jika dicatat.",
        },
        {
          title: "Bawa fakta, bukan tebakan",
          body: "Saat dokter bertanya seberapa sering dan sejak kapan, Anda punya jawabannya, lengkap dengan PDF untuk ditunjukkan.",
        },
      ],
      note: "Temui dokter jika tinja berdarah atau berwarna hitam, merah, atau pucat, atau jika ada perubahan yang tidak kunjung membaik.",
    },
    limits: {
      title: "Batasan yang jujur",
      items: [
        "Poopita adalah catatan pribadi, bukan alat medis. Aplikasi ini tidak mendiagnosis atau mengobati apa pun. Jika ada yang mengkhawatirkan, bicarakan dengan dokter.",
        "Cadangan hanya dibuat jika Anda menyalakannya atau menyimpannya sendiri. Menghapus aplikasi berarti menghapus catatan, kecuali Anda punya cadangan Poopita atau cadangan iPhone, dan kunci pemulihan yang hilang tidak bisa diganti.",
      ],
    },
    faq: {
      title: "Pertanyaan",
      items: [
        {
          question: "Apakah gratis?",
          answer: ["Ya. Tanpa iklan, tanpa langganan, dan tanpa pembelian dalam aplikasi."],
        },
        {
          question: "Apakah pribadi?",
          answer: [
            "Catatan Anda tetap di iPhone. Aplikasi hanya mengirim laporan crash anonim, tanpa isi catatan. Jika Anda menyalakan cadangan iCloud, salinan terenkripsi disimpan di iCloud Drive Anda sendiri, dan hanya kunci pemulihan Anda yang bisa membukanya.",
          ],
        },
        { question: "Apakah perlu akun?", answer: ["Tidak. Buka aplikasinya dan mulai mencatat."] },
        {
          question: "Apa itu skala Bristol?",
          answer: [
            "Bagan yang membagi tinja menjadi tujuh tipe berdasarkan bentuk, dari gumpalan keras (tipe 1) sampai cair (tipe 7). Pilih yang paling mendekati; tidak perlu persis.",
          ],
        },
        {
          question: "Bagaimana jika ponsel saya hilang?",
          answer: [
            "Pulihkan dari cadangan iCloud atau berkas dengan kunci pemulihan Anda. Tanpa cadangan Poopita atau cadangan iPhone, catatan ikut hilang. Kami tidak pernah punya salinannya.",
          ],
        },
      ],
      more: "Jawaban lain di halaman bantuan",
    },
    closing: {
      statement: "Catatan yang hanya tahu apa yang Anda catat, dan menyimpannya untuk Anda sendiri.",
    },
  },
  privacy: {
    meta: {
      title: "Kebijakan privasi — Poopita",
      description:
        "Poopita menyimpan catatan Anda di iPhone. Baca apa yang tetap di perangkat, laporan crash anonim yang dapat dikirim aplikasi, dan hak Anda.",
    },
    title: "Kebijakan privasi",
    effective: privacyEffective,
    summary: [
      "Catatan Anda tetap di iPhone. Kami tidak pernah melihatnya.",
      "Tanpa akun, tanpa iklan, dan tanpa pelacakan.",
      "Aplikasi dapat mengirim laporan crash anonim agar kami bisa memperbaiki bug. Laporan itu tidak berisi catatan Anda.",
    ],
    sections: [
      {
        id: "who-we-are",
        heading: "Siapa kami",
        paragraphs: [
          `Poopita dibuat oleh ${site.owner}, pengembang perorangan di Indonesia ("kami"). Untuk apa pun tentang kebijakan ini, kirim email ke ${site.supportEmail}.`,
        ],
      },
      {
        id: "on-your-device",
        heading: "Yang tetap di perangkat Anda",
        paragraphs: [
          "Semua yang Anda masukkan ke Poopita tetap di iPhone Anda: catatan, konfirmasi tidak BAB, catatan singkat, pengingat, serta pengaturan kunci dan tampilan. Data itu tidak dikirim ke kami atau ke siapa pun, dan kami tidak dapat melihat, memulihkan, atau menghapusnya untuk Anda.",
          "Ekspor (file CSV dan PDF untuk dokter) dibuat di iPhone Anda dan hanya dikirim ke tempat yang Anda pilih.",
          "Cadangan dienkripsi di iPhone Anda dengan kunci pemulihan yang hanya Anda pegang. Jika Anda menyalakan cadangan iCloud, berkas terenkripsi disimpan di iCloud Drive Anda sendiri; jika tidak, Anda yang memilih tempatnya. Kami tidak pernah menerimanya, dan tanpa kunci itu tidak ada yang bisa membukanya, termasuk kami dan Apple.",
        ],
      },
      {
        id: "what-we-receive",
        heading: "Yang kami terima",
        paragraphs: [
          "Saat Poopita mengalami kegagalan teknis, aplikasi dapat mengirim laporan crash. Laporan berisi kode kesalahan, informasi teknis stack, versi aplikasi, dan waktu. Laporan tidak berisi isi catatan, nama, alamat email, atau pengenal perangkat, dan alamat IP tidak disimpan.",
          "Kami memakai laporan crash hanya untuk menemukan dan memperbaiki bug. Dasar hukumnya adalah kepentingan sah kami agar aplikasi tetap berfungsi.",
        ],
      },
      {
        id: "processor",
        heading: "Siapa yang memprosesnya",
        paragraphs: [
          "Laporan crash diproses untuk kami oleh Sentry (Functional Software, Inc., Amerika Serikat) berdasarkan perjanjian pemrosesan datanya. Data dapat diproses di Amerika Serikat; transfer mengandalkan EU-U.S. Data Privacy Framework dan klausul kontrak standar.",
        ],
        links: [
          { label: "Perjanjian pemrosesan data Sentry", href: site.sentryDpaUrl },
          { label: "Subprosesor Sentry", href: site.sentrySubprocessorsUrl },
        ],
      },
      {
        id: "retention",
        heading: "Berapa lama disimpan",
        paragraphs: [
          `Laporan crash dihapus setelah ${site.crashReportRetentionDays} hari. Data di iPhone Anda ada sampai Anda menghapusnya atau menghapus aplikasinya.`,
        ],
      },
      {
        id: "what-we-dont-do",
        heading: "Yang tidak kami lakukan",
        bullets: [
          "Tanpa akun dan tanpa login.",
          "Tanpa iklan dan tanpa pelacakan lintas aplikasi atau situs web.",
          "Tidak menjual atau membagikan data.",
          "Tidak memakai informasi kesehatan untuk pemasaran.",
        ],
        paragraphs: [],
      },
      {
        id: "choices",
        heading: "Pilihan dan hak Anda",
        paragraphs: [
          "Hapus satu catatan dari layar ubahnya, atau semuanya dari Pengaturan › Data Anda › Hapus semua riwayat. Menghapus aplikasi menghapus semua datanya dari iPhone Anda.",
          "Tergantung tempat tinggal Anda (misalnya berdasarkan GDPR atau UU Pelindungan Data Pribadi), Anda dapat meminta akses, perbaikan, atau penghapusan data pribadi, menolak pemrosesan, dan mengadu ke otoritas pelindungan data. Karena laporan crash tidak terhubung ke seseorang, kami biasanya tidak dapat mencocokkan permintaan dengan laporan, tetapi kirimkan email dan kami akan membantu sebisanya.",
        ],
      },
      {
        id: "security",
        heading: "Keamanan",
        paragraphs: [
          "Catatan Anda dilindungi oleh pelindungan data iOS, dan Anda dapat menambahkan kunci Face ID, Touch ID, atau kode sandi serta menyembunyikan aplikasi di pengalih aplikasi. Jika terjadi kebocoran yang memengaruhi Anda, kami akan memberi tahu Anda dan otoritas sesuai hukum, yang di Indonesia paling lambat 3 × 24 jam.",
        ],
      },
      {
        id: "children",
        heading: "Anak-anak",
        paragraphs: ["Poopita tidak ditujukan untuk anak di bawah 13 tahun."],
      },
      {
        id: "website",
        heading: "Situs web ini",
        paragraphs: [
          "Situs web ini tidak memasang cookie dan tidak menjalankan analitik. Situs ini di-hosting di Cloudflare, yang memproses log permintaan standar untuk menayangkan dan melindungi situs.",
        ],
        links: [{ label: "Kebijakan privasi Cloudflare", href: site.cloudflarePrivacyUrl }],
      },
      {
        id: "changes",
        heading: "Perubahan",
        paragraphs: [
          "Kami akan memuat setiap perubahan di sini dengan tanggal berlaku baru, dan menyebutkan perubahan penting di catatan rilis aplikasi.",
        ],
      },
      {
        id: "contact",
        heading: "Kontak",
        paragraphs: [
          `Kirim email ke ${site.supportEmail}. Kebijakan ini diterbitkan dalam bahasa Inggris dan Bahasa Indonesia; bagi pengguna di Indonesia, versi Bahasa Indonesia yang berlaku.`,
        ],
      },
    ],
  },
  terms: {
    meta: {
      title: "Ketentuan penggunaan — Poopita",
      description:
        "Poopita dilisensikan berdasarkan EULA Standar Apple. Poopita adalah catatan pribadi, bukan alat medis.",
    },
    title: "Ketentuan penggunaan",
    effective,
    summary: [
      "Perjanjian Lisensi Standar Apple mengatur aplikasi ini.",
      "Poopita adalah catatan pribadi, bukan alat medis.",
      "Catatan Anda ada di iPhone, jadi menjaganya tetap aman adalah tanggung jawab Anda.",
    ],
    sections: [
      {
        id: "license",
        heading: "Lisensi",
        paragraphs: [
          "Aplikasi Poopita dilisensikan kepada Anda berdasarkan Licensed Application End User License Agreement Apple (EULA Standar), yang mengatur penggunaan aplikasi. Ketentuan ini melengkapinya dan tidak menggantikannya.",
        ],
        links: [{ label: "EULA Standar Apple", href: site.appleEulaUrl }],
      },
      {
        id: "not-medical",
        heading: "Bukan nasihat medis",
        paragraphs: [
          "Poopita adalah catatan pribadi. Poopita bukan alat medis dan tidak mendiagnosis, mengobati, atau mencegah kondisi apa pun. Wawasan adalah informasi umum tentang apa yang Anda catat. Bicarakan dengan dokter tentang apa pun yang mengkhawatirkan, terutama darah, tinja hitam atau pucat, atau perubahan yang berlangsung lama. Dalam keadaan darurat, hubungi nomor darurat setempat.",
        ],
      },
      {
        id: "your-data",
        heading: "Data Anda",
        paragraphs: [
          "Catatan Anda hanya disimpan di iPhone Anda. Untuk menyimpan salinan, buat cadangan terenkripsi di Pengaturan › Cadangan dan simpan kunci pemulihan Anda dengan aman. Kami tidak dapat memulihkan catatan atau kunci pemulihan yang hilang untuk Anda.",
        ],
      },
      {
        id: "source",
        heading: "Kode sumber dan merek dagang",
        paragraphs: [
          `Kode sumber tersedia dengan lisensi ${site.licenseName}. Nama, ikon, dan maskot Poopita tidak tercakup dalam lisensi tersebut dan tidak boleh dipakai untuk aplikasi lain.`,
          "Apple, logo Apple, iPhone, dan App Store adalah merek dagang Apple Inc., yang terdaftar di AS serta negara dan wilayah lain.",
        ],
        links: [{ label: "Kode sumber", href: site.sourceUrl }],
      },
      {
        id: "website",
        heading: "Situs web ini",
        paragraphs: ["Isi situs web ini adalah informasi umum dan dapat berubah tanpa pemberitahuan."],
      },
      {
        id: "contact",
        heading: "Kontak",
        paragraphs: [
          `Kirim email ke ${site.supportEmail}. Ketentuan ini diterbitkan dalam bahasa Inggris dan Bahasa Indonesia; bagi pengguna di Indonesia, versi Bahasa Indonesia yang berlaku.`,
        ],
      },
    ],
  },
  support: {
    meta: {
      title: "Bantuan — Poopita",
      description:
        "Bantuan untuk Poopita: kunci aplikasi, ponsel baru, menghapus data, pengingat, bahasa, dan skala Bristol.",
    },
    title: "Bantuan",
    lead: "Ada yang tidak berfungsi, atau punya ide? Begini cara menghubungi kami, dan jawaban untuk pertanyaan umum.",
    contact: {
      title: "Kontak",
      body: "Kami biasanya membalas dalam dua hari kerja.",
      note: "Mohon jangan kirim foto atau detail tentang kesehatan Anda. Kami tidak membutuhkannya untuk membantu.",
    },
    faqTitle: "Pertanyaan umum",
    faq: [
      {
        question: "Bagaimana cara mengunci Poopita?",
        answer: [
          "Buka Pengaturan › Privasi dan nyalakan kuncinya. Poopita lalu meminta Face ID, Touch ID, atau kode sandi saat dibuka. Aplikasi tetap terbuka jika Anda kembali dalam 1 menit.",
          "Jika Face ID tidak mengenali Anda, gunakan kode sandi iPhone.",
        ],
      },
      {
        question: "Saya pindah ke iPhone baru. Apakah catatan saya ikut?",
        answer: [
          "Ya, jika Anda pindah dengan Mulai Cepat atau memulihkan dari cadangan iPhone. Anda juga bisa membuat cadangan di Pengaturan › Cadangan dan memulihkannya di iPhone baru dengan kunci pemulihan Anda. Kami tidak pernah punya salinannya.",
        ],
      },
      {
        question: "Bagaimana cara menghapus data saya?",
        answer: [
          "Hapus satu catatan dari layar ubahnya. Untuk menghapus semuanya, buka Pengaturan › Data Anda › Hapus semua riwayat. Anda dapat menyimpan salinan dulu dengan Ekspor semua data.",
          "Menghapus aplikasi juga menghapus datanya. Tidak ada yang perlu dihapus di pihak kami.",
        ],
      },
      {
        question: "Pengingat saya tidak muncul.",
        answer: [
          "Periksa Pengaturan iOS › Notifikasi › Poopita, Fokus yang mungkin membisukannya, dan apakah Ringkasan Terjadwal menahannya. Lalu periksa waktu dan hari di Poopita › Pengaturan › Pengingat.",
          'Jika "Lewati jika sudah mencatat" menyala, hari dengan catatan atau konfirmasi tidak mendapat pengingat.',
        ],
      },
      {
        question: "Bagaimana cara mengganti bahasa?",
        answer: [
          "Buka Poopita › Pengaturan › Bahasa. Aplikasi akan tertutup dan terbuka lagi dalam bahasa baru; catatan Anda tidak terpengaruh.",
        ],
      },
      {
        question: "Apa itu skala Bristol?",
        answer: [
          "Skala ini membagi tinja menjadi tujuh tipe berdasarkan bentuk. Pilih yang paling mendekati; tidak perlu persis.",
          "1: gumpalan keras terpisah, seperti kacang. 2: berbentuk sosis tetapi bergumpal. 3: seperti sosis dengan retakan. 4: seperti sosis atau ular, halus dan lunak. 5: gumpalan lunak dengan tepi jelas. 6: potongan lembek dengan tepi tidak rata. 7: cair, tanpa bagian padat.",
        ],
      },
      {
        question: "Mengapa hari tertentu tampil tidak diketahui, bukan nol?",
        answer: [
          "Poopita hanya menghitung apa yang Anda catat. Hari tanpa catatan dan tanpa konfirmasi mungkin ada BAB yang tidak tercatat, jadi hari itu tetap tidak diketahui. Konfirmasi hari tanpa BAB dengan satu ketukan agar terhitung.",
        ],
      },
      {
        question: "Bisakah Poopita memberi tahu jika ada yang salah?",
        answer: [
          "Tidak. Poopita adalah catatan pribadi, bukan alat medis. Aplikasi menunjukkan hal yang perlu dilihat dokter, seperti darah atau tinja hitam, merah, atau pucat, tetapi hanya dokter yang dapat menjelaskan artinya. Gunakan Ekspor untuk dokter untuk membawa riwayat Anda.",
        ],
      },
    ],
    report: {
      title: "Melaporkan bug",
      body: "Beri tahu kami:",
      items: [
        "Versi iOS dan versi Poopita Anda (di bagian bawah Pengaturan).",
        "Apa yang Anda lakukan, apa yang Anda harapkan, dan apa yang terjadi.",
      ],
    },
  },
};
