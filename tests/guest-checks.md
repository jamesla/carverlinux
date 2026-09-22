# carverlinux guest acceptance checks

Verify that the features below actually work inside the running carverlinux VM.
Report what you find; do not fix anything, do not touch the NixOS configuration,
and do not rebuild. A failing check is a useful result.

Run every check even if an earlier one fails, and even if the guest has not
finished booting — a check that cannot be run yet is a `FAIL` with the reason,
not a reason to stop.

## Running commands in the guest

Use `prlctl exec "$VM" '<command>'` from the macOS host. Things to know:

- It runs as **root** with an **empty `PATH`**, so start every command with
  `export PATH=/run/current-system/sw/bin:/run/wrappers/bin;`.
- The command string is limited to roughly 3 KB. Keep each invocation short and
  run several rather than one big one. A command containing a literal
  backslash-newline is rejected outright, so keep each one on a single line.
- The guest command's exit code comes back to the host, and stdout/stderr are
  returned as normal.

## Checks

### 1. opengl

3D acceleration must be real, not a software fallback. X autologins as `james`,
so query the running display:

    export DISPLAY=:0 XAUTHORITY=/home/james/.Xauthority; glxinfo -B

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

      export HOME=/root NIX_CONFIG='experimental-features = nix-command flakes'
      nix build --no-link --print-out-paths nixpkgs#legacyPackages.x86_64-linux.hello

  Run `<store path>/bin/hello` and expect `Hello, world!`. On a fresh VM this
  also fetches the nixpkgs flake, so allow it a few minutes.

### 3. docker-x86

Docker must run `linux/amd64` images, which works purely through the rosetta
binfmt registration — no qemu, no `tonistiigi/binfmt` bootstrap:

    docker run --rm --platform linux/amd64 alpine:3 uname -m

Expect `x86_64`. Also confirm `docker.service` is active, and that `james`
reaches the docker socket without root (`sudo -u james docker version`) — that
proves the `docker` group membership, which `prlctl exec` as root would hide.

### 4. carverlinux-mount

The Parallels shared folder must be mounted:

- `findmnt -no SOURCE,FSTYPE /carverlinux` reports source `carverlinux` and
  fstype `fuse.prl_fsd`.
- The repo is readable through it — `/carverlinux/flake.nix` exists and contains
  `nixosConfigurations`.
- `sudo -u james ls /carverlinux` succeeds. The share is mounted by root, so
  without FUSE `allow_other` the user who actually works in it gets `EACCES`.

Treat this check as read-only: do not write into `/carverlinux`, it is the
user's live repo checkout on the host.

### 5. multica-resources

The skills, agents, squads, autopilots and quick actions declared in
`packages/multica/default.nix` must actually exist in the running Multica
instance, not merely be declared.

`multica-reconcile.service` is what pushes them. Work out what was declared
rather than trusting a number in this file — `systemctl cat
multica-reconcile.service` leads to the reconcile script, which names a JSON
manifest in the nix store holding every declared `agents`, `autopilots`,
`quickActions`, `skills` and `squads` entry. That manifest is the expected set.

Then confirm they were created. Useful signals, roughly in order of strength:

- `multica-reconcile.service` is `active (exited)`. It is a `RemainAfterExit`
  oneshot, so anything else — especially still `activating` — means reconcile
  never finished and the later resource types were never pushed.
- Its journal logs a `creating <name>` line per resource.
- The backend on `http://127.0.0.1:8080` can be queried for what actually
  exists, and the `multica` CLI has `agent`, `autopilot`, `skill` and `squad`
  subcommands. If the CLI reports it is not authenticated, say so in the
  result rather than attempting to log in.

Report a count per resource type — declared versus present — and name anything
missing. Every declared resource must exist for this check to pass. Do not
create, delete or modify any Multica resource, and never print the contents of
`/var/lib/multica/env`.

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
