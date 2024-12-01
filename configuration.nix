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
    extraGroups = [ "wheel" "docker" "vboxusers" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.xserver = {
    autoRepeatDelay = 150;
    autoRepeatInterval = 50;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "james";
    };
  };

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  #users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.bindfs
    pkgs.spice-vdagent
    pkgs.nixos-generators
    pkgs.vagrant
    #pkgs.rar
    pkgs.git-lfs
    pkgs.alacritty
    pkgs.love
    pkgs.twilio-cli
    pkgs.gcc
    pkgs.aws-sam-cli
    pkgs.rubyPackages.rails
    pkgs.jq
    pkgs.ffmpeg
    pkgs.certbot
    pkgs.ngrok
    pkgs.postgresql
    pkgs.flameshot
    pkgs.openssl
    pkgs.unzip
    pkgs.vscode
    pkgs.jdk11
    pkgs.xclip
    pkgs.maven
    pkgs.minikube
    pkgs.kubectl
    pkgs.git
    unstable.nodePackages_latest.cdktf-cli
    pkgs.nodejs
    pkgs.nodePackages.npm-check-updates
    pkgs.nodePackages.eslint
    pkgs.yarn
    pkgs.wget
    pkgs.gnumake
    #pkgs.discord
    pkgs.dmenu
    pkgs.python3
    pkgs.ncdu
    pkgs.inetutils
    #pkgs.steamcmd # breaks nix-darwin builder
    unstable.terraform
    pkgs.envsubst
    pkgs.awscli2
    pkgs.tree
    pkgs.killall
    pkgs.docker-compose
    pkgs.azure-cli
    pkgs.kubernetes-helm
    (pkgs.callPackage ./packages/st { })
  ];

  fonts.packages = with pkgs; [
    nerdfonts
  ];

  #terminal
  environment.sessionVariables.TERMINAL= [ "st" ];
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
    home.file."carverlinux/.create".text = "created";
  };

  system.stateVersion = "24.05";
}
