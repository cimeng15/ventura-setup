#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  ventura-setup — installer tema "Ventura / macOS" untuk KDE Plasma 6
#  Sekali jalan: salin tema, panel, ikon, kursor, GTK, shell fish.
#  Aman: semua file yang tertimpa dibackup lebih dulu.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

# ── Opsi CLI ────────────────────────────────────────────────────
ASSUME_YES=0
SKIP_DEPS=0
SKIP_FISH=0
NO_APPLY=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes)      ASSUME_YES=1 ;;
        --skip-deps)   SKIP_DEPS=1 ;;
        --skip-fish)   SKIP_FISH=1 ;;
        --no-apply)    NO_APPLY=1 ;;
        -h|--help)
            cat <<EOF
Pemakaian: ./install.sh [opsi]

  -y, --yes        jangan bertanya, langsung pasang
  --skip-deps      lewati instalasi paket dependensi
  --skip-fish      jangan sentuh konfigurasi fish
  --no-apply       jangan terapkan ke sesi yang sedang berjalan
  -h, --help       tampilkan bantuan ini
EOF
            exit 0 ;;
        *) die "opsi tidak dikenal: $arg (lihat --help)" ;;
    esac
done

[[ $EUID -eq 0 ]] && die "Jangan jalankan dengan sudo/root. Jalankan sebagai user biasa."

confirm() {
    [[ $ASSUME_YES -eq 1 ]] && return 0
    local prompt="$1" ans
    read -r -p "$prompt [Y/n] " ans || true
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# ── Banner ──────────────────────────────────────────────────────
printf '%s\n' "${C_CYAN}${C_BOLD}"
cat <<'EOF'
  ██╗   ██╗███████╗███╗   ██╗████████╗██╗   ██╗██████╗  █████╗
  ██║   ██║██╔════╝████╗  ██║╚══██╔══╝██║   ██║██╔══██╗██╔══██╗
  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ██║   ██║██████╔╝███████║
  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██╔══██╗██╔══██║
   ╚████╔╝ ███████╗██║ ╚████║   ██║   ╚██████╔╝██║  ██║██║  ██║
    ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
EOF
printf '%s\n' "${C_RESET}"
echo "  Tema Ventura / macOS untuk KDE Plasma 6"
echo "  ─────────────────────────────────────────"
echo

info "Memeriksa sistem…"
if [[ ! -d /usr/share/plasma ]]; then
    die "Ini bukan sistem KDE Plasma. Skrip ini khusus Plasma 6."
fi
ok "Plasma terdeteksi"

PLASMA_VER="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)"
[[ -n "$PLASMA_VER" ]] && ok "Plasma versi utama: ${PLASMA_VER}"
command -v kwriteconfig6 >/dev/null 2>&1 || warn "kwriteconfig6 tidak ditemukan (paket kconfig). Beberapa setting mungkin tidak diterapkan."

# ── 1. Dependensi ───────────────────────────────────────────────
install_deps() {
    info "Memasang dependensi sistem…"

    # Deteksi manajer paket
    local pm=""
    for c in pacman apt dnf zypper; do command -v "$c" >/dev/null 2>&1 && { pm="$c"; break; }; done
    [[ -z "$pm" ]] && { warn "manajer paket tidak dikenali, lewati dependensi"; return 0; }

    local pkgs=()
    case "$pm" in
        pacman)
            pkgs=(ksplashqml qt6-svg qt6-declarative kconfig plasma-workspace plasma-desktop breeze qt6-base)
            # kwin-effects magic lamp dari AUR bila helper tersedia
            if command -v paru >/dev/null 2>&1 || command -v yay >/dev/null 2>&1; then
                local helper; helper="$(command -v paru || command -v yay)"
                info "Memasang efek magic lamp (AUR)…"
                "$helper" -S --needed --noconfirm kwin-effects-yet-another-magic-lamp-reloaded-git 2>/dev/null \
                    && ok "Magic lamp terpasang" || warn "Magiclamp AUR gagal/lewati (opsional)"
            else
                warn "paru/yay tidak ada — magic lamp dilewati (opsional)"
            fi
            sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || warn "sebagian paket gagal dipasang"
            ;;
        apt)
            sudo apt-get update -qq 2>/dev/null || true
            sudo apt-get install -y ksplashqml qml-module-org-kde-qqc2desktopstyle \
                plasma-framework kwin-addons 2>/dev/null || warn "sebagian paket gagal dipasang"
            ;;
        dnf)
            sudo dnf install -y kf6-kirigami plasma-workspace plasma-desktop 2>/dev/null || warn "sebagian paket gagal dipasang"
            ;;
        zypper)
            sudo zypper --non-interactive install plasma6-workspace plasma6-desktop 2>/dev/null || warn "sebagian paket gagal dipasang"
            ;;
    esac
    ok "Dependensi selesai"
}

if [[ $SKIP_DEPS -eq 0 ]]; then
    confirm "Pasang paket dependensi yang kurang (butuh sudo)?" && install_deps
