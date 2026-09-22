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

## Testing

`make check` verifies a running VM: OpenGL acceleration, Rosetta x86 emulation,
`linux/amd64` docker containers, and the `/carverlinux` shared-folder mount. The
checks are written in English in `tests/guest-checks.md` and driven by an agent
over `prlctl exec`; it prints a line per check and exits non-zero unless all four
pass.

```bash
make check
```

`make test` is the full loop — it destroys the VM, rebuilds it from the image,
waits for the guest to boot, then runs the checks. Expect it to take a while.

```bash
make test
```

`make destroy` stops and deletes the VM on its own. It does not prompt.
