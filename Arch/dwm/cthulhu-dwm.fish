# Only local TTY1 login starts Xorg/dwm; SSH sessions are untouched.
if status is-login; and test (tty) = /dev/tty1; and not set -q DISPLAY; and not set -q SSH_TTY
    exec startx
end
