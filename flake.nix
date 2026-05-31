{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
    peon-ping.url = "github:PeonPing/peon-ping";
  };
  outputs = { self, nixpkgs, unstablepkgs, home-manager, llm-agents, peon-ping, ... }: let
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

    # Fix nettle GOT overflow on aarch64 static builds (nixpkgs#392673)
    nettleStaticOverlay = final: prev: {
      nettle = prev.nettle.overrideAttrs (nixpkgs.lib.optionalAttrs final.stdenv.hostPlatform.isStatic {
        CCPIC = "-fPIC";
      });
    };

    # Fix qemu-user-static segfault on aarch64 (nixpkgs#366902)
    qemuStaticOverlay = final: prev: {
      qemu-user = prev.qemu-user.overrideAttrs (old:
        nixpkgs.lib.optionalAttrs final.stdenv.hostPlatform.isStatic {
          configureFlags = old.configureFlags ++ [ "--disable-pie" ];
        }
      );
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ lklMemoryOverlay nettleStaticOverlay qemuStaticOverlay ];
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
          inherit unstable home-manager llm-agents peon-ping;
        };
     };
    };
  };
}
