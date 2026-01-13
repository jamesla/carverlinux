# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  networking.hostName = "carverlinux";
  networking.firewall.enable = false;

  time.timeZone = "Pacific/Auckland";
  networking.useDHCP = true;

  users.users.james = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "vboxusers" "video" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;

  services.xserver = {
    autoRepeatDelay = 150;
    autoRepeatInterval = 50;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
    dpi = 254;
    deviceSection = ''
      Driver "virtio"
      Option "HWCursor" "true"
      Option "AccelMethod" "glamor"
    '';
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "james";
    };
  };

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    unstable.opencode
    pkgs.gh
    pkgs.awscli2
    pkgs.terraform
    pkgs.kubectl
    pkgs.nodejs
    pkgs.docker-compose
    pkgs.spice-vdagent
    pkgs.git-lfs
    pkgs.gcc
    pkgs.jq
    pkgs.openssl
    pkgs.unzip
    pkgs.xclip
    pkgs.git
    pkgs.wget
    pkgs.gnumake
    pkgs.dmenu
    pkgs.ncdu
    pkgs.inetutils
    pkgs.killall
    pkgs.mesa-demos
    (pkgs.callPackage ./packages/st { })
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.liberation
  ];

  #terminal
  environment.sessionVariables = {
    TERMINAL = "st";
    EDITOR = "nvim";
    LIBGL_ALWAYS_SOFTWARE = "true";
    GALLIUM_DRIVER = "llvmpipe";
  };

  programs.fish = import ./packages/fish.nix;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = "";

   home-manager.users.james = {
     imports = [
       ./packages/opencode.nix
     ];
     programs.git = import ./packages/git.nix;
     programs.chromium = import ./packages/chromium.nix;
     programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
     programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
     programs.ghostty = import ./packages/ghostty.nix { inherit pkgs; };
     home.stateVersion = "25.11";
   };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
