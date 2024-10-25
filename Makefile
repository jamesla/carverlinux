PACKAGE ?= carverlinux

.DEFAULT_GOAL := help

.ONESHELL:

.PHONY: provision
provision: ## provision nixos vm
	@nix build ".#default"
	@cp -n result/nixos.qcow2 vm.utm/Data/nixos.qcow2 || (echo "copy failed: file already exists ./vm.utm/Data/nixos.qcow2")
	@chmod 644 vm.utm/Data/nixos.qcow2
	@open vm.utm
	
.PHONY: rebuild
rebuild: ## rebuild system
	@sudo nixos-rebuild switch --flake ".#default" --install-bootloader

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
