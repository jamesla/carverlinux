PACKAGE ?= carverlinux

.DEFAULT_GOAL := help

.ONESHELL:

.PHONY: build
build: ## build system image for Parallels Desktop (from macOS)
	@nix build .#nixosConfigurations.default.config.system.build.images.raw-efi
	@cp result/*.img nixos-parallels.img
	@chmod 644 nixos-parallels.img

.PHONY: parallels-share
parallels-share: ## register this repo as the 'carverlinux' Parallels shared folder
	@prlctl set Carverlinux --shf-host on
	@prlctl set Carverlinux --shf-host-add carverlinux --path $(CURDIR) --mode rw

.PHONY: rebuild
rebuild: ## rebuild system (from NixOS)
	@sudo nixos-rebuild switch --flake ".#default"

.PHONY: version
version: ## gets current version
	@nix-instantiate --eval --expr '(import <nixos> {}).lib.version'

.PHONY: clean
clean: ## clean nixos
	@sudo nix-collect-garbage -d; sudo nix-store --gc

.PHONY: update
update: ## update flake lock file
	@sudo nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
