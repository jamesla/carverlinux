{ lib, pkgs, unstable, home-manager, peon-ping, ... }:

let
  agent-browser = pkgs.callPackage ./packages/agent-browser.nix { inherit unstable; };
in
{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  networking.hostName = "carverlinux";
  networking.firewall.enable = false;

  time.timeZone = "Pacific/Auckland";
  networking.useDHCP = true;
  networking.dhcpcd.denyInterfaces = [ "veth*" "docker*" "br-*" ];

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
    # Keeps the herdr-core backend (hc) running after logout so remote machines can attach.
    linger = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "render" ];
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
    pulse.enable = true;
    wireplumber.extraConfig."51-virtio-audio" = {
      "wireplumber.settings" = {
        "device.restore-routes" = false;
        "device.routes.default-sink-volume" = 0.6;
        "device.routes.default-source-volume" = 0.6;
      };
    };
  };

  services.xserver = {
    autoRepeatDelay = 500;
    autoRepeatInterval = 25;
    xkb.options = "caps:escape, altwin:ctrl_win";
    enable = true;
    windowManager.xmonad = import ./packages/xmonad.nix;
    exportConfiguration = true;
    dpi = 120;
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

  environment.systemPackages = [
    unstable.pi-coding-agent
    unstable.herdr-core
    pkgs.zip
    pkgs.lsof
    pkgs.gh
    pkgs.nodejs
    pkgs.docker-compose
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
    pkgs.obsidian
    (pkgs.callPackage ./packages/st { })
    (unstable.callPackage ./packages/claude.nix { })
    agent-browser
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.liberation
  ];

  environment.sessionVariables = {
    TERMINAL = "st";
    EDITOR = "nvim";
    MESA_LOADER_DRIVER_OVERRIDE = "virtio_gpu";
  };

  programs.fish = import ./packages/fish.nix;

  services.openssh.enable = true;
  programs.ssh.askPassword = "";

  # Returns freed blocks to the host so the expanding Parallels disk can shrink.
  services.fstrim.enable = true;

  home-manager.backupFileExtension = "backup";
  home-manager.users.james = {
    imports = [
      peon-ping.homeManagerModules.default
      (import ./packages/herdr.nix { inherit lib pkgs unstable; })
    ];
    programs.git = import ./packages/git.nix;
    programs.ssh = import ./packages/ssh.nix;
    programs.chromium = import ./packages/chromium.nix;
    programs.neovim = import ./packages/neovim.nix { inherit pkgs; };
    programs.peon-ping = import ./packages/peon-ping.nix { inherit pkgs peon-ping; };
    home.packages = [ peon-ping.packages."${pkgs.stdenv.hostPlatform.system}".default ];

    home.stateVersion = "26.05";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Keep build outputs/derivations so back-to-back `make rebuild`s don't refetch or
    # rebuild dev dependencies.
    keep-outputs = true;
    keep-derivations = true;
  };
  system.stateVersion = "26.05";
}
