# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, home-manager, llm-agents, peon-ping, workmux, multica-nix, ... }:

let
  multica = pkgs.callPackage ./packages/multica.nix { };
  agent-browser = pkgs.callPackage ./packages/agent-browser.nix { };
in
{
  imports = [
    home-manager.nixosModules.home-manager
    ./packages/multica
  ];

  networking.hostName = "carverlinux";
  networking.firewall.enable = false;

  time.timeZone = "Pacific/Auckland";
  networking.useDHCP = true;
  # Keep dhcpcd off Docker/VirtualBox virtual interfaces; managing veths that come
  # and go with containers made dhcpcd SIGSEGV in a crash-loop.
  networking.dhcpcd.denyInterfaces = [ "veth*" "docker*" "br-*" "vboxnet*" ];

  # Compressed in-RAM swap: cheap headroom so a memory spike can't hard-freeze the VM.
  # memoryPercent = 100 gives more compressed swap before real pressure; zstd is default.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  # Run /tmp in RAM so temp-heavy compiles and tool scratch avoid the virtio disk.
  # Overflow spills to zram swap, so a large build can't hard-fail; point TMPDIR at
  # a disk path for the rare multi-GB nix image build if it ever exhausts this.
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "60%";

  boot.kernel.sysctl = {
    # With zram, swapping to RAM is cheaper than evicting page cache, so bias hard
    # toward keeping hot file cache resident for better interactive responsiveness.
    "vm.swappiness" = 180;
    # Writeback in small frequent batches instead of large stalls -> fewer UI hitches.
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
  };

  users.users.james = {
    isNormalUser = true;
    group = "users";
    home = "/home/james";
    createHome = true;
    homeMode = "700";
    extraGroups = [ "wheel" "docker" "vboxusers" "video" "audio" "render" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlkZ7yS+y5Jp/K18ZE3Swi4sfEWokEdNv0BwfDzYVEfSEKmWr9zKXhfm4pvhyxcWtqshYOzKMS3u6a8tpChEPlmVW5AkZeAPJk+Rwn++eANjeXpkvQ8zvfV6ALBU2FUiE60oGIA+tZOEbzUcgZ15CilFpwatnbe0whVocYsYAn4F9d3CLbt8U6miG4NjdSDP3E5OukuVyhF2dXEBVa9N0erLKZyL7hkePTWqoCY9hOvoxgMgopBNHLy2Q0yxkL9M3zgi8qQwa0L0ORcolBk4AVMV6+Wjt+lqYoTtn7GupFC3pZLwWRIqOvneb2oo37JVeUeIRSNSKKrwE7SGSaSAX"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Audio: PipeWire with ALSA + PulseAudio shim
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
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
    autoRepeatDelay = 750;
    autoRepeatInterval = 50;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
    dpi = 120;
    deviceSection = ''
      Driver "modesetting"
      Option "AccelMethod" "glamor"
    '';
    libinput.enable = true;
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


  # Install secrets from the repo .env (gitignored) into a root-only file, keeping them
  # out of the world-readable nix store.
  systemd.services.multica-secrets = {
    description = "Install multica secrets from repo .env";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = "/carverlinux";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      install -d -m700 /etc/multica
      install -m600 /carverlinux/.env /etc/multica/multica.env
    '';
  };

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
    pkgs.vulkan-tools
    pkgs.alsa-utils
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.ffmpeg
    pkgs.firefox
    pkgs.obsidian
    (pkgs.callPackage ./packages/st { })
    (unstable.callPackage ./packages/claude.nix { })
    multica
    agent-browser
    pkgs.libglvnd
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.liberation
  ];

  #terminal
  environment.sessionVariables = {
    TERMINAL = "st";
    EDITOR = "nvim";
    MESA_LOADER_DRIVER_OVERRIDE = "zink";
    LIBGL_ALWAYS_INDIRECT = "0";
  };

  programs.fish = import ./packages/fish.nix;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = "";

   home-manager.backupFileExtension = "backup";
   home-manager.users.james = {
     imports = [
       ./packages/peon-ping-fixed.nix
       (import ./packages/workmux.nix { inherit pkgs workmux; })
       ./packages/opencode.nix
     ];
     programs.git = import ./packages/git.nix;
     programs.ssh = import ./packages/ssh.nix;
     programs.chromium = import ./packages/chromium.nix;
     programs.tmux = import ./packages/tmux.nix { inherit config pkgs; };
     programs.neovim = import ./packages/neovim.nix { inherit config pkgs; };
     programs.ghostty = import ./packages/ghostty.nix { inherit pkgs; };
     programs.peon-ping = import ./packages/peon-ping.nix { inherit pkgs peon-ping; };
     home.packages = [ peon-ping.packages."${pkgs.stdenv.hostPlatform.system}".default ];


     # Multica agent daemon: auto-detects the coding agent CLIs on PATH (claude,
     # opencode) and registers each as a runtime the local server can assign tasks to.
     systemd.user.services.multica-daemon = {
       Unit = {
         Description = "Multica agent daemon (registers local coding agents)";
         After = [ "network-online.target" ];
         Wants = [ "network-online.target" ];
       };
       Service = {
         Type = "simple";
         Environment = [
           "MULTICA_WORKSPACES_ROOT=%h/multica_workspaces"
           "OBSIDIAN_VAULT=/carverlinux/knowledge"
           # Ensure the detected agent CLIs are on the daemon's PATH.
           "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/james/bin:%h/.nix-profile/bin"
         ];
         # Idempotent, browser-free; keeps the server/app URLs pinned across restarts.
         ExecStartPre = [
           # Use 127.0.0.1, not localhost: the backend is published on IPv4 only
           # (docker 0.0.0.0:8080), but localhost resolves to ::1 first -> connection
           # refused and the daemon crash-loops.
           "${multica}/bin/multica config set server_url http://127.0.0.1:8080"
           "${multica}/bin/multica config set app_url http://127.0.0.1:3000"
         ];
         ExecStart = "${multica}/bin/multica daemon start --foreground";
         Restart = "on-failure";
         RestartSec = 10;
       };
       Install.WantedBy = [ "default.target" ];
     };

     home.stateVersion = "26.05";
   };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Use all 8 vCPUs for parallel builds (max-jobs) and per-build compilation (cores).
    max-jobs = "auto";
    cores = 0;
    # Keep build outputs/derivations so back-to-back `make rebuild`s don't refetch or
    # rebuild dev dependencies.
    keep-outputs = true;
    keep-derivations = true;
    builders-use-substitutes = true;
  };
  system.stateVersion = "26.05";
}
