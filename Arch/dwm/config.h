/* Cthulhu / nebu — dwm 6.8 + local targeted modifications.
 * Only one tag per Xinerama monitor; no bar; no border; 50/50 tiling.
 * Build: ~/.config/dwm/rebuild.sh
 */
#include <X11/XF86keysym.h>

static const unsigned int borderpx = 0;
static const unsigned int snap = 32;
static const int showbar = 0;
static const int topbar = 1;
static const char *fonts[] = { "JetBrainsMono Nerd Font:size=12" };
static const char dmenufont[] = "JetBrainsMono Nerd Font:size=12";
static const char col_bg[] = "#1e1e1e";
static const char col_fg[] = "#eeeeee";
static const char *colors[][3] = {
    [SchemeNorm] = { col_fg, col_bg, col_bg },
    [SchemeSel] = { col_fg, col_bg, col_bg },
};
static const char *tags[] = { "1" }; /* one workspace per display */
static const Rule rules[] = {
    /* class instance title tagsmask isfloating monitor */
    { NULL, NULL, NULL, 0, 0, -1 },
};
static const float mfact = 0.50;
static const int nmaster = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 120;
static const Layout layouts[] = {
    { "[]=", tile },
};

#define MODKEY Mod4Mask
/* dmenumon is filled in by dwm spawn() using the active monitor. */
static char dmenumon[2] = "0";
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, NULL };
static const char *termcmd[] = { "kitty", NULL };
static const char *browsercmd[] = { "google-chrome-stable", NULL };
static const char *filecmd[] = { "thunar", NULL };
static const char *shotcmd[] = { "sh", "-c", "mkdir -p \"$HOME/Screenshots\" && maim --select --hidecursor \"$HOME/Screenshots/$(date +%Y-%m-%d_%H-%M-%S)_$.png\"", NULL };
static const char *volupcmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+", NULL };
static const char *voldowncmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-", NULL };
static const char *volmutecmd[] = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };

static const Key keys[] = {
    { MODKEY, XK_Return, spawn, {.v = termcmd} },
    { MODKEY, XK_b, spawn, {.v = browsercmd} },
    { MODKEY, XK_d, spawn, {.v = dmenucmd} },
    { MODKEY, XK_t, spawn, {.v = filecmd} },
    { MODKEY, XK_q, killclient, {0} },
    { MODKEY, XK_f, togglefullscr, {0} },
    { 0, XK_Print, spawn, {.v = shotcmd} },
    { 0, XF86XK_AudioRaiseVolume, spawn, {.v = volupcmd} },
    { 0, XF86XK_AudioLowerVolume, spawn, {.v = voldowncmd} },
    { 0, XF86XK_AudioMute, spawn, {.v = volmutecmd} },
};
static const Button buttons[] = {
    { ClkClientWin, MODKEY, Button1, movemouse, {0} },
    { ClkClientWin, MODKEY, Button3, resizemouse, {0} },
};
