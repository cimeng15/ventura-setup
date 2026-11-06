# ─────────────────────────────────────────────────────────────
#  fish config — versi portabel (tema Ventura / macOS-like)
#  Dipasang oleh ventura-setup. Aman untuk distro apa pun.
# ─────────────────────────────────────────────────────────────

# ── Prompt & warna ala macOS (tanpa plugin eksternal) ────────
# Jika starship/fish bawaan distro ada, biarkan distro yang atur prompt.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# ── PATH ─────────────────────────────────────────────────────
fish_add_path --global --move "$HOME/.local/bin"

# ── Editor ───────────────────────────────────────────────────
set -gx EDITOR nano
command -q micro; and set -gx EDITOR micro
command -q nvim;  and set -gx EDITOR nvim

# ── macOS-like alias & helper ────────────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias cat='bat --paging=never' 2>/dev/null
alias open='xdg-open'
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

# ── Hermes agent (opsional, hanya bila terpasang) ────────────
if command -q hermes
    function h -d "Hermes: lanjutkan chat terakhir"
        hermes chat -c $argv
    end
    function hbaru -d "Hermes: mulai chat baru"
        hermes chat $argv
    end
    function htopik -d "Hermes: buat/lanjut chat bernama topik"
        hermes chat -c $argv[1] --create-if-missing $argv[2..-1]
    end
end

# ── Greeting ringan (bisa dimatikan) ─────────────────────────
if status is-interactive
    set -q fastfetch; and fastfetch 2>/dev/null
end
