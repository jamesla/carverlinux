PACKAGE ?= carverlinux

.DEFAULT_GOAL := help

.ONESHELL:

build: build-base run-vagrant

.PHONY: build-base
build-base: ## build base box with packer
	packer init nixos.pkr.hcl
	packer build -on-error=ask nixos.pkr.hcl
	vagrant box add --force nixos nixos.box

.PHONY: run-vagrant
run-vagrant: ## run vagrant
	vagrant up --provider parallels

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
