{ config, lib, pkgs, modulesPath, unstable, ... }:

{
  boot.initrd.kernelModules = ["virtio_gpu" "virtio_pci" "virtio" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

  boot.kernelModules = [ "virtio_snd" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 1;

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.parallels.enable = true;
  hardware.parallels.package = unstable.prl-tools;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  fileSystems."/carverlinux" = {
    device = "carverlinux";
    fsType = "fuse.prl_fsd";
    options = [
      "nosuid"
      "nodev"
      "noatime"
      "big_writes"
      "uid=1000"
      "gid=100"
      "nofail"
      "x-systemd.requires=prltoolsd.service"
      "x-systemd.after=prltoolsd.service"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
}