else
    info "Melewati dependensi (--skip-deps)"
fi

# ── 2. Backup ───────────────────────────────────────────────────
STAMP="$(date +%Y%m%d-%H%M%S)"
export BACKUP_DIR="$XDG_DATA_HOME/ventura-setup/backup-$STAMP"
mkdir -p "$BACKUP_DIR"
ok "Backup akan disimpan di $BACKUP_DIR"

# ── 3. Aset tema ────────────────────────────────────────────────
info "Memasang tema, ikon, kursor, dekorasi…"

A="$ROOT/assets"
# Ikon (icon theme)
for d in "$A"/icons/*/; do
    install_dir "$d" "$XDG_DATA_HOME/icons/$(basename "$d")"
done
ok "Icon themes terpasang"

# GTK themes
for d in "$A"/themes/*/; do
    install_dir "$d" "$XDG_DATA_HOME/themes/$(basename "$d")"
done
ok "GTK themes terpasang"

# Aurorae (dekorasi jendela macOS)
for d in "$A"/aurorae/*/; do
    install_dir "$d" "$XDG_DATA_HOME/aurorae/themes/$(basename "$d")"
done
# File referensi dekorasi (WhiteSur-darkrc, dll.) — di tingkat yang sama
for f in "$A"/aurorae/*rc; do
    [[ -f "$f" ]] && install_file "$f" "$XDG_DATA_HOME/aurorae/themes/$(basename "$f")"
done
ok "Dekorasi jendela (Aurorae) terpasang"

# Plasma desktop themes
for d in "$A"/desktoptheme/*/; do
    install_dir "$d" "$XDG_DATA_HOME/plasma/desktoptheme/$(basename "$d")"
done
ok "Desktop theme terpasang"

# Global themes (look-and-feel / splash)
for d in "$A"/look-and-feel/*/; do
    install_dir "$d" "$XDG_DATA_HOME/plasma/look-and-feel/$(basename "$d")"
done
ok "Global themes terpasang"

# Plasmoids (widget panel: AppBay, Flex Hub, Kpple Menu, dll.)
for d in "$A"/plasmoids/*/; do
    install_dir "$d" "$XDG_DATA_HOME/plasma/plasmoids/$(basename "$d")"
done
ok "Widget panel terpasang"

