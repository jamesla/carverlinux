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
    , terminal         = "st -e tmux new-session -A -s carver"
    , normalBorderColor  = "#000000"
    , focusedBorderColor = "#000000"
    , layoutHook = spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True $
        layoutHook def
    , startupHook = do
      spawn "st -e tmux new-session -A -s carver"
    }
