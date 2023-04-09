{
  programs.sway = {
  enable = true;
  wrapperFeatures.gtk = true; # so that gtk works properly
  extraPackages = with pkgs; [
      wl-clipboard
      dmenu
    ];
  };

  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      # THIS IS THE FIX FOR WHY I'M NOT CURRENTLY RUNNING SWAY
      # WITHOUT THIS SET NO MOUSE CURSOR
      # WITH IT SET LAGGY MOUSE CURSOR
      # RIP
      export WLR_NO_HARDWARE_CURSORS=1
      exec sway
    fi
  '';

  programs.qt5ct.enable = true;
}

