---
type: Plans
title: "Back Up, Then Install the New Omarchy for Apple Silicon"
lede: "The omarchy-mac fork is frozen. Move the MacBook Air M2 to the official Omarchy for Apple Silicon: back up, remove the old install from macOS, install fresh, restore."
publish: true
date_created: 2026-11-23
date_modified: 2026-11-23
date_authored_initial_draft: 2026-11-23
date_authored_current_draft: 2026-11-23
date_authored_final_draft:
authors:
  - mps
augmented_with:
  - Claude Code on Claude Opus 5.5
at_semantic_version: 0.0.1.0
status: Planned
site_uuid: 555b9fc5-147f-4dfe-9ef1-6ab6d8d090be
hex_code: ktune8
tags:
  - Omarchy
  - Asahi-Linux
  - Reinstall
  - Backups
summary: "Runbook for moving the MacBook Air M2 (2022, apple,j413 / t8112) from the frozen malik-na/omarchy-mac dev checkout to the official Omarchy for Apple Silicon. There is no in-place upgrade. Steps 2-5 run in macOS."
---

# Back Up, Then Install the New Omarchy for Apple Silicon

## Why Care?

On 2026-11-23, `omarchy update` failed while rebasing the dev checkout
(`~/.local/share/omarchy`, branch `quattro`). Upstream had pushed
`5ccd72e5f`, "Freeze Omarchy Mac installs and point them to Omarchy for Apple
Silicon (#804)". That commit rewrote `bin/omarchy-update-dev`, the same file as
the local fix `f137d732c` (pull with `--rebase`), so the rebase stopped on a
conflict.

The conflict is already resolved. `f137d732c` was skipped because upstream no
longer pulls the checkout, so that fix is obsolete. The two other local fixes
are still on top:

- `da2b4c2b3` Local fix: rename Color singleton to ThemeColor for Qt 6.12
- `0b65a9237` Local fix: move qconsole seeding to workspace.created

`f137d732c` is still in the reflog if it is ever needed.

**What the freeze means:**

- The current install keeps running and its system packages still update.
- `omarchy update` no longer pulls the checkout. It prints a notice that the
  checkout is frozen, and no further Omarchy changes arrive.
- There is no deadline and no in-place upgrade. The supported path is: back up,
  remove the old install, install fresh, restore.

## Is it Asahi?

Yes, both before and after.

- **Old (this machine):** the `omarchy-mac` fork was installed by script on top
  of Asahi Alarm (Asahi Linux, Arch Linux ARM). Running kernel:
  `7.2.12-3-1-ARCH`.
- **New:** the official Omarchy Installer is a macOS app that runs a "pinned
  Asahi-based engine" (an Asahi installer source lock with an Omarchy Python
  overlay). It shrinks the macOS APFS container, writes the boot stub and EFI,
  and finishes in macOS Recovery, the same boot chain Asahi uses. The Mac
  packages (`omarchy-mac`, `omarchy-mac-boot` in `omacom/omarchy-mac-pkgs`)
  credit Asahi Linux and Asahi Alarm.

The difference is packaging and ownership, not the Linux base. The setup is now
an official Omacom product with a GUI installer, signed catalogs, and packages
from pkgs.omarchy.org, not a community fork pulled as a git checkout.

## Compatibility

- Machine: **MacBook Air (13-inch, M2, 2022)**, which is on the supported list.
  M4 and newer are not supported yet.
- Requires macOS 15 Sequoia or later and a macOS administrator account.
- The install downloads several gigabytes, so keep the Mac on power with an
  internet connection.

## Sources

- Official guide, "Coming from Omarchy Mac":
  https://github.com/omacom/omarchy/blob/quattro/manual/44-mac-support.md#coming-from-omarchy-mac
- Installer: https://github.com/omacom/omarchy-mac-installer (README covers
  release channels, updating the installer, removing Omarchy)
- Installer releases: https://github.com/omacom/omarchy-mac-installer/releases
- Help: Omarchy Discord, https://discord.gg/tXFUdasqhY

Open the guide on your phone before restarting, because steps 2-5 happen in
macOS.

## Steps

### 1. Back up from Omarchy, off the Mac

Removing the old install erases it, and macOS cannot read the Omarchy disk.

- [ ] Find git repos with uncommitted or unpushed work, and commit and push
      them. This repo (`~/code/dotfiles`) is 4 commits ahead of `origin/main`
      with uncommitted changes to `hypr/.config/hypr/bindings.lua` and
      `omarchy/.config/omarchy/shell.json`.
- [ ] Save the package list: `pacman -Qqe > ~/packages.txt`
- [ ] Copy the home folder (about 33 GB) to an external drive or another
      computer. Include:
  - [ ] `~/.ssh`
  - [ ] GPG keys (`~/.gnupg`, or an export with `gpg --export-secret-keys`)
  - [ ] Browser profiles
  - [ ] `~/code` and any unpushed work
  - [ ] `~/.claude` (memory, settings)
- [ ] Note the two local Omarchy fixes above, and check after the reinstall
      whether the official release still needs them.
- [ ] Back up macOS too, for example with Time Machine. Removing and installing
      both resize the macOS disk.

### 2. Start up in macOS

Shut down. Hold the power button until "Loading startup options" appears, then
choose macOS.

### 3. Install the Omarchy Installer (in macOS)

```sh
brew install omacom/mac/omarchy
```

Or download the newest Omarchy Installer from the releases page and open it.

### 4. Remove the old install

In the installer, choose **Installation > Remove Omarchy**. It shows what it
will delete and gives the space back to macOS. If it does not recognize the
install, it stops without changing the disk. In that case, ask in Discord.
**Do not delete partitions by hand, because that can erase macOS.**

### 5. Install Omarchy for Apple Silicon

Use the same installer. It checks the Mac, shows the plan, and lets you change
the Omarchy partition size. It holds **Install** until the download is verified
and the backup box is ticked. After the first stage:

1. Shut down, hold the power button until "Loading startup options" appears,
   choose **Omarchy**, click Continue, and sign in with the macOS account.
2. The Recovery app installs and enrolls the startup software, then shows
   **Installation complete!** Click Restart.
3. On first boot, set the disk encryption password. **There is no recovery
   key. If the password is lost, the Omarchy files cannot be recovered.**

To switch between operating systems later, shut down, hold the power button,
and pick one.

### 6. Restore files, a piece at a time

- [ ] Restore `~/.ssh`, GPG keys, and `~/code`.
- [ ] Re-stow dotfiles from this repo. Do not copy all of `~/.config` over the
      new defaults, because old settings can override them.
- [ ] Reinstall packages from `packages.txt` selectively. Some may not exist
      on the new package sources.
- [ ] Re-stow agent skills:
      `stow -R -d ~/code/lossless-monorepo/context-v -t ~/.claude/skills agent-skills`
- [ ] Check whether the two local Omarchy fixes (ThemeColor rename, qconsole
      seeding) are still needed.

## Good to Know

- On M1 and M2 MacBooks, wake from sleep by opening the lid or pressing the
  power button.

## Progress Log

- 2026-11-23: The update failed because of the upstream freeze. The rebase was
  resolved by skipping `f137d732c`. Plan written.
