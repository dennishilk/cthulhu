# Fastfetch only for interactive kitty windows (not TTY, SSH or scripts).
if status is-interactive; and set -q KITTY_WINDOW_ID; and command -sq fastfetch
    fastfetch
end
