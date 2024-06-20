PACKAGE ?= carverlinux

.DEFAULT_GOAL := help

.ONESHELL:

.PHONY: build
build: ## build nixos disk image
	nix build ".#default"
	
.PHONY: rebuild
rebuild: ## rebuild system
	sudo nixos-rebuild switch --flake ".#default"

.PHONY: version
version: ## gets current version
	nix-instantiate --eval --expr '(import <nixos> {}).lib.version'

.PHONY: clean
clean: ## clean nixos
	sudo nix-collect-garbage -d; sudo nix-store --gc

.PHONY: update
update: ## update flake lock file
	cd nixos
	sudo nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
