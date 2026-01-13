{ pkgs, ... }:
{
  enable = true;
  enableFishIntegration = true;
  package = pkgs.ghostty;
  
  settings = {
    font-family = "Liberation Mono Nerd Font";
    font-size = 11;
    window-decoration = false; 
    shell-integration = "fish";
  };
}
