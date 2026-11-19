---
type: Plans
title: "Staged System Update, November 2026"
lede: "230 packages, an openssl major bump and a locally patched Omarchy, updated in four stages that survive reboots and lost sessions."
publish: true
date_created: 2026-11-19
date_modified: 2026-11-19
date_authored_initial_draft: 2026-11-19
date_authored_current_draft: 2026-11-19
date_authored_final_draft:
authors:
  - mps
augmented_with:
  - Claude Code on Claude Opus 5.5
at_semantic_version: 0.0.1.0
status: Implementing
date_work_started: 2026-11-19
site_uuid: 4339f862-adeb-444d-9a53-b1e7d7caf289
hex_code: fdexh4
tags:
  - Omarchy
  - Asahi-Linux
  - System-Updates
  - Resumable-Plan
summary: "Resumable runbook for the Nov 2026 update of the MacBook Air M2 (Asahi + omarchy-mac). An agent resuming this work should read 'How to resume', run the state check, then continue from the first stage whose Done check fails. Append to the Progress Log after every stage."
---

# Staged System Update, November 2026

## Why Care?

This MacBook runs Arch Linux ARM with the Asahi kernel, plus the omarchy-mac desktop
layer, plus local fixes on top of that. A single "update everything" after a gap is the
classic way to break it. It happened in October 2026 (see the README's
*Troubleshooting: recovering from a broken update*). So updates go in stages: hardware
first, then the kernel and core system, then Omarchy and apps, then AUR packages. A
reboot sits between stages, and a reboot also ends the working session. This plan
records each stage's state so that **any new session, human or agent, can tell where
things stand from the machine itself and carry on.**

## How to resume (read this first in a new session)

1. Read the **Progress Log** at the bottom. It records what was done and when.
2. Don't trust the log alone. Run the **state check** below. It reads the truth from
   pacman, git and the running kernel.
3. Continue from the first stage whose **Done check** fails.
4. After finishing a stage, append a line to the Progress Log and commit this file.
   Then a crash or reboot loses nothing.

### State check

```bash
uname -r                                                    # running kernel
pacman -Q mesa vulkan-asahi systemd dbus openssl qt6-base hyprland
checkupdates | wc -l                                        # repo updates still pending
yay -Qua | wc -l                                            # AUR updates still pending
git -C ~/.local/share/omarchy log --oneline -1              # Omarchy checkout HEAD
git -C ~/.local/share/omarchy log --oneline @{u}..HEAD      # local fixes still on top (expect 3)
grep -c ThemeColor ~/.local/share/omarchy/shell/Commons/qmldir   # 1 = Qt colour fix active
sudo snapper -c root list | tail -3                         # recent snapshots
tail -5 /var/log/pacman.log                                 # did the last transaction finish?
```

If `pacman.log` ends mid-transaction or `/var/lib/pacman/db.lck` exists with no pacman
running, stop and follow the README's broken-update recovery section first.

## Starting state (surveyed 2026-11-19)

| Area | State |
|---|---|
| Last update | 2026-11-05, finished cleanly (initramfs rebuilt, hooks ran) |
| Kernel / boot | `linux-asahi 7.2.12.asahi3-1`, `m1n1 1.9.9-1`, `uboot-asahi 2026.07.asahi2-1`. **No updates pending** |
| Pending repo updates | 230 |
| Graphics | `mesa` / `vulkan-asahi` 26.2.6 → 26.3.1 |
| Core | systemd 262.1 → 262.2, dbus 1.16.2 → 1.16.4, **openssl 3.6.5 → 4.1.0**, pacman, qt6-base 6.12.0-3 → -5, pipewire, wireplumber, bluez |
| Hyprland | 0.57.1-2 (Omarchy build). `omarchy-update` deliberately passes `--ignore hyprland`, so it stays put |
| AUR | 3: `spotify`, `dotnet-runtime-9.0-bin`, `devin-cli-bin` |
| Omarchy checkout | `~/.local/share/omarchy` tracks `malik-na/omarchy-mac`. Clean tree, 3 local commits on top, upstream 3 commits ahead (README only) |
| Disk | 63 GB free on `/` |

**Risk notes**

- **openssl 4 is a soname bump (`libssl.so.3` → `.so.4`), not a drop-in.** sudo, curl,
  openssh, cryptsetup, libarchive, libgit2 and others are built against openssl 3, and the
  new systemd needs openssl 4. A dry run on 2026-11-19 showed that **any** core-only
  transaction fails: `installing openssl (4.1.0-1) breaks dependency 'libcrypto.so=3-64'
  required by sudo`, and so on. The core system can only move together with the full
  `-Syu`, so **Stage 2 is folded into Stage 3 this time.** The full upgrade (230 packages,
  `--ignore hyprland`) resolves with no errors.
- **AUR packages that depend on `openssl`:** `spotify` and `dotnet-runtime-9.0-bin`.
  Both have pending AUR updates (Stage 4). Test them after the upgrade.
- Stage 1 updates only part of the system, which Arch doesn't support as a long-lived
  state. Run Stage 1 → 3 in one sitting.

### What changed in our Omarchy setup (why plain `omarchy-update` is OK now)

