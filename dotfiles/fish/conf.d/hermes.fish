# hermes.fish — dipasang oleh ventura-setup
# Fungsi pembuka Hermes; hanya aktif bila binari `hermes` tersedia.
if command -q hermes
    function h -d "Hermes: lanjutkan chat terakhir"
        hermes chat -c $argv
    end

    function hbaru -d "Hermes: mulai chat baru (topik baru)"
        hermes chat $argv
    end

    function htopik -d "Hermes: lanjut/buat chat bernama topik"
        hermes chat -c $argv[1] --create-if-missing $argv[2..-1]
    end
end
