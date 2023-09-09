{
  description = ''
    djbutterchicken's flake
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    oldpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    unstablepkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    oldpkgs,
    unstablepkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";

    unstable = import unstablepkgs {
      inherit system;
      config.allowUnfree = true;
    };

    old = import unstablepkgs {
      inherit system;
      config.allowUnfree = true;
    };

    inherit (nixpkgs) lib;

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      carverlinux-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          { nixpkgs.pkgs = pkgs; }
          ./computers/pc/hardware-configuration.nix
          ./configuration.nix
        ];

      };

      carverlinux-prl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit unstable old;
        };

        modules = [
          { nixpkgs.pkgs = pkgs; }
          ./computers/parallels/hardware-configuration.nix
          ./configuration.nix
	  home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vagrant = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };

  nixConfig = {
    # enable new nix command and flakes
    extra-experimental-features = "nix-command flakes";
    # use four cores for enableParallelBuilding
    cores = 4;
    # continue building derivations if one fails
    #keep-going = true;
    # show more log lines for failed builds
    log-lines = 20;
    # instances of cachix for package derivations
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}

