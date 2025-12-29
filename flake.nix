{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, unstablepkgs, home-manager, nixos-generators, ... }: let
    system = "aarch64-linux";

    unstable = import unstablepkgs {
      inherit system;
      config.allowUnfree = true;
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
        ];
        specialArgs = {
          inherit pkgs unstable home-manager;
        };
     };
    };

    packages.aarch64-darwin = {
      default = nixos-generators.nixosGenerate {
        inherit system;
        modules = [
          ./configuration.nix
	  ({...}: { virtualisation.diskSize = 150 * 1024; })
        ];
        format = "qcow-efi";
        #format = "raw-efi";
        specialArgs = {
          inherit pkgs unstable home-manager;
        };
      };
    };
  };
}
