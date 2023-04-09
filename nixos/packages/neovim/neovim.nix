{ lib, fetchFromGitHub, pkgs }:

let
  packages = [
    pkgs.ripgrep
    pkgs.gcc
    pkgs.unzip
    pkgs.cargo
    pkgs.dotnet-sdk
    pkgs.go
    pkgs.ruby
    # packages to move to mason once it supports it
  ];
in
  pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: rec {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.makeWrapper ];

    disallowedReferences = [ ];

    postInstall = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${lib.makeBinPath packages}
    '';
  })

