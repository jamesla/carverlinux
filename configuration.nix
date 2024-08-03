# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, ... }:
let
  hyprlandGreetdConfig = pkgs.writeText "greetd-hyprland-config" ''
    exec-once = qtgreet; hyprctl dispatch exit
  '';
in
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
    initialHashedPassword = "$6$rll.DofC3vOVxX28$RuskIaQDzZD3wEUgx3DzZJcRUNE4xBQtBSvtq9.ss3bbjeAntiBX0WK5dAVIPs8H4dalKYb/wgSTwyPnTm2DP0";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      mesa_drivers
      libva
      libvdpau
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  programs.hyprland.enable = true;

  #programs.hyprland = {
  #  enable = true;
  #  config = ''
  #    bind=SUPER+RETURN,exec,alacritty
  #  '';
  #};

  #xdg.portal.enable = true;

  #services.xserver = {
  #  autoRepeatDelay = 150;
  #  autoRepeatInterval = 50;
  #  xkb.options = "caps:escape, altwin:ctrl_win";
  #  enable = true;
  #  windowManager.xmonad = import ./packages/xmonad.nix;
  #  exportConfiguration = true;
  #};

  #services.displayManager = {
  #  autoLogin = {
  #    enable = true;
  #    user = "james";
  #  };
  #};

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "hyprland --config ${hyprlandGreetdConfig}";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    hyprland
    fish
  '';

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.mesa
    pkgs.mesa_drivers
    pkgs.dmenu-wayland
    pkgs.bindfs
    pkgs.spice-vdagent
    pkgs.nixos-generators
    pkgs.vagrant
    pkgs.rar
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
    pkgs.discord
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
    programs.kitty.enable = true;
    programs.git = import ./packages/git.nix;
    programs.chromium = import ./packages/chromium.nix;
    programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
    programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
    #wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland = {
      # Whether to enable Hyprland wayland compositor
      enable = true;
      # The hyprland package to use
      package = pkgs.hyprland;

      # Whether to enable XWayland
      #xwayland.enable = true;

      # Optional
      # Whether to enable hyprland-session.target on hyprland startup
      #systemd.enable = true;

      settings = {
        "$mod" = "SUPER";
        bind =
          [
            "$mod, P, exec, dmenu-wl_run -i"
            "$mod, F, exec, st"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
        debug = {
          disable_logs = false;
        };
      };
    };

    home.stateVersion = "24.05";
  };

  system.stateVersion = "24.05";
}
