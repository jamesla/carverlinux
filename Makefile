PACKAGE ?= carverlinux

VM        ?= $(notdir $(CURDIR))
VM_DIR    ?= $(HOME)/Parallels
VM_CPUS   ?= 4
VM_MEM    ?= 24576
IMAGE_ATTR_PATH := nixosConfigurations.default.config.system.build.images.raw-efi

.DEFAULT_GOAL := help

.ONESHELL:

.PHONY: build
build: ## build system image for Parallels Desktop (from macOS)
	@nix build ".#$(IMAGE_ATTR_PATH)"
	@cp result/*.img nixos-parallels.img
	@chmod 644 nixos-parallels.img

.PHONY: rebuild
rebuild: ## rebuild system (from NixOS)
	@sudo nixos-rebuild switch --flake ".#default" --impure

.PHONY: version
version: ## gets current version
	@nix-instantiate --eval --expr '(import <nixos> {}).lib.version'

.PHONY: clean
clean: ## clean nixos
	@sudo nix-collect-garbage -d; sudo nix-store --gc

.PHONY: update
update: ## update flake lock file
	@sudo nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes

.PHONY: up
up: ## create and start the Parallels VM from the built disk image
	@set -euo pipefail; \
	prlctl list -a -o name --no-header | grep -qxF '$(VM)' && \
	{ echo "error: a Parallels VM named '$(VM)' already exists." >&2; \
	  echo "  start it:  prlctl start '$(VM)'" >&2; \
	  echo "  remove it: prlctl delete '$(VM)'" >&2; \
	  exit 1; }; \
	nix build ".#$(IMAGE_ATTR_PATH)"; \
	img=$$(ls result/*.img | head -1); \
	bytes=$$(stat -f %z "$$img"); \
	size_mb=$$(( (bytes + 1048575) / 1048576 )); \
	prlctl create '$(VM)' --distribution linux --no-hdd --dst '$(VM_DIR)'; \
	prlctl set '$(VM)' --device-add hdd --size "$$size_mb" --type plain \
	  --iface sata --position 0 --alloc-policy sparse; \
	home=$$(prlctl list -i '$(VM)' | awk '/^Home: /{print $$2}'); \
	hds=$$(ls "$$home"/*.hdd/*.hds | head -1); \
	echo "writing $$img -> $$hds (~$$size_mb MB, this takes a few minutes)"; \
	dd if="$$img" of="$$hds" bs=4m conv=notrunc; \
	prlctl set '$(VM)' --cpus $(VM_CPUS) --memsize $(VM_MEM); \
	prlctl set '$(VM)' --video-adapter-type virtio --3d-accelerate highest; \
	prlctl set '$(VM)' --shf-host on; \
	prlctl set '$(VM)' --shf-host-add carverlinux --path '$(CURDIR)' --mode rw; \
	prlctl start '$(VM)'

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
