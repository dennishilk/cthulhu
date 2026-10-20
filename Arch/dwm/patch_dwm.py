#!/usr/bin/env python3
"""Minimal, fail-closed local changes to official dwm 6.8 source.

The upstream dwm.c is retained in ~/.config/dwm/src as a git checkout.
This script modifies only the local working tree; git HEAD stays at tag 6.8.
"""
from pathlib import Path
import re
import sys

source = Path(__file__).resolve().parent / "src" / "dwm.c"
if not source.is_file():
    sys.exit(f"Missing dwm source: {source}")
data = source.read_text()
marker = "/* CTHULHU_DWM_6_8_PATCH */"
if marker in data:
    if "void\ntogglefullscr(const Arg *arg)" not in data or "const int outer = 12" not in data:
        sys.exit("Incomplete local patch; refusing to rebuild")
    print("Cthulhu dwm source adjustments are already present")
    sys.exit(0)


def replace_exact(old: str, new: str, label: str) -> None:
    global data
    count = data.count(old)
    if count != 1:
        sys.exit(f"dwm 6.8 anchor '{label}' matched {count} times, expected 1. Source untouched.")
    data = data.replace(old, new, 1)

replace_exact(
    "static void togglefloating(const Arg *arg);",
    "static void togglefullscr(const Arg *arg);\nstatic void togglefloating(const Arg *arg);",
    "fullscreen declaration",
)
replace_exact(
    "void\ntogglefloating(const Arg *arg)\n{",
    """void
togglefullscr(const Arg *arg)
{
    if (selmon->sel)
        setfullscreen(selmon->sel, !selmon->sel->isfullscreen);
}

void
togglefloating(const Arg *arg)
{""",
    "fullscreen implementation",
)
replace_exact(
    "\tint x, y, ocx, ocy, nx, ny;\n\tClient *c;\n\tMonitor *m;",
    "\tint x, y, ocx, ocy, nx, ny, was_tiled;\n\tClient *c;\n\tMonitor *m;",
    "movemouse variables",
)
replace_exact(
    "\tif (c->isfullscreen) /* no support moving fullscreen windows by mouse */\n\t\treturn;\n\trestack(selmon);",
    "\tif (c->isfullscreen) /* no support moving fullscreen windows by mouse */\n\t\treturn;\n\twas_tiled = !c->isfloating;\n\trestack(selmon);",
    "movemouse initial tiling state",
)
# The same monitor-transfer suffix appears in resizemouse(); modify only movemouse().
move_start = data.find("void\nmovemouse(const Arg *arg)\n{")
move_end = data.find("Client *\nnexttiled(Client *c)", move_start)
if move_start < 0 or move_end < 0:
    sys.exit("dwm 6.8 movemouse boundaries not found; source untouched")
move = data[move_start:move_end]
old_move = "\tif ((m = recttomon(c->x, c->y, c->w, c->h)) != selmon) {\n\t\tsendmon(c, m);\n\t\tselmon = m;\n\t\tfocus(NULL);\n\t}"
new_move = "\tif ((m = recttomon(c->x, c->y, c->w, c->h)) != selmon) {\n\t\tif (was_tiled)\n\t\t\tc->isfloating = 0; /* re-tile only originally tiled clients */\n\t\tsendmon(c, m);\n\t\tselmon = m;\n\t\tfocus(NULL);\n\t}"
if move.count(old_move) != 1:
    sys.exit("dwm 6.8 movemouse target anchor changed; source untouched")
data = data[:move_start] + move.replace(old_move, new_move, 1) + data[move_end:]

# Replace the upstream tile() geometry only. The algorithm keeps 12 px outer gaps
# even with one client, and 8 px between all tiled clients, on each monitor.
tile_re = re.compile(r"(?m)^void\ntile\(Monitor \*m\)\n\{.*?^\}\n", re.S)
tile = """void
tile(Monitor *m)
{
    const int outer = 12, inner = 8;
    unsigned int n = 0, i = 0, masters;
    int x, y, w, h, mw, sw, my, sy, th, left, sx, split;
    Client *c;

    for (c = nexttiled(m->clients); c; c = nexttiled(c->next))
        n++;
    if (!n)
        return;
    x = m->wx + outer;
    y = m->wy + outer;
    w = m->ww - 2 * outer;
    h = m->wh - 2 * outer;
    if (w < 1 || h < 1)
        return;
    masters = MIN(n, m->nmaster);
    split = masters && n > masters;
    mw = split ? (int)((w - inner) * m->mfact) : (masters ? w : 0);
    sw = split ? w - inner - mw : w - mw;
    sx = x + mw + (split ? inner : 0);
    my = sy = y;

    for (c = nexttiled(m->clients); c; c = nexttiled(c->next), i++) {
        if (i < masters) {
            left = masters - i;
            th = (h - (my - y) - inner * (left - 1)) / left;
            resize(c, x, my, MAX(1, mw - 2 * c->bw),
                   MAX(1, th - 2 * c->bw), 0);
            my += th + inner;
        } else {
            left = n - i;
            th = (h - (sy - y) - inner * (left - 1)) / left;
            resize(c, sx, sy, MAX(1, sw - 2 * c->bw),
                   MAX(1, th - 2 * c->bw), 0);
            sy += th + inner;
        }
    }
}
"""
data, n = tile_re.subn(lambda m: tile, data)
if n != 1:
    sys.exit(f"dwm 6.8 tile function matched {n} times, expected 1. Source untouched.")
data = marker + "\n" + data
source.write_text(data)
print("Applied Cthulhu dwm 6.8 adjustments (gaps, fullscreen, monitor retile)")
