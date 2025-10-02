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
    import qualified XMonad.StackSet as W
    import qualified XMonad.Util.CustomKeys as C
    import qualified Data.Map as M
    import XMonad.Actions.SpawnOn
    import XMonad.Util.EZConfig
    import XMonad.Layout.Spacing

    main :: IO ()
    main = xmonad $ defaultConfig
        { borderWidth        = 0
        , terminal         = "st"
        , normalBorderColor  = "#000000"
        , focusedBorderColor = "#000000"
        , layoutHook = spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True $
            layoutHook def
        , startupHook = do
          spawn "st"
          spawn "feh --bg-scale /etc/wallpaper.png"
        }
  '';
}
