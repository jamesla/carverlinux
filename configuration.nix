# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, llm-agents, peon-ping, ... }:

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
    extraGroups = [ "wheel" "docker" "vboxusers" "video" "audio" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;

  # Audio: PipeWire with ALSA backend
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  hardware.pulseaudio.enable = false;

  # Set default ALSA device to hw:0,1 (Virtio audio device)
  environment.etc."asound.conf".text = ''
    defaults.pcm.card 0
    defaults.pcm.device 1
    defaults.ctl.card 0

    pcm.!default {
      type plug
      slave.pcm "hw:0,1"
    }

    ctl.!default {
      type hw
      card 0
    }
  '';

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
    pkgs.ffmpeg
    (pkgs.callPackage ./packages/st { })
    (unstable.callPackage ./packages/claude.nix { })
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
       ./packages/claude-commands.nix
       peon-ping.homeManagerModules.default
     ];
     programs.git = import ./packages/git.nix;
     programs.chromium = import ./packages/chromium.nix;
     programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
     programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
     programs.ghostty = import ./packages/ghostty.nix { inherit pkgs; };
     programs.peon-ping = {
        enable = true;
        package = peon-ping.packages."${pkgs.system}".default;
        settings = {
          default_pack = "sc_scv";
          volume = 0.7;
          enabled = true;
          desktop_notifications = true;
          suppress_subagent_complete = true;
          #annoyed_threshold = 1;
          #annoyed_window_seconds = 10;
          categories = {
            "session.start" = true;
            "session.end" = true;
            "task.complete" = true;
            "task.acknowledge" = true;
            "task.error" = true;
            "task.progress" = true;
            "input.required" = true;
            "resource.limit" = true;
            "user.spam" = true;
          };
        };
        installPacks = [ "sc_scv" ];
     };
     home.packages = [ peon-ping.packages."${pkgs.system}".default ];

     # Set Virtio audio card to pro-audio profile for output
     systemd.user.services.set-audio-profile = {
       Unit.Description = "Set PipeWire audio profile for Virtio card";
       Unit.After = [ "pipewire.service" ];
       Unit.PartOf = [ "graphical-session.target" ];
       Service = {
         Type = "oneshot";
         RemainAfterExit = true;
         ExecStart = "${pkgs.lib.getExe pkgs.pulseaudio} set-card-profile alsa_card.pci-0000_00_0a.0 pro-audio";
       };
       Install.WantedBy = [ "graphical-session.target" ];
     };

     home.stateVersion = "25.11";
   };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
