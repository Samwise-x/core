# WSL clean baseline

The first canonical WSL baseline for `samwise-ubuntu` was captured after Ubuntu first-boot/OOBE completed and before Docker, Core, or SAMWISE services were installed.

## Baseline artifact

- Export: `E:\WSL\samwise-ubuntu-baseline-oobe-20261006T001607.tar`
- Method: clean `wsl --shutdown`, verify the distro is stopped, then `wsl --export`.
- Size: `1264476160` bytes.
- SHA-256: `BB6DD8E20B5F32E2DB3B1E135A62CE619C72B8DB35C4CB964454BFFCBCD45321`.
- Archive validation: `tar -tf` exited `0`.
- Snapshot manifest: `E:\WSL\samwise-ubuntu-baseline-oobe-20261006T001607.manifest.txt`.

## Captured state

- Distro: `samwise-ubuntu`, WSL 2.
- Ubuntu: 24.04.5 LTS.
- Installed at `D:\WSL\samwise-ubuntu`.
- Default Linux user: `master_j` (UID 1000).
- OOBE complete.
- `/etc/wsl.conf` enables systemd and sets `master_j` as the default user.
- No Docker, Core checkout, or SAMWISE service layer was admitted before this export.

## Canonical capture procedure

1. Verify the intended distro and source VHD location.
2. Run `wsl --shutdown`.
3. Verify `samwise-ubuntu` reports `Stopped`.
4. Export with `wsl --export samwise-ubuntu <new-baseline-path>.tar`.
5. Compute SHA-256 for the completed archive.
6. Validate archive readability with `tar -tf <archive>`.
7. Write a sibling manifest with the capture state, byte size, hash, and recovery guardrails.

Do not copy a live `ext4.vhdx` as the canonical baseline.

## Recovery validation

Never use the production distro as a restore test and never unregister it merely to test a backup.

Import the archive under a distinct temporary name and path, for example:

```powershell
wsl --import samwise-ubuntu-restore-test D:\WSL\samwise-ubuntu-restore-test E:\WSL\samwise-ubuntu-baseline-oobe-20261006T001607.tar --version 2
wsl -d samwise-ubuntu-restore-test -u master_j -- id
```

A production replacement is a separate cutover: take a fresh pre-change backup, verify it, obtain explicit authorization for any destructive registry/distro operation, then perform the replacement. The clean baseline remains immutable.
