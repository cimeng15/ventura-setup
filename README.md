# 🍎 Ventura Theme — KDE Plasma 6 (macOS-like)

Repo instalasi **sekali jalan** untuk menerapkan tampilan **macOS Ventura** ke KDE
Plasma 6 — persis seperti yang sudah dikonfigurasi di mesin sumber (CachyOS).

Semua aset (ikon, dekorasi jendela, kursor, global theme, panel, wallpaper,
GTK, shell fish) dibundel di dalam repo. **Tidak butuh internet saat instalasi**
(kecuali mau memasang paket sistem lewat `--skip-deps`).

---

## ✨ Isi tema

| Komponen | Paket |
|---|---|
| Global theme (look-and-feel) | `Apple.Ventura.Dark.P6` |
| Splash screen | `AppleSplash` |
| Desktop theme (Plasma) | `AppleDark-ALL` |
| Ikon | `Mkos-Big-Sur-Night` |
| Kursor | `Apple-cursors` |
| Dekorasi jendela (Aurorae) | `WhiteSur-dark` |
| Skema warna | `WhiteSurDark` |
| Tema GTK 2/3/4 | `WhiteSur-Dark` |
| Wallpaper | `Ventura` |
| Efek minimalisasi | `kwin-effects-yet-another-magic-lamp` (AUR, opsional) |
| Widget panel | AppBay (launchpad), Flex Hub (control center), Kpple Menu, Window Title Fork, Simple Separator, Command Output |
| Shell | fish (prompt, alias macOS, PATH, fungsi `h`/`hbaru`/`htopik`) |

**Tata letak panel yang direplikasi**
- **Panel atas** (24px): menu Apple (Kpple) · judul jendela · app-menu global · system tray · tanggal & jam · Flex Hub
- **Dock bawah** (66px, floating): AppBay · daftar aplikasi · kalkulator · trash
- **Efek**: blur (noise 7, saturation 152), magic lamp, tombol jendela di kiri (`XIA`)

---

## 🚀 Instalasi (di laptop tujuan)

```bash
git clone <URL-REPO> ventura-setup
cd ventura-setup
./install.sh
```

Ikuti saja pertanyaannya. Untuk mode tanpa tanya:

```bash
./install.sh -y            # pasang + dependensi (butuh sudo)
./install.sh -y --skip-deps  # tanpa sudo / tanpa internet
```

Setelah selesai: **logout, lalu login sekali**. Ini wajib agar dekorasi
jendela, splash screen, dan panel ter-reload sepenuhnya.

### Syarat

- KDE Plasma **6** di Wayland/X11 (CachyOS, Arch, Fedora, Ubuntu, dst.)
- `bash`, `python3`
- Untuk efek magic lamp: `paru`/`yay` (AUR) — opsional

---

## 🔧 Perintah tambahan

```bash
./bin/ventura-verify            # cek semua komponen benar-benar terpasang
./bin/ventura-apply             # terapkan ulang tema ke sesi berjalan
./bin/ventura-backup list       # daftar backup konfigurasi lama
./bin/ventura-backup restore    # kembalikan konfigurasi sebelum tema dipasang
```

### Opsi `install.sh`

| Opsi | Arti |
|---|---|
| `-y`, `--yes` | jangan bertanya |
| `--skip-deps` | lewati pemasangan paket sistem |
| `--skip-fish` | jangan sentuh konfigurasi fish |
| `--no-apply` | jangan menerapkan ke sesi yang sedang berjalan |

---

## 🛟 Keamanan & backup

Installer **tidak pernah menghapus setting tanpa backup**. Sebelum file apa pun
ditimpa, salinannya disimpan ke:

```
~/.local/share/ventura-setup/backup-<tanggal>/files/
~/.local/share/ventura-setup/backup-<tanggal>/manifest.tsv
```

Kembalikan kapan saja dengan `./bin/ventura-backup restore`.

`kdeglobals` **digabung**, bukan ditimpa: hanya grup `Colors:*`,
`ColorEffects:*` dan setting inti tema yang diubah — setting pribadi lain tetap.

---

## 🖥️ Struktur repo

```
ventura-setup/
├── install.sh              # installer utama
├── bin/
│   ├── ventura-apply       # terapkan ulang tema
│   ├── ventura-backup      # list/restore/purge backup
│   └── ventura-verify      # verifikasi instalasi
├── lib/common.sh           # fungsi bersama (copy, backup, ini_set, …)
├── configs/                # file konfigurasi (kdeglobals, kwinrc, panel, GTK, …)
├── dotfiles/fish/          # konfigurasi fish portabel
└── assets/
    ├── icons/              # Mkos-Big-Sur-Night, WhiteSur-*, cursors
    ├── themes/             # GTK WhiteSur-Dark / Light
    ├── aurorae/            # dekorasi jendela
    ├── desktoptheme/       # AppleDark-ALL
    ├── look-and-feel/      # Apple.Ventura.Dark.P6, AppleSplash
    ├── plasmoids/          # widget panel
    ├── wallpapers/         # Ventura
    ├── cursors/            # Apple-cursors
    └── color-schemes/
```

---

## ⚠️ Catatan

- **Ikon 127 MB** dibundel agar hasilnya identik & offline.
- Shell fish ditulis **portabel**: blok `source cachyos-fish-config` hanya jalan
  bila file itu ada, jadi aman di distro non-CachyOS.
- Tema ini kumpulan karya pihak ketiga (lihat [`CREDITS.md`](CREDITS.md)).
- Efek magic lamp vanilla memakai animasi minimize standar (mengarah ke ikon
  taskbar Plasma). Versi yang "terbang ke ikon dock" adalah bagian proyek
  terpisah (Golden Gate Shell) dan **tidak** termasuk repo ini.
