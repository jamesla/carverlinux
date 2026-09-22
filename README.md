# Carverlinux

## Getting started

1. Ensure darwin-nix is installed

2. Configure darwin linux builder (ensure following snippet is added to your darwin-configuration.nix)
```nix
...
nix.linux-builder = {
  enable = true;
  ephemeral = true;
  maxJobs = 4;
  config = {
    virtualisation = {
      darwin-builder = {
        diskSize = 200 * 1024;
        memorySize = 8 * 1024;
      };
      cores = 6;
    };
  };
};

nix.settings.trusted-users = [ "@admin" ];
...
```

3. Build builder
```bash
darwin-rebuild switch
```

4. Create and start the VM
```bash
make up
```

5. Inside the VM, you can rebuild the system with
```bash
make rebuild
```

## Make targets

`make` with no target prints this list.

| Target | Runs on | What it does |
| --- | --- | --- |
| `make build` | macOS host | build the system image for Parallels Desktop |
| `make up` | macOS host | create and start the Parallels VM from the built disk image |
| `make check` | macOS host | run the guest acceptance checks against the running VM |
| `make test` | macOS host | ⚠ destroy the VM, rebuild it from scratch, and verify the guest |
| `make destroy` | macOS host | ⚠ stop and delete the Parallels VM |
| `make rebuild` | NixOS guest | rebuild the system from the flake |
| `make clean` | NixOS guest | ⚠ collect nix garbage |
| `make update` | either | update the flake lock file |
| `make version` | either | print the NixOS version |

⚠ destroys state. `destroy` and `test` delete the VM without prompting.

The `VM_*` variables at the top of the Makefile — `VM`, `VM_DIR`, `VM_CPUS`,
`VM_MEM`, `VM_DISK_MB`, `VM_BOOT_TIMEOUT` — can be overridden on the command
line, e.g. `make up VM_MEM=16384`. `VM` defaults to the name of the directory
you cloned into, so in this checkout the VM is named `carverlinux-acm2`.

## Testing

`make check` verifies a running VM. It covers five checks — `opengl` (real
virgl acceleration, not an llvmpipe fallback), `rosetta` (x86_64 binaries
actually execute), `docker-x86` (`linux/amd64` containers run),
`carverlinux-mount` (the Parallels shared folder is mounted and readable as
your user), and `multica-resources` (every skill, agent, squad, autopilot and
quick action declared in `packages/multica/default.nix` exists in the running
Multica instance).

The checks are written in English in `tests/guest-checks.md` and driven by an
agent over `prlctl exec`; it prints a line per check and exits non-zero unless
every check passes.

```bash
make check
```

It runs on the macOS host and needs both `prlctl` and the `claude` CLI there.
The VM must already be running — start it with `prlctl start` or `make up`
first. `make check` waits for the guest agent and for the guest to finish
booting (up to `VM_BOOT_TIMEOUT`, 600s by default); a guest that is still
booting after that is a warning, not a failure, and the checks run anyway.

`make test` is the full loop — it destroys the VM, rebuilds it from the image,
waits for the guest to boot, then runs the checks. Expect it to take a while.

```bash
make test
```

`make destroy` stops and deletes the VM on its own. It does not prompt.
