PACKAGE ?= carverlinux

.DEFAULT_GOAL := help

.ONESHELL:

# create a random id we use this throughout the build
ID := $(shell openssl rand -base64 100 | tr -dc 'a-z' | head -c 8)

.PHONY: build
build: ## build base box with packer
	packer init carverlinux.pkr.hcl
	packer build -var build_id=$(ID) -on-error=ask carverlinux.pkr.hcl
	vagrant box add carverlinux-$(ID) boxes/carverlinux-$(ID).box

	mkdir -p machines/carverlinux-$(ID) \
	  && cd machines/carverlinux-$(ID) \
	  && vagrant init -m carverlinux-$(ID) \
	  && vagrant up --provider parallels

.PHONY: parallels
parallels: ## build parallels vm
	cd nixos
	sudo nixos-rebuild switch --flake ".#carverlinux-prl"

.PHONY: pc
pc: ## build pc
	sudo nixos-rebuild switch --flake ".#carverlinux-pc"

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
