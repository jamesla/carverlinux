PACKAGE ?= carverlinux

VM        ?= $(notdir $(CURDIR))
VM_DIR    ?= $(HOME)/Parallels
VM_CPUS   ?= 8
VM_MEM    ?= 32768
VM_DISK_MB ?= 122880
VM_BOOT_TIMEOUT ?= 600
IMAGE_ATTR_PATH := nixosConfigurations.default.config.system.build.images.raw-efi

.DEFAULT_GOAL := help

.ONESHELL:

.PHONY: build
build: ## build system image for Parallels Desktop (from macOS)
	@nix build ".#$(IMAGE_ATTR_PATH)"
	@ls -lh result/*.img

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
	prlctl set '$(VM)' --shf-host-add carverlinux --path '$(CURDIR)' --mode rw; \
	echo "priming the VM so Parallels applies the shared-folder setting"; \
	prlctl start '$(VM)' >/dev/null; \
	for i in $$(seq 1 30); do \
	  [ "$$(prlctl list -a -o status --no-header '$(VM)' | tr -d ' ')" = running ] && break; \
	  sleep 1; \
	done; \
	sleep 5; \
	prlctl stop '$(VM)' --kill >/dev/null; \
	for i in $$(seq 1 30); do \
	  [ "$$(prlctl list -a -o status --no-header '$(VM)' | tr -d ' ')" = stopped ] && break; \
	  sleep 1; \
	done; \
	prlctl set '$(VM)' --shf-host on; \
	prlctl set '$(VM)' --device-add hdd --size $(VM_DISK_MB) --type plain \
	  --iface sata --position 0 --alloc-policy sparse; \
	home=$$(prlctl list -i '$(VM)' | awk '/^Home: /{print $$2}'); \
	hds=$$(ls "$$home"/*.hdd/*.hds | head -1); \
	hdd=$$(dirname "$$hds"); \
	echo "writing $$img ($$size_mb MB) -> $$hds in a $(VM_DISK_MB) MB disk"; \
	dd if="$$img" of="$$hds" bs=4m conv=notrunc,sparse; \
	echo "converting to an expanding disk"; \
	prl_disk_tool convert --hdd "$$hdd" --expanding; \
	prlctl set '$(VM)' --device-set hdd0 --online-compact on; \
	prlctl set '$(VM)' --cpus $(VM_CPUS) --memsize $(VM_MEM); \
	prlctl set '$(VM)' --video-adapter-type virtio --3d-accelerate highest --vertical-sync off; \
	prlctl set '$(VM)' --rosetta-linux on; \
	prlctl set '$(VM)' --tools-autoupdate no; \
	prlctl set '$(VM)' --autostop shutdown --on-window-close keep-running; \
	prlctl set '$(VM)' --time-sync-smart-mode on; \
	prlctl set '$(VM)' --sh-app-host-to-guest off --sh-app-guest-to-host off; \
	prlctl set '$(VM)' --smart-mount off --shared-cloud off --share-host-location off; \
	prlctl list -i '$(VM)' | grep -qF '$(CURDIR)' || \
	{ echo "error: shared folder 'carverlinux' -> $(CURDIR) was not registered." >&2; \
	  echo "  inspect: prlctl list -i '$(VM)'   remove: prlctl delete '$(VM)'" >&2; \
	  exit 1; }; \
	prlctl list -i '$(VM)' | grep -q '^Host Shared Folders: (+)' || \
	{ echo "error: folder 'carverlinux' is registered but host sharing is disabled." >&2; \
	  echo "  Parallels only applies it after the VM has been started once (the priming step)." >&2; \
	  exit 1; }; \
	prlctl list -i '$(VM)' | grep -qE '^  cpu cpus=$(VM_CPUS) auto=off' || \
	{ echo "error: cpus not pinned to $(VM_CPUS) (still auto-sized)." >&2; exit 1; }; \
	prlctl list -i '$(VM)' | grep -qE '^  memory size=$(VM_MEM)Mb auto=off' || \
	{ echo "error: memory not pinned to $(VM_MEM)Mb (still auto-sized)." >&2; exit 1; }; \
	prlctl list -i '$(VM)' | grep -qE '^  Rosetta Linux: on' || \
	{ echo "error: Rosetta for Linux is not enabled; x86_64 binaries will not run." >&2; exit 1; }; \
	prlctl start '$(VM)'

.PHONY: destroy
destroy: ## stop and delete the Parallels VM
	@set -euo pipefail; \
	prlctl list -a -o name --no-header | grep -qxF '$(VM)' || \
	{ echo "no Parallels VM named '$(VM)'; nothing to destroy."; exit 0; }; \
	if [ "$$(prlctl list -a -o status --no-header '$(VM)' | tr -d ' ')" != stopped ]; then \
	  prlctl stop '$(VM)' --kill >/dev/null; \
	  for i in $$(seq 1 30); do \
	    [ "$$(prlctl list -a -o status --no-header '$(VM)' | tr -d ' ')" = stopped ] && break; \
	    sleep 1; \
	  done; \
	fi; \
	prlctl delete '$(VM)'

.PHONY: check
check: ## run the guest acceptance checks against the running VM
	@set -euo pipefail; \
	prlctl list -a -o name --no-header | grep -qxF '$(VM)' || \
	{ echo "error: no Parallels VM named '$(VM)'; run 'make up' first." >&2; exit 1; }; \
	[ "$$(prlctl list -a -o status --no-header '$(VM)' | tr -d ' ')" = running ] || \
	{ echo "error: VM '$(VM)' is not running." >&2; \
	  echo "  start it: prlctl start '$(VM)'" >&2; exit 1; }; \
	echo "waiting for the Parallels Tools guest agent"; \
	for i in $$(seq 1 $(VM_BOOT_TIMEOUT)); do \
	  prlctl exec '$(VM)' true >/dev/null 2>&1 && break; \
	  [ "$$i" = $(VM_BOOT_TIMEOUT) ] && \
	  { echo "error: no response from the guest agent after $(VM_BOOT_TIMEOUT)s." >&2; exit 1; }; \
	  sleep 1; \
	done; \
	echo "waiting for the guest to finish booting"; \
	for i in $$(seq 1 $(VM_BOOT_TIMEOUT)); do \
	  state=$$(prlctl exec '$(VM)' \
	    'PATH=/run/current-system/sw/bin; systemctl is-system-running || true' \
	    2>/dev/null | tr -dc 'a-z-'); \
	  case "$$state" in running|degraded) break;; esac; \
	  sleep 1; \
	done; \
	if [ "$$state" = degraded ]; then \
	  echo "warning: the guest booted degraded; failed units:" >&2; \
	  prlctl exec '$(VM)' 'PATH=/run/current-system/sw/bin systemctl --failed --no-legend' >&2 || true; \
	fi; \
	case "$$state" in running|degraded) ;; *) \
	  echo "warning: guest still '$$state' after $(VM_BOOT_TIMEOUT)s; jobs still queued:" >&2; \
	  prlctl exec '$(VM)' 'PATH=/run/current-system/sw/bin systemctl list-jobs --no-legend' >&2 || true; \
	  echo "running the checks anyway - they report more than this wait can." >&2;; \
	esac; \
	echo "running the guest checks"; \
	log=$$(mktemp); \
	printf 'The Parallels VM to check is named "%s".\n\n%s\n' \
	  '$(VM)' "$$(cat tests/guest-checks.md)" \
	  | claude -p --allowed-tools 'Bash(prlctl:*)' \
	      --disallowed-tools Write Edit NotebookEdit | tee "$$log"; \
	grep -qE '^ *RESULT: PASS *$$' "$$log" || \
	{ rm -f "$$log"; echo "error: guest checks did not pass." >&2; exit 1; }; \
	rm -f "$$log"

.PHONY: test
test: ## destroy the VM, rebuild it from scratch, and verify the guest
	@set -euo pipefail; \
	$(MAKE) destroy; \
	$(MAKE) up; \
	$(MAKE) check

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
