------------------------------------------------------------
-- XMonad Config
-- Dennis Hilk
-- • X11 only • boring is good •
------------------------------------------------------------

import XMonad
import qualified XMonad.StackSet as W
import System.Exit (exitSuccess)

-- Hooks
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat)
import XMonad.Hooks.SetWMName

-- Layouts
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing

-- Utils
import XMonad.Util.SpawnOnce
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Hacks (fixSteamFlicker)

------------------------------------------------------------
-- Main
------------------------------------------------------------
main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    $ def
        { terminal           = "kitty"
        , modMask            = mod4Mask
        , borderWidth        = 2
        , focusedBorderColor = "#89b4fa"
        , normalBorderColor  = "#1e1e2e"

        -- MUST be False (GitHub workaround)
        , focusFollowsMouse  = False
        , clickJustFocuses   = False

        , layoutHook         = myLayout
        , manageHook         = myManageHook
        , startupHook        = myStartupHook

        -- Steam flicker fix (override-redirect popups)
        , handleEventHook    =
            fixSteamFlicker
            <+> fullscreenEventHook
            <+> handleEventHook def
        }
        `additionalKeysP` myKeys

------------------------------------------------------------
-- Layout
------------------------------------------------------------
myLayout =
  smartBorders
    $ spacingWithEdge 6
    $ Tall 1 (3 / 100) (1 / 2)
      ||| Full

------------------------------------------------------------
-- ManageHook
------------------------------------------------------------
myManageHook =
  composeAll
    [ isFullscreen --> doFullFloat
    ]

------------------------------------------------------------
-- Startup
------------------------------------------------------------
myStartupHook :: X ()
myStartupHook = do
  -- Disable screen blanking / DPMS
  spawnOnce "xset s off"
  spawnOnce "xset s noblank"
  spawnOnce "xset -dpms"

  -- User autostart
  spawnOnce "~/.xmonad/autostart.sh"
  spawnOnce "~/.xmonad/soundfix.sh"
  spawnOnce "~/.xmonad/screenlayout.sh"

  -- Wine / Proton / Electron compatibility
  setWMName "LG3D"

------------------------------------------------------------
-- Keybindings
------------------------------------------------------------
myKeys :: [(String, X ())]
myKeys =
  [ -- Apps
    ("M-<Return>", spawn "kitty")
  , ("M-d",        spawn "rofi -show drun")
  , ("M-b",        spawn "google-chrome-stable")
  , ("M-t",        spawn "thunar")

    -- Window
  , ("M-q",        kill)
  , ("M-S-q",      io exitSuccess)

    -- Layouts
  , ("M-<Space>",  sendMessage NextLayout)

    -- Focus
  , ("M-j",        windows W.focusDown)
  , ("M-k",        windows W.focusUp)
  , ("M-m",        windows W.focusMaster)

    -- Swap
  , ("M-S-j",      windows W.swapDown)
  , ("M-S-k",      windows W.swapUp)

    -- Resize
  , ("M-h",        sendMessage Shrink)
  , ("M-l",        sendMessage Expand)

    -- Reload XMonad
  , ("M-S-r",      spawn "xmonad --recompile && xmonad --restart")

    -- Screenshot
  , ("<Print>", spawn "scrot '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Bilder/screenshots/'")

    -- Audio (PipeWire / SPDIF safe)
  , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
  , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
  , ("<XF86AudioMute>",        spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  ]
