/* Cthulhu / nebu: dwm 6.8, patch-free. Rebuild: ~/.config/dwm/rebuild.sh */
static const unsigned int borderpx = 2;
static const unsigned int snap = 32;
static const int showbar = 1;
static const int topbar = 1;
static const char *fonts[] = { "JetBrainsMono Nerd Font:size=10" };
static const char dmenufont[] = "JetBrainsMono Nerd Font:size=10";
static const char col_bg[] = "#11191b";
static const char col_border[] = "#354448";
static const char col_fg[] = "#cbd9d5";
static const char col_active[] = "#5e9991";
static const char *colors[][3] = {
    [SchemeNorm] = { col_fg, col_bg, col_border },
    [SchemeSel] = { col_fg, col_bg, col_active },
};
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };
static const Rule rules[] = {
    /* class instance title tagsmask isfloating monitor */
    { NULL, NULL, NULL, 0, 0, -1 },
};
static const float mfact = 0.55;
static const int nmaster = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 120;
static const Layout layouts[] = {
    { "[]=", tile },
    { "><>", NULL },
    { "[M]", monocle },
};
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
    { MODKEY, KEY, view, {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask, KEY, toggleview, {.ui = 1 << TAG} }, \
    { MODKEY|ShiftMask, KEY, tag, {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask|ShiftMask, KEY, toggletag, {.ui = 1 << TAG} },
static const char *menucmd[] = { "rofi", "-show", "drun", "-show-icons", NULL };
static const char *termcmd[] = { "kitty", NULL };
static const char *browsercmd[] = { "google-chrome-stable", NULL };
static const Key keys[] = {
    { MODKEY, XK_Return, spawn, {.v = termcmd} },
    { MODKEY, XK_b, spawn, {.v = browsercmd} },
    { MODKEY, XK_d, spawn, {.v = menucmd} },
    { MODKEY, XK_q, killclient, {0} },
    { MODKEY, XK_j, focusstack, {.i = +1} },
    { MODKEY, XK_k, focusstack, {.i = -1} },
    { MODKEY, XK_h, setmfact, {.f = -0.05} },
    { MODKEY, XK_l, setmfact, {.f = +0.05} },
    { MODKEY|ShiftMask, XK_Return, zoom, {0} },
    { MODKEY, XK_t, setlayout, {.v = &layouts[0]} },
    { MODKEY, XK_f, setlayout, {.v = &layouts[2]} },
    { MODKEY, XK_space, setlayout, {0} },
    { MODKEY|ShiftMask, XK_space, togglefloating, {0} },
    { MODKEY, XK_comma, focusmon, {.i = -1} },
    { MODKEY, XK_period, focusmon, {.i = +1} },
    { MODKEY|ShiftMask, XK_comma, tagmon, {.i = -1} },
    { MODKEY|ShiftMask, XK_period, tagmon, {.i = +1} },
    TAGKEYS(XK_1,0)
    TAGKEYS(XK_2,1)
    TAGKEYS(XK_3,2)
    TAGKEYS(XK_4,3)
    TAGKEYS(XK_5,4)
    TAGKEYS(XK_6,5)
    TAGKEYS(XK_7,6)
    TAGKEYS(XK_8,7)
    TAGKEYS(XK_9,8)
    { MODKEY|ShiftMask, XK_q, quit, {0} },
};
static const Button buttons[] = {
    { ClkLtSymbol, 0, Button1, setlayout, {0} },
    { ClkLtSymbol, 0, Button3, setlayout, {.v = &layouts[2]} },
    { ClkWinTitle, 0, Button2, zoom, {0} },
    { ClkStatusText, 0, Button2, spawn, {.v = termcmd} },
    { ClkClientWin, MODKEY, Button1, movemouse, {0} },
    { ClkClientWin, MODKEY, Button2, togglefloating, {0} },
    { ClkClientWin, MODKEY, Button3, resizemouse, {0} },
    { ClkTagBar, 0, Button1, view, {0} },
    { ClkTagBar, 0, Button3, toggleview, {0} },
    { ClkTagBar, MODKEY, Button1, tag, {0} },
    { ClkTagBar, MODKEY, Button3, toggletag, {0} },
};
