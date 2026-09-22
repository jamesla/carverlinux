# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, unstable, master, home-manager, llm-agents, peon-ping, workmux, multica-nix, ... }:

let
  multicaCli = config.services.multica.package;
  multicaServerUrl = "http://127.0.0.1:8080";

  # Runtimes are not declarative: multica-reconcile skips agents and squads (and
  # then quick actions and autopilots, for want of assignees) unless a running
  # daemon has registered one. The daemon needs a credential to do that, and
  # `multica config set` has no token key, so it has to log in.
  #
  # A dev-login JWT is not enough on its own -- `multica daemon start` wants a
  # credential persisted by `multica login`, which only accepts a mul_… PAT. So
  # bootstrap through the same dev login multica-reconcile uses, then spend that
  # JWT once on minting a non-expiring PAT and hand that to `multica login`.
  #
  # Guarded on `multica auth status` so this runs once per VM, not once per
  # restart: /auth/send-code is rate-limited and multica-reconcile competes for
  # it, so logging in on every start starves both.
  multica-daemon-start = pkgs.writeShellApplication {
    name = "multica-daemon-start";
    runtimeInputs = [ pkgs.curl pkgs.jq multicaCli ];
    text = ''
      server=${lib.escapeShellArg multicaServerUrl}
      email=${lib.escapeShellArg config.services.multica.devLoginEmail}
      code=${lib.escapeShellArg config.services.multica.devVerificationCode}
      export MULTICA_SERVER_URL="$server"

      for _ in $(seq 1 60); do
        curl -fsS "$server/health" >/dev/null 2>&1 && break
        sleep 2
      done

      # 127.0.0.1, not localhost: the backend is published on IPv4 only
      # (docker 0.0.0.0:8080), but localhost resolves to ::1 first.
      multica config set server_url "$server"
      multica config set app_url http://127.0.0.1:3000

      if ! multica auth status >/dev/null 2>&1; then
        sent=0
        for _ in $(seq 1 6); do
          status=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
            -H 'Content-Type: application/json' \
            -d "$(jq -nc --arg email "$email" '{email: $email}')" \
            "$server/auth/send-code")
          if [ "$status" = "200" ]; then sent=1; break; fi
          sleep 10
        done
        if [ "$sent" != "1" ]; then
          echo "multica-daemon: could not request a dev login code (rate limited?)" >&2
          exit 1
        fi

        jwt=$(curl -fsS -X POST -H 'Content-Type: application/json' \
          -d "$(jq -nc --arg email "$email" --arg code "$code" '{code: $code, email: $email}')" \
          "$server/auth/verify-code" | jq -r '.token // empty')
        if [ -z "$jwt" ]; then
          echo "multica-daemon: dev login failed (no token in verify-code response)" >&2
          exit 1
        fi

        # The API wants the workspace alongside the bearer token; without
        # X-Workspace-Id it answers "missing authorization".
        ws=$(MULTICA_TOKEN="$jwt" multica workspace list --output json \
          | jq -r '.[0].id // empty')
        if [ -z "$ws" ]; then
          echo "multica-daemon: dev login token sees no workspace" >&2
          exit 1
        fi

        pat=$(curl -fsS -X POST \
          -H "Authorization: Bearer $jwt" \
          -H "X-Workspace-Id: $ws" \
          -H 'Content-Type: application/json' \
          -d '{"name":"carverlinux-daemon"}' \
          "$server/api/tokens" | jq -r '.token // empty')
        if [ -z "$pat" ]; then
          echo "multica-daemon: could not mint a daemon access token" >&2
          exit 1
        fi

        multica login --token "$pat" >/dev/null
      fi

      exec multica daemon start --foreground
    '';
  };

  agent-browser = pkgs.callPackage ./packages/agent-browser.nix { inherit unstable; };
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
  networking.dhcpcd.denyInterfaces = [ "veth*" "docker*" "br-*" "vboxnet*" ];

  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "60%";

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
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
    autoRepeatDelay = 500;
    autoRepeatInterval = 25;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
    dpi = 120;
    deviceSection = ''
      Driver "modesetting"
      Option "AccelMethod" "glamor"
    '';
  };

  services.libinput.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "james";
    };
  };

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;

  # Parallels serves the Rosetta runtime as a prl_fsd shared folder rather than
  # the virtiofs share virtualisation.rosetta assumes.
  virtualisation.rosetta.enable = true;
  virtualisation.rosetta.mountTag = "RosettaLinux";
  fileSystems."/run/rosetta" = {
    fsType = lib.mkForce "fuse.prl_fsd";
    options = [ "nofail" "nosuid" "nodev" "noatime" ];
  };

  systemd.services.systemd-binfmt = {
    after = [ "run-rosetta.mount" ];
    requires = [ "run-rosetta.mount" ];
  };

  # Disable prltoolsd's global shared-folder automount
  environment.etc."prltools/prlfsmountd-disable".text = "";

  fileSystems."/carverlinux" = {
    device = "carverlinux";
    fsType = "fuse.prl_fsd";
    options = [ "nofail" ];
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
    MESA_LOADER_DRIVER_OVERRIDE = "virtio_gpu";
    LIBGL_ALWAYS_INDIRECT = "0";
  };

  programs.fish = import ./packages/fish.nix;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = "";

  # Returns freed blocks to the host so the expanding Parallels disk can shrink.
  services.fstrim.enable = true;

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
         # Waits for the backend, pins the server/app URLs, then dev-logs-in and
         # execs the daemon. Idempotent and browser-free.
         ExecStart = lib.getExe multica-daemon-start;
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
