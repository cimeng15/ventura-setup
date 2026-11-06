# lerd.fish — dipasang oleh ventura-setup (opsional)
# Menambahkan ~/.local/share/lerd/bin ke PATH bila direktori itu ada.
set -l lerd_bin "$HOME/.local/share/lerd/bin"
if test -d $lerd_bin
    fish_add_path --global $lerd_bin
end
