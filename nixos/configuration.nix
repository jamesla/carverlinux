# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, ... }:

{
  networking.hostName = "carverlinux"; # Define your hostname.
  time.timeZone = "Australia/Brisbane";
  networking.useDHCP = true;

  users.users.vagrant = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    #pkgs.rubyPackages.rails
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
    pkgs.nodejs-16_x
    pkgs.nodePackages.npm-check-updates
    pkgs.nodePackages.eslint
    pkgs.yarn
    pkgs.wget
    pkgs.gnumake
    pkgs.discord
    pkgs.dmenu
    pkgs.frp
    pkgs.python3
    pkgs.ncdu
    pkgs.inetutils
    pkgs.steamcmd
    pkgs.terraform
    pkgs.envsubst
    pkgs.awscli2
    pkgs.tree
    pkgs.killall
    pkgs.docker-compose
    pkgs.azure-cli
    pkgs.kubernetes-helm
    (pkgs.callPackage ./packages/st { })
  ];

  nixpkgs.config.allowInsecure = true;

  #terminal
  environment.sessionVariables.TERMINAL= [ "st" ];

  # FISH
  programs.fish = import ./packages/fish;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = "";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

