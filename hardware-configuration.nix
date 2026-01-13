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

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;

  services.xserver.videoDrivers = [ "virtio" ];

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

  fileSystems."/carverlinux" = {
    device = "com.apple.virtio-fs.automount";
    fsType = "virtiofs";
    options = [ "nofail" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
}
