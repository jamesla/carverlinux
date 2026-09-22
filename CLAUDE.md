# Carverlinux Agent Guidelines

## Build Commands
- `make build` - Build Parallels Desktop image (from macOS)
- `make up` - Create and start the Parallels VM from the built disk image (from macOS)
- `make rebuild` - Rebuild system from NixOS
- `make destroy` - Stop and delete the Parallels VM (from macOS)
- `make check` - Run the guest acceptance checks against the running VM (from macOS)
- `make test` - Destroy the VM, rebuild it from scratch, then check it (from macOS)
- `make clean` - Clean nix garbage
- `make update` - Update flake lock file
- `make version` - Print the NixOS version

`make` with no target prints the help. The VM name defaults to the checkout's
directory name, and the `VM_*` variables at the top of the Makefile can be
overridden on the command line.

## Testing

`destroy`, `check` and `test` run on the **macOS host**, not inside the VM: they
need `prlctl`, and `check` also needs the `claude` CLI. CI only lints Nix and
Makefile syntax - it never runs these.

- `make check` runs the acceptance checks against an already-running VM. It
  waits for the Parallels Tools guest agent, then for the guest to reach
  `running` or `degraded` (`VM_BOOT_TIMEOUT`, default 600s). A slow boot is a
  warning rather than a fatal error - the checks run anyway, since they report
  more than the wait can.
- `make test` is `destroy` + `up` + `check`. It deletes the VM and takes a long
  time.
- `make destroy` stops and deletes the VM. No prompt, and a no-op when the VM is
  absent.

The checks live in `tests/guest-checks.md` as English prose rather than a shell
script. `prlctl exec` rejects command strings over roughly 3KB and rejects a
literal backslash-newline, so an agent drives the suite with many short
`prlctl exec` calls instead of uploading one script. Write new checks in that
style: each command on a single line, prefixed with an explicit `PATH`, because
`prlctl exec` runs as root with an empty environment.

Add a check by adding a numbered `###` section under `## Checks` in
`tests/guest-checks.md` - no Makefile change is needed. The report format is a
contract: `make check` greps the output for `RESULT: PASS` and exits non-zero
without it, so preserve the `ok   - <name>` / `FAIL - <name> - <reason>` lines
and the final `RESULT:` line.

The checks are read-only - they report failures, they do not fix them, and they
never write to `/carverlinux` (the user's live repo checkout on the host).

## Code Style Guidelines
- Use Nix functional style with proper indentation (2 spaces)
- Follow NixOS module patterns with imports and config sections
- Use descriptive variable names (snake_case for packages, camelCase for functions)
- Keep configuration modular - separate concerns into individual .nix files
- Use overlays for package customization
- Include proper SHA256 hashes for fetchurl
- Use `inherit` for passing arguments between modules
- Maintain consistent ordering: inputs, overlays, pkgs, configurations
- Use comments sparingly - Nix should be self-documenting
- Follow Nixpkgs conventions for package definitions
- Only write to flake.nix if necessary - prefer writing to configuration.nix, hardware-configuration.nix or the nix files in the packages directory.

## Important

- Never git commit or push unless specifically asked
- Do not create git branches
- Don't make changes to the system directly. Make them to the nixos configuration so that the change is made for all applies going forward.
- Don't run `make check` or `make test` unless specifically asked - `test` deletes the VM, and both are slow.
