{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    peon-ping.url = "github:PeonPing/peon-ping";
    peon-ping.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, unstablepkgs, home-manager, peon-ping, ... }: let
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
        ];
        specialArgs = {
          inherit unstable home-manager peon-ping;
        };
      };
    };
  };
}