# Wallpapers
for d in "$A"/wallpapers/*/; do
    install_dir "$d" "$XDG_DATA_HOME/wallpapers/$(basename "$d")"
done
ok "Wallpaper terpasang"

# Color schemes
mkdir -p "$XDG_DATA_HOME/color-schemes"
for f in "$A"/color-schemes/*.colors; do
    install_file "$f" "$XDG_DATA_HOME/color-schemes/$(basename "$f")"
done
ok "Color scheme terpasang"

# Apple cursors
install_dir "$A/cursors/Apple-cursors" "$HOME/.icons/Apple-cursors"
ok "Kursor Apple terpasang"

# ── 4. Konfigurasi ──────────────────────────────────────────────
info "Menulis konfigurasi…"
C="$ROOT/configs"

# GTK (bukan pakai gtk-3.0/assets lama, tapi dir baru)
copy_tree "$C/gtk-3.0" "$XDG_CONFIG_HOME/gtk-3.0"
copy_tree "$C/gtk-4.0" "$XDG_CONFIG_HOME/gtk-4.0"
install_file "$C/gtkrc-2.0" "$HOME/.gtkrc-2.0"
install_file "$C/fontconfig/fonts.conf" "$XDG_CONFIG_HOME/fontconfig/fonts.conf"
install_file "$C/xsettingsd/xsettingsd.conf" "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf"
ok "GTK, fontconfig, xsettingsd"

# kdeglobals: gabungkan (jangan timpa seluruh file — user lain bisa punya setting)
KG="$XDG_CONFIG_HOME/kdeglobals"
[[ -f "$KG" ]] && backup_file "$KG"
[[ -f "$KG" ]] || : > "$KG"

# Palet warna dari tema (disalin utuh: grup Colors:* dan ColorEffects:*)
python3 - "$ROOT/configs/plasma/kdeglobals" "$KG" <<'PY'
import sys, io, configparser, re
src, dst = sys.argv[1:3]
p = configparser.RawConfigParser(strict=False)
p.optionxform = str
# Pertahankan urutan baris komentar/blank seminimal mungkin; fokus nilai.
p.read(src, encoding="utf-8")
d = configparser.RawConfigParser(strict=False)
d.optionxform = str
d.read(dst, encoding="utf-8")
for sect in p.sections():
    if sect.startswith("Colors:") or sect.startswith("ColorEffects:"):
        if not d.has_section(sect):
            d.add_section(sect)
        for k, v in p.items(sect):
            d.set(sect, k, v)
with io.open(dst, "w", encoding="utf-8") as fh:
    d.write(fh, space_around_delimiters=False)
PY

for kv in \
    "General:ColorScheme:WhiteSurDark" \
    "Icons:Theme:Mkos-Big-Sur-Night" \
    "KDE:widgetStyle:Breeze" \
    "KDE:LookAndFeelPackage:Apple.Ventura.Dark.P6" \
    "KDE:AnimationDurationFactor:0.25" \
    "KDE:contrast:4" \
    "KDE:frameContrast:0.2" \
    "General:font:Noto Sans,10,-1,5,50,0,0,0,0,0" \
    "General:menuFont:Noto Sans,10,-1,5,50,0,0,0,0,0" \
    "General:taskbarFont:Noto Sans,10,-1,5,50,0,0,0,0,0" \
    "General:toolBarFont:Noto Sans,10,-1,5,50,0,0,0,0,0" \
    "General:smallestReadableFont:Noto Sans,8,-1,5,50,0,0,0,0,0" \
    "General:fixed:Hack,10,-1,5,50,0,0,0,0,0" \
    "KFileDialog Settings:View Style:DetailTree" \
    ; do
    IFS=: read -r g k v <<<"$kv"
    ini_set "$KG" "$g" "$k" "$v"
done
ok "kdeglobals"

# File rc yang sepenuhnya milik tema bisa ditimpa utuh (dengan backup)
for f in kwinrc plasmarc ksplashrc kcminputrc; do
    install_file "$C/plasma/$f" "$XDG_CONFIG_HOME/$f"
done
ok "kwinrc, plasmarc, ksplashrc, kcminputrc"

# Layout panel & desktop (Backup dulu, baru tulis)
install_file "$C/plasma/plasma-org.kde.plasma.desktop-appletsrc" \
    "$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
ok "Layout panel & desktop"

# plasmashellrc (panel floating thickness) — gabung, jangan timpa
for kv in "PlasmaViews][Panel 108:thickness:66" "PlasmaViews][Panel 108:alignment:132"; do
    IFS=: read -r g k v <<<"$kv"
    ini_set "$XDG_CONFIG_HOME/plasmashellrc" "$g" "$k" "$v"
done
ok "plasmashellrc"

# kdedefaults (defaults dari global theme)
mkdir -p "$XDG_CONFIG_HOME/kdedefaults"
copy_tree "$C/kdedefaults" "$XDG_CONFIG_HOME/kdedefaults"
ok "kdedefaults"

# Config AppBay
mkdir -p "$XDG_CONFIG_HOME/kde.org"
install_file "$C/kde.org/plasmashell.conf" "$XDG_CONFIG_HOME/kde.org/plasmashell.conf"
ok "config widget"

# ── 5. Shell fish ───────────────────────────────────────────────
if [[ $SKIP_FISH -eq 0 ]]; then
    if command -v fish >/dev/null 2>&1 || [[ -d /usr/share/fish ]]; then
        info "Memasang konfigurasi fish (portabel)…"
        F="$ROOT/dotfiles/fish"
        install_file "$F/config.fish" "$XDG_CONFIG_HOME/fish/config.fish"
        mkdir -p "$XDG_CONFIG_HOME/fish/conf.d"
        for f in "$F"/conf.d/*.fish; do
            install_file "$f" "$XDG_CONFIG_HOME/fish/conf.d/$(basename "$f")"
        done
        ok "fish terpasang"
    else
        warn "fish tidak terpasang, melewati"
    fi
else
    info "Melewati fish (--skip-fish)"
fi

# ── 6. Terapkan ─────────────────────────────────────────────────
if [[ $NO_APPLY -eq 0 ]] && plasma_running; then
    info "Menerapkan tema ke sesi yang berjalan…"
    "$ROOT/bin/ventura-apply" || warn "sebagian penerapan gagal — coba logout/login"
else
    info "Tidak menerapkan langsung (sesi tidak aktif atau --no-apply)"
fi

# ── Ringkasan ───────────────────────────────────────────────────
echo
printf '%s%s Selesai!%s\n' "$C_GREEN" "$C_BOLD" "$C_RESET"
echo
echo "  Tema yang terpasang:"
echo "    • Global theme : Apple.Ventura.Dark.P6"
echo "    • Splash       : AppleSplash"
echo "    • Desktop      : AppleDark-ALL"
echo "    • Ikon         : Mkos-Big-Sur-Night"
echo "    • Kursor       : Apple-cursors"
echo "    • Jendela      : WhiteSur-dark (Aurorae)"
echo "    • Warna        : WhiteSurDark"
echo "    • GTK          : WhiteSur-Dark"
echo "    • Wallpaper    : Ventura"
echo
if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    echo "  Backup setting lama: $BACKUP_DIR"
    echo "  Kembalikan dengan : ./bin/ventura-backup restore"
    echo
fi
echo "  ${C_YELLOW}Penting:${C_RESET} untuk hasil 100% (dekorasi, splash, panel),"
echo "  logout lalu login sekali. Treeview ikon & panel butuh sesi baru."
echo
