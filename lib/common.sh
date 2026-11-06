# Shared helper functions untuk installer Ventura theme.
# Di-source oleh install.sh, bin/ventura-apply, dan bin/ventura-backup.
# Tidak dieksekusi langsung.

# Warna (fallback kalau bukan terminal)
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'; C_CYAN=$'\033[36m'
else
    C_RESET=''; C_BOLD=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''
fi

info()  { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s  !%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf '%s  ✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()   { err "$*"; exit 1; }

# Lokasi repo (direktori induk dari lib/)
REPO_ROOT() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }

# Direktori tujuan (override lewat env untuk mode testing)
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

# Pasang isi direktori dengan backup otomatis:
#   copy_tree <src_dir> <dest_dir>
# File yang sudah ada di dest dan berbeda akan disalin ke $BACKUP_DIR lebih dulu.
copy_tree() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || { warn "sumber tidak ada: $src"; return 0; }
    mkdir -p "$dest"
    local rel
    while IFS= read -r -d '' f; do
        rel="${f#"$src"/}"
        local target="$dest/$rel"
        if [[ -f "$target" ]] && ! cmp -s "$f" "$target"; then
            backup_file "$target"
        fi
        mkdir -p "$(dirname "$target")"
        # -a: pertahankan symlink apa adanya (icon/GTK theme banyak memakainya)
        cp -a --no-preserve=ownership "$f" "$target"
    done < <(find "$src" \( -type f -o -type l \) -print0)
}

# Salin satu file dengan backup.
install_file() {
    local src="$1" dest="$2"
    [[ -f "$src" ]] || { warn "file tidak ada: $src"; return 0; }
    if [[ -f "$dest" ]] && ! cmp -s "$src" "$dest"; then
        backup_file "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a --no-preserve=ownership "$src" "$dest"
}

# Backup satu file/path jika belum dibackup di sesi ini.
backup_file() {
    local target="$1"
    [[ -n "${BACKUP_DIR:-}" ]] || return 0
    [[ -e "$target" ]] || return 0
    # Path relatif terhadap $HOME; bila target di luar $HOME, buang leading '/'
    local rel="${target#"$HOME"/}"
    rel="${rel#/}"
    local out="$BACKUP_DIR/files/$rel"
    [[ -e "$out" ]] && return 0     # sudah ada backup versi pertama
    mkdir -p "$(dirname "$out")"
    cp -a "$target" "$out"
    # Catat lokasi asli agar restore akurat
    printf '%s\t%s\n' "$rel" "$target" >> "$BACKUP_DIR/manifest.tsv"
}

# Salin seluruh direktori sebagai satu unit (untuk theme dir), dengan backup.
install_dir() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || { warn "direktori tidak ada: $src"; return 0; }
    if [[ -e "$dest" ]]; then
        backup_file "$dest"
        rm -rf "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a --no-preserve=ownership "$src" "$dest"
}

# Tulis key=value ke file INI, membuat grup bila belum ada.
#   ini_set <file> <group> <key> <value>
ini_set() {
    local file="$1" group="$2" key="$3" value="$4"
    touch "$file"
    python3 - "$file" "$group" "$key" "$value" <<'PY'
import sys, io, configparser
f, g, k, v = sys.argv[1:5]
p = configparser.RawConfigParser(strict=False)
p.optionxform = str
p.read(f, encoding="utf-8")
if not p.has_section(g):
    p.add_section(g)
p.set(g, k, v)
with io.open(f, "w", encoding="utf-8") as fh:
    p.write(fh, space_around_delimiters=False)
PY
}

# Baca nilai dari file INI; cetak ke stdout (kosong bila tidak ada).
ini_get() {
    local file="$1" group="$2" key="$3"
    python3 - "$file" "$group" "$key" <<'PY'
import sys, configparser
f, g, k = sys.argv[1:4]
p = configparser.RawConfigParser(strict=False)
p.optionxform = str
try:
    p.read(f, encoding="utf-8")
    print(p.get(g, k, fallback=""))
except Exception:
    print("")
PY
}

# Hapus key dari grup INI (abaikan bila tidak ada).
ini_unset() {
    local file="$1" group="$2" key="$3"
    [[ -f "$file" ]] || return 0
    python3 - "$file" "$group" "$key" <<'PY'
import sys, io, configparser
f, g, k = sys.argv[1:4]
p = configparser.RawConfigParser(strict=False)
p.optionxform = str
p.read(f, encoding="utf-8")
if p.has_section(g) and p.has_option(g, k):
    p.remove_option(g, k)
    with io.open(f, "w", encoding="utf-8") as fh:
        p.write(fh, space_around_delimiters=False)
PY
}

# Session Plasma sedang aktif?
plasma_running() {
    pgrep -u "$UID" -x plasmashell >/dev/null 2>&1
}

kwin_running() {
    pgrep -u "$UID" -x kwin_wayland >/dev/null 2>&1 \
        || pgrep -u "$UID" -x kwin_x11 >/dev/null 2>&1
}

# Restart plasmashell supaya config baru terbaca.
reload_plasma() {
    if plasma_running; then
        info "Merestart plasmashell…"
        ( nohup kquitapp6 plasmashell >/dev/null 2>&1 || killall plasmashell >/dev/null 2>&1 ) 
        sleep 1
        ( nohup plasmashell >/dev/null 2>&1 & ) 
        ok "plasmashell dijalankan ulang"
    fi
    if kwin_running; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 \
            && ok "KWin dikonfigurasi ulang"
    fi
}

# Terapkan tema ke sesi yang sedang berjalan lewat plasma-apply-* (jika ada).
apply_live() {
    command -v plasma-apply-lookandfeel >/dev/null 2>&1 \
        && plasma-apply-lookandfeel --resetLayout -p Apple.Ventura.Dark.P6 >/dev/null 2>&1
    command -v plasma-apply-desktoptheme >/dev/null 2>&1 \
        && plasma-apply-desktoptheme AppleDark-ALL >/dev/null 2>&1
    command -v plasma-apply-colorscheme >/dev/null 2>&1 \
        && plasma-apply-colorscheme WhiteSurDark >/dev/null 2>&1
    command -v plasma-apply-cursortheme >/dev/null 2>&1 \
        && plasma-apply-cursortheme Apple-cursors >/dev/null 2>&1
    # GTK
    command -v gsettings >/dev/null 2>&1 && {
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Mkos-Big-Sur-Night' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme 'Apple-cursors' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10' 2>/dev/null || true
    }
    true
}
