# carverlinux guest acceptance checks

Verify that the features below actually work inside this running carverlinux
VM. You are running inside the guest as `james` (or as root via `sudo` where a
step says so). Report what you find; do not fix anything, do not touch the NixOS
configuration, and do not rebuild. A failing check is a useful result.

Run every check even if an earlier one fails, and even if the guest has not
finished booting — a check that cannot be run yet is a `FAIL` with the reason,
not a reason to stop.

Keep the work read-only. Do not write into `/carverlinux`; it is the user's live
repo checkout.

## Checks

### 1. opengl

3D acceleration must be real, not a software fallback. Query the X display that
`james` autologins to:

    export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority; glxinfo -B

Expect `direct rendering: Yes`, `Accelerated: yes`, and an `OpenGL renderer
string` naming **virgl**. Any of `llvmpipe`, `softpipe` or `swrast` means Mesa
fell back to software rendering — that is a failure even though direct rendering
still reports `Yes`. If the X socket `/tmp/.X11-unix/X0` is not there yet, wait
for it before deciding.

### 2. rosetta

x86_64 binaries must run on the host kernel through Parallels' Rosetta:

- `/run/rosetta/rosetta` exists (it arrives over a `fuse.prl_fsd` share, not
  virtiofs).
- `/proc/sys/fs/binfmt_misc/rosetta` says `enabled` and
  `interpreter /run/binfmt/rosetta`.
- Actually execute an x86_64 ELF. `virtualisation.rosetta` already sets
  `extra-platforms = x86_64-linux`, and the binary substitutes from the cache,
  so no x86_64 builder is involved:

      NIX_CONFIG='experimental-features = nix-command flakes' nix build --no-link --print-out-paths nixpkgs#legacyPackages.x86_64-linux.hello

  Run `<store path>/bin/hello` and expect `Hello, world!`. On a fresh VM this
  also fetches the nixpkgs flake, so allow it a few minutes.

### 3. docker-x86

Docker must run `linux/amd64` images, which works purely through the rosetta
binfmt registration — no qemu, no `tonistiigi/binfmt` bootstrap:

    docker run --rm --platform linux/amd64 alpine:3 uname -m

Expect `x86_64`. Also confirm `docker.service` is active
(`systemctl is-active docker.service`), and that `james` reaches the docker
socket without root (`docker version`, run as `james`, with no sudo) — that
proves the `docker` group membership.

### 4. carverlinux-mount

The Parallels shared folder must be mounted:

- `findmnt -no SOURCE,FSTYPE /carverlinux` reports source `carverlinux` and
  fstype `fuse.prl_fsd`.
- The repo is readable through it — `/carverlinux/flake.nix` exists and contains
  `nixosConfigurations`.
- `ls /carverlinux` succeeds as `james`. The share is mounted by root, so
  without FUSE `allow_other` the user who actually works in it gets `EACCES`.

## Reporting

This report is parsed by `make check`, so the format is not optional. Emit it
even when a check fails, when a check cannot be run at all, or when you think
the expectation itself is wrong — say so in the `FAIL` line's reason and still
print the verdict. Never end without a `RESULT:` line.

Print exactly one line per check, in the order above:

    ok   - <name>
    FAIL - <name> — <what went wrong, with the command output that shows it>

Then a blank line, then a final line on its own, one of:

    RESULT: PASS
    RESULT: FAIL

`RESULT: PASS` only if every check passed. Keep the whole report short — the
per-check lines and the verdict, nothing else. Print it as plain text; do not
wrap it in a code fence, and do not indent the verdict line.
