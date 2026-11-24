---
name: rebuild
description: Rebuild the running carverlinux system with `make rebuild`, then verify the result against the acceptance checks in `tests/`. Use when the user asks to rebuild, apply, switch to or upgrade the NixOS configuration, or to check that a rebuild worked.
---

# Rebuild and verify

Apply the NixOS configuration in this repo to the running system, then prove
the system still works by walking through the acceptance checks in `tests/`.
A rebuild that exits 0 only shows that the configuration built and activated;
the checks are what show that 3D acceleration, Rosetta, Docker and the shared
folder survived it.

This runs **inside the NixOS guest**, as `james`, from the repo root
(`/carverlinux`). If `nixos-rebuild` is not on the `PATH` you are on the macOS
host: stop and say so. `make check` and `make test` are the host-side
equivalents, and they are not this skill's job.

## 1. Rebuild

Run `make rebuild` from the repo root. It runs
`sudo nixos-rebuild switch --flake .#default` and can take many minutes when
inputs changed, so give it a long timeout or run it in the background rather
than assuming it hung.

Then decide whether to carry on:

- **Evaluation or build failed** - nothing was switched, so the running system
  is the old one and the checks would say nothing about the change. Report the
  error and stop.
- **It switched but units failed** (`nixos-rebuild` exits non-zero after
  "activating the configuration", typically listing failed units) - the new
  configuration is live. Carry on with the checks and include the failed units
  in the report.
- **It succeeded** - carry on.

Things worth knowing when reading a failure:

- The flake only sees files git knows about. An error that a path does not
  exist, for a file that is plainly on disk, usually means the file is
  untracked. Say so; do not stage it yourself.
- "Git tree is dirty" is a warning, not an error.

## 2. Run the checks

Read every `.md` file in `tests/` and run each check described there. Read the
files each time instead of working from memory of them: adding a check is done
by adding a section to those files, and this skill must pick it up without
being edited.

Those files are written for an agent on the macOS host that reaches the guest
through `prlctl exec`. You are already in the guest, so translate:

- Run each command directly. Drop the `prlctl exec "$VM" '...'` wrapper and the
  `export PATH=...` prefix, and ignore the 3 KB and single-line limits - they
  are `prlctl` constraints.
- `prlctl exec` runs as root, so a check may quietly assume root. Use `sudo`
  for commands that need it. Where a check deliberately drops to `james`
  (`sudo -u james ...`) to prove unprivileged access, keep that form: it starts
  a fresh login for `james`, so it reflects group membership from the new
  configuration, which your own shell may predate.
- Everything else in those files applies as written: the expectations, the
  waits they ask for, and the rule that every check runs even when an earlier
  one failed.

The checks are read-only. They never write into `/carverlinux` (the user's
live checkout, shared from the host), and a failing check is reported, not
repaired.

## 3. Check whether a reboot is pending

`switch` does not reboot, so a new kernel or initrd is installed but not
running. Compare what was booted with what was just activated:

    readlink /run/booted-system/kernel /run/booted-system/initrd /run/booted-system/kernel-modules
    readlink /run/current-system/kernel /run/current-system/initrd /run/current-system/kernel-modules

If any pair differs, the checks ran against the old kernel. Say that a reboot
is needed for the upgrade to fully apply, and that kernel-dependent checks
should be read with that in mind.

## 4. Report

Use the report format `tests/` defines, with the rebuild outcome on top:

    rebuild: ok                (or: rebuild: switched with failed units - <units>)
    ok   - <name>
    FAIL - <name> - <what went wrong, with the command output that shows it>

    RESULT: PASS

One line per check, in the order the files list them. `RESULT: PASS` only if
the rebuild succeeded cleanly and every check passed; otherwise `RESULT: FAIL`.
Add the reboot note when it applies.

After a `FAIL`, add a short note on the likely cause if the evidence points at
one. Do not fix it unprompted, and never by changing the running system
directly: fixes belong in the NixOS configuration, followed by another rebuild.
