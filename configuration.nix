# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, llm-agents, peon-ping, workmux, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  networking.hostName = "carverlinux";
  networking.firewall.enable = false;

  time.timeZone = "Pacific/Auckland";
  networking.useDHCP = true;
  # Keep dhcpcd off Docker/VirtualBox virtual interfaces; managing veths that come
  # and go with containers made dhcpcd SIGSEGV in a crash-loop.
  networking.dhcpcd.denyInterfaces = [ "veth*" "docker*" "br-*" "vboxnet*" ];

  users.users.james = {
    isNormalUser = true;
    group = "users";
    home = "/home/james";
    createHome = true;
    homeMode = "700";
    extraGroups = [ "wheel" "docker" "vboxusers" "video" "audio" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;

  # Audio: PipeWire with ALSA + PulseAudio shim
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # WirePlumber otherwise remembers and restores per-device route state from
    # ~/.local/state/wireplumber/, and the UTM VirtIO sink/source get stuck
    # restored as muted/zero-volume across reboots. Disable route restoration
    # and pin sane defaults so audio always comes up unmuted.
    wireplumber.extraConfig."51-virtio-audio" = {
      "wireplumber.settings" = {
        "device.restore-routes" = false;
        "device.routes.default-sink-volume" = 0.6;
        "device.routes.default-source-volume" = 0.6;
      };
    };
  };
  services.pulseaudio.enable = false;

  services.xserver = {
    autoRepeatDelay = 150;
    autoRepeatInterval = 50;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
    dpi = 254;
    deviceSection = ''
      Driver "modesetting"
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
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    unstable.opencode
    pkgs.ngrok
    pkgs.zip
    pkgs.lsof
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
    pkgs.alsa-utils
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.ffmpeg
    (pkgs.callPackage ./packages/st { })
    (unstable.callPackage ./packages/claude.nix { })
    pkgs.bindfs
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
       ./packages/peon-ping-fixed.nix
       (import ./packages/workmux.nix { inherit pkgs workmux; })
     ];
     programs.git = import ./packages/git.nix;
     programs.chromium = import ./packages/chromium.nix;
     programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
     programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
     programs.ghostty = import ./packages/ghostty.nix { inherit pkgs; };
     programs.peon-ping = import ./packages/peon-ping.nix { inherit pkgs peon-ping; };
     home.packages = [ peon-ping.packages."${pkgs.stdenv.hostPlatform.system}".default ];

     home.stateVersion = "26.05";
   };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";
}
