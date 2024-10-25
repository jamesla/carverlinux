{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, unstablepkgs, home-manager, nixos-generators, ... }: let
    system = "x86_64-linux";

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
          { boot.loader.grub.devices = [ "/dev/sda" ]; }
          ./hardware-configuration.nix
          ./configuration.nix
        ];
        specialArgs = {
          inherit pkgs unstable home-manager;
        };
     };
    };

    packages.x86_64-darwin = {
      default = nixos-generators.nixosGenerate {
        inherit system;
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
        ];
        format = "qcow-efi";
        specialArgs = {
          inherit pkgs unstable home-manager;
          diskSize = 200 * 1024;
        };
      };
    };
  };
}
