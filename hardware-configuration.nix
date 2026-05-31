{ config, lib, pkgs, modulesPath, ... }:

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

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  fileSystems."/mnt/carverlinux-raw" = {
    device = "share";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=104857600"
      "access=any"
      "nofail"
    ];
  };

  fileSystems."/carverlinux" = {
    device = "/mnt/carverlinux-raw";
    fsType = "fuse.bindfs";
    options = [
      "map=501/1000:@26/@100"
      "nofail"
      "x-systemd.requires-mounts-for=/mnt/carverlinux-raw"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
}
