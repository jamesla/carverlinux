{
  enable = true;
  enableContribAndExtras = true;
  extraPackages = hpkgs: [
    hpkgs.xmonad-contrib
    hpkgs.xmonad-extras
    hpkgs.xmonad
  ];
  config = ''
    import XMonad
    import XMonad.Hooks.EwmhDesktops
    import qualified XMonad.StackSet as W
    import qualified XMonad.Util.CustomKeys as C
    import qualified Data.Map as M
    import XMonad.Actions.SpawnOn
    import XMonad.Util.EZConfig
    import XMonad.Layout.Spacing
    import XMonad.Util.SpawnOnce

    main :: IO ()
    main = xmonad $ ewmhFullscreen $ ewmh $ defaultConfig
        { borderWidth        = 0
        , terminal         = "st"
        , normalBorderColor  = "#000000"
        , focusedBorderColor = "#000000"
        , layoutHook = spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True $
            layoutHook def
        , startupHook = do
          spawnOnce "st"
        }
        `additionalKeys`
        [ ((mod1Mask .|. shiftMask, xK_Return), spawn "st")
        , ((mod1Mask .|. controlMask, xK_Return), spawn "st -e herdr --session main")
        ]
  '';
}
