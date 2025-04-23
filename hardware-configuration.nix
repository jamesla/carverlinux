{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "uhci_hcd" "ehci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" ={
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/mnt/carverlinux" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "nofail" ];
  };

  fileSystems."/home/james/carverlinux" = {
    device = "/mnt/carverlinux";
    fsType = "fuse.bindfs";
    options = [
      "map=501/1000:@20/@1000"
      "_netdev"
      "nofail"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