The README's *Oct 2026: Qt 6.12 broke the shell* section says not to run plain
`omarchy-update` and to use a revert/update/re-patch one-liner instead. **That's
outdated.** Since then the patch became local commits in the Omarchy checkout:

- `694d6dea7` Rename `Color` singleton to `ThemeColor` for Qt 6.12
- `f48409f96` Move qconsole seeding to `workspace.created`
- `a807ed1de` `omarchy-update-dev` now uses `git pull --rebase` instead of `--ff-only`,
  so the local commits are replayed on top of upstream instead of aborting the update

Upstream still uses the bare `Color` singleton, so the fix is still needed. A follow-up
task is to update the README section to match (see *Follow-ups*).

## Stages

### Stage 0: Snapshot ✅

```bash
sudo snapper -c root create -d "before staged update 2026-11-19" -p   # → 40
```

Rollback: `omarchy snapshot restore`, or `sudo snapper rollback 40` and reboot.
`omarchy-update` takes its own snapshot as well in Stage 3.

### Stage 1: Mac hardware (keyrings + graphics) ✅

```bash
sudo pacman -Sy --needed archlinuxarm-keyring asahi-alarm-keyring
sudo pacman -S --needed mesa vulkan-asahi vulkan-mesa-implicit-layers
```

pacman may pull in newer `llvm-libs` / `libdrm` as dependencies. That's expected.

**Done check:** `pacman -Q mesa` shows `26.3.1`. Reboot is not required, but the new
Mesa only applies to apps started afterwards.

### Stage 2: Kernel and core system (⏭ folded into Stage 3 this round)

**Skip as a separate step this time.** See the openssl risk note: the new systemd needs
openssl 4, and openssl 4 breaks every package built on openssl 3 until those packages
are upgraded in the same transaction. No kernel or boot-chain update is pending either.
The commands below are kept for future rounds where the core *can* move alone. Always
dry-run them first with `pacman -S --needed --print ...`.

```bash
sudo pacman -S --needed systemd systemd-libs systemd-resolvconf systemd-sysvcompat \
  dbus openssl pacman qt6-base
```

If pacman wants extra packages as dependencies, let it, but read the list first.
Stop if it proposes removing anything unexpected.

Then check the boot image and reboot:

```bash
grep -E "Image generation successful|error" /var/log/pacman.log | tail -3
sudo reboot
```

**Done check after reboot:** `systemctl --failed` is empty (ignore `wlan`/`wpa_supplicant`
noise), the bar and launcher draw in colour, and `curl -sI https://archlinux.org | head -1`
and `ssh -T git@github.com` work, which proves openssl 4 is fine.

### Stage 3: Omarchy and apps (the remaining repo packages)

```bash
omarchy-update
```

What it does: prunes the pacman cache, takes a snapshot, pulls the Omarchy checkout with
`--rebase` (replaying our 3 local commits), runs migrations, then
`pacman -Syu --ignore hyprland`, then AUR updates. If the rebase hits a conflict, stop. Run
`git -C ~/.local/share/omarchy status` and resolve it by hand. Don't force anything.

This round it also carries the core system (systemd, dbus, openssl 4, pacman, qt6-base),
so **reboot afterwards** and run Stage 2's after-reboot checks too (`systemctl --failed`,
`curl`, `ssh -T git@github.com`, `sudo true`).

**Done check:**

- `checkupdates | wc -l` is 0, or only `hyprland*` is left
- `git -C ~/.local/share/omarchy log --oneline @{u}..HEAD` still lists the 3 local fixes
- `grep -c ThemeColor ~/.local/share/omarchy/shell/Commons/qmldir` is 1, **or** upstream
  has fixed the bug (`grep -c "Commons.Color" ~/.local/share/omarchy/shell/plugins/bar/Bar.qml` ≥ 1).
  If upstream has fixed it, our rename commit can be dropped.
- Bar, Super+Space launcher, menus and notifications all draw in colour
- Reboot if `omarchy-update` asks for one

### Stage 4: AUR packages

`omarchy-update` normally covers these. Check for anything left over:

```bash
yay -Qua
yay -Sua      # only if anything remains
```

**Done check:** `yay -Qua` is empty. Launch Spotify once to confirm it starts.

## Progress Log

Append one line per event: date, stage, outcome. Newest last.

- 2026-11-19: Surveyed state (230 repo, 3 AUR). Snapshot **#40** created. Stage 0 ✅
- 2026-11-19: Plan written. Next: Stage 1
- 2026-11-19: Keyrings already current. Dry runs: Stage 1 clean (3 pkgs). Stage 2 impossible on its own (openssl 4 soname bump). Folded into Stage 3. Nothing installed yet.
- 2026-11-19: Stage 1 ✅ mesa, vulkan-asahi, vulkan-mesa-implicit-layers → 26.3.1-1. (A `!` pacman run in Claude Code cannot answer the Y/n prompt; it aborted harmlessly.) Next: Stage 3 (`omarchy-update`) in a real terminal.

## Follow-ups (after the update)

- Rewrite the README's *Oct 2026: Qt 6.12* section. The local fix now lives as commits
  and `omarchy-update` rebases them, so the one-liner workaround is obsolete.
- Commit the pending `hypr/.config/hypr/bindings.lua` change (unbinds Super+Alt+S for Zen).
- Once complete: set `status: Shipped`, `date_work_completed`, `date_first_published`.
