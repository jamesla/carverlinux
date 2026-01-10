{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, unstablepkgs, home-manager, ... }: let
    system = "aarch64-linux";

    unstable = import unstablepkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Overlay to increase LKL (Linux Kernel Library) memory from 100M to 1024M
    # The cptofs tool uses LKL to run a kernel as a library for filesystem operations
    # during disk image creation. The default 100M causes OOM for large disk images.
    lklMemoryOverlay = final: prev: {
      lkl = prev.lkl.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Increase LKL kernel memory for large disk image builds
          substituteInPlace tools/lkl/cptofs.c \
            --replace-fail 'lkl_start_kernel("mem=100M")' 'lkl_start_kernel("mem=1024M")'
        '';
      });
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ lklMemoryOverlay ];
    };
  in {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        modules = [
	  nixpkgs.nixosModules.readOnlyPkgs
          { nixpkgs.pkgs = pkgs; }

          ./hardware-configuration.nix
          ./configuration.nix
	  { virtualisation.diskSize = 120 * 1024; }
        ];
        specialArgs = {
          inherit unstable home-manager;
        };
     };
    };
  };
}
