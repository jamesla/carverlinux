# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  networking.hostName = "carverlinux"; # Define your hostname.
  networking.firewall.enable = false;

  time.timeZone = "Pacific/Auckland";
  networking.useDHCP = true;

  users.users.james = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "vboxusers" "video" "input" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = false;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "james";
  };

  services.xserver = {
    enable = false;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  }; 

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    #extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
    };
  };

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.ghostty
    pkgs.bemenu
    pkgs.nodejs
    pkgs.git-lfs
    pkgs.gcc
    pkgs.jq
    pkgs.openssl
    pkgs.unzip
    pkgs.xclip
    pkgs.git
    pkgs.wget
    pkgs.gnumake
    pkgs.ncdu
    pkgs.inetutils
    pkgs.killall
    #(pkgs.callPackage ./packages/st { })
  ];

  #terminal
  environment.sessionVariables.TERMINAL= [ "ghostty" ];
  environment.variables.EDITOR = "nvim";

  programs.fish = import ./packages/fish.nix;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = "";

  home-manager.users.james = {
    programs.git = import ./packages/git.nix;
    programs.chromium = import ./packages/chromium.nix;
    programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
    programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
    home.stateVersion = "24.05";
    home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05";
}
