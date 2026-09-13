# dotfiles-omarchy

My Omarchy configs (MacBook Air M2, Asahi Linux), managed with GNU Stow. To install Omarchy on
Apple Silicon, see [Up and Running with Omarchy on Apple Silicon](https://github.com/lossless-group/lossless-content/blob/78c04039d0f3368cc935b60d37a084db56e53dd5/lost-in-public/up-and-running/Up%20and%20Running%20with%20Omarchy%20on%20Apple%20Silicon.md).

## Packages, Services, Software that has Dotfiles

| Package | Links |
|---|---|
| `bash` | `~/.bashrc` |
| `starship` | `~/.config/starship.toml` |
| `nvim` | `~/.config/nvim` |
| `hypr` | `~/.config/hypr` |
| `omarchy` | `~/.config/omarchy` |
| `git` | `~/.config/git` |
| `gh` | `~/.config/gh/config.yml` |
| `mise` | `~/.config/mise` |
| `atuin` | `~/.config/atuin/config.toml` |
| `helix` | `~/.config/helix/config.toml` |
| `superfile` | `~/.config/superfile/` |

## Setup

```bash
git clone https://github.com/mpstaton/dotfiles-omarchy.git ~/code/dotfiles
cd ~/code/dotfiles
stow -n -v */                                     # lists conflicts; move those aside first
mkdir -p ~/.config/gh ~/.config/superfile/theme  # keep gh login and stock themes out of the repo
stow */
ln -s ~/.local/state/omarchy/current/theme/neovim.lua nvim/.config/nvim/lua/plugins/theme.lua
```

Secrets go in `~/.secrets`, which `.bashrc` loads and git ignores.

---

## Extra software

Everything here is installed and working on this machine. All of it except Zen is a
prebuilt aarch64 package from Arch Linux ARM's `extra` repo or the `[omarchy-aarch64]` repo,
so nothing compiles.

### Install

```bash
# dotfile symlink manager, editor, file manager, screen recorder
sudo pacman -S --needed stow helix superfile obs-studio

# Zen Browser: AUR zen-browser-bin repackages Zen's official aarch64 build.
# Omarchy's installer also writes Zen's policies and wires up the default-browser menu.
omarchy install browser zen

# GitHub CLI comes from mise, not pacman
mise use -g gh@latest
```

### Notes

- **Helix** installs its command as `helix`, not `hx` (another package already owns `hx`).
- **Superfile** runs as `spf`. The AUR `superfile` package is x86_64-only, so use `extra`.
- **OBS Studio** is skipped by the Apple Silicon Omarchy installer, but plain `obs-studio`
  from `[omarchy-aarch64]` installs in seconds. Don't use `yay` for it: the AUR variant
  pulls `obs-studio-browser`, which compiles for ~3 hours and then fails on aarch64.
  Encoding is software-only (x264), because Asahi has no video encoder yet.
- **Zen** opens floating by default. `~/.config/hypr/hyprland.lua` tiles it with
  `o.window({ tag = "firefox-based-browser" }, { tile = true })`.

---

## Core cross-device services

These are what make jumping between machines seamless: the same passwords and the same
shell history everywhere. Set them up on every machine, right after the extra software.

### Install

```bash
# 1Password desktop app (official arm64 build), 1password-cli, and the Chromium extension
omarchy install service 1password

# Atuin shell history (it bundles bash-preexec; the package is a harmless fallback)
sudo pacman -S --needed atuin bash-preexec
```

### 1Password

- The AUR `1password` package is x86_64-only. Omarchy's installer uses 1Password's official
  arm64 tarball instead (installed to `/opt/1Password`), so it doesn't update through
  pacman.
- It also installs `1password-cli` (`op`) and adds the 1Password extension to Chromium.
  Restart Chromium to load the extension.
- Zen isn't covered: install the 1Password extension from Firefox Add-ons.
- Sign in to your account in the app.

### Atuin

Omarchy doesn't set Atuin up. To sync history with other machines, log in (the server defaults
to `https://api.atuin.sh`):

```bash
atuin login
```

Enter the username and password. At *"enter key or leave blank to use existing key file"*,
paste the 24-word key phrase. Don't leave it blank on a new machine: that creates a fresh key
that can't read the synced history. To print the phrase, run this on a machine that already
syncs:

```bash
atuin key
```

Then pull history:

```bash
atuin sync
```

The key is saved to `~/.local/share/atuin/key`, never in this repo. Atuin takes over
**Ctrl+R** because `~/.bashrc` loads it after Omarchy's rc.

#### If sync says the key can't decrypt the server data

*"Your local encryption key cannot decrypt the data on the server"* means some records on the
server were written with a different key. On this machine only an old host's records were
unreadable, and this fixed it without making a new key:

```bash
atuin store purge            # delete local records this key can't decrypt
atuin store verify           # must print: Local store encryption verified OK
atuin store push --force     # clear the server, upload the cleaned store
atuin store rebuild history  # make it searchable with Ctrl+R
atuin sync
```

A machine that is logged in with a different key switches to the shared one instead:

```bash
atuin store purge
atuin store rekey "<24-word key phrase>"
atuin sync
```

---

# Installing Omarchy on this MacBook Air

Notes from installing Omarchy on this machine, alongside macOS.

---

## This machine

| | |
|---|---|
| Model | MacBook Air 13" (`Mac14,2`, M2, 2022) |
| RAM | 8 GB |
| Internal disk | 251 GB — after install: macOS 122.55 GB, Linux 122.55 GB |
| macOS | 26.6.2 (Tahoe), build 25G83 |
| FileVault | **On** |
| Time Machine | none configured (machine set up fresh) |

M1/M2 is the well-supported Asahi generation. M3 support is recent, M4 is not supported.

---

## What this does to the disk

Apple Silicon supports multiple OSes natively — no bootloader hacks, nothing overwritten.

1. The macOS APFS container (`disk0s2`) is **shrunk in place**. macOS itself is untouched.
2. A **~2.5 GB APFS "stub" container** is created, holding a minimal macOS + recoveryOS.
   Every bootable OS on Apple Silicon needs its own container with its own boot policy —
   this stub is what makes the Mac willing to boot Linux at all.
3. A **~500 MB EFI partition** gets m1n1 + U-Boot + GRUB.
4. The remainder becomes the **Linux root**.
5. `disk0s3` (`Apple_APFS_Recovery`, 5.4 GB) is left alone.

> **Never delete `Apple_APFS_Recovery`.** Doing so makes macOS unupgradeable and the
> machine unbootable without a DFU restore.

macOS stays at **Full Security**. Permissive Security is set only on the Asahi stub's
boot policy. macOS must remain installed — it is required to update/repair m1n1 and to
resize the Asahi install later.

---

## Step 0 — pre-flight

Local APFS snapshots occupy free space and block the resize. These accumulate whether or
not a backup drive ever existed, so it is worth one check:

```bash
tmutil listlocalsnapshots /
```

On this machine this returned empty — nothing to clear. If it ever lists any:

```bash
tmutil deletelocalsnapshots <date-string>
```

Also confirm no macOS update is sitting downloaded and pending in System Settings.

---

## Step 1 — Asahi (run in macOS Terminal)

Note this is **not** `alx.sh` — that installs Fedora Asahi Remix. Omarchy needs the Arch flavor:

```bash
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

Answer the prompts:

1. **Admin password** — it needs this to touch partitions.
2. **What to install** → option **`2: Asahi Alarm Minimal (BTRFS)`**.
   BTRFS is worth it: snapshots make a bad system upgrade a rollback, not a reinstall.
   Do **not** pick a Desktop flavor (3 or 4) — Omarchy installs its own Hyprland stack.
   Do not pick 5 (UEFI only, no OS).
   When asked for an **OS name**, this install used `Omarchy` — it's the label shown in
   the boot picker, so short beats the long default.
3. **Size** → this install used **122.55 GB** (an even split). The installer
   automatically holds back 38 GB for macOS so macOS upgrades keep working.
4. It shrinks the container and writes the stub + EFI + root partitions.

### If the resize fails with "encrypted and locked volumes"

That's FileVault, which is on here. Do not abort:

```bash
diskutil apfs list | grep -i -B5 "FileVault: *Yes (locked)"
diskutil apfs unlockVolume <diskXsY>    # Data volume only — skip System volumes
```

Then re-run the installer.

### If the resize fails some other way

That usually indicates latent APFS corruption from Apple's own drivers, not Asahi.
Boot into recoveryOS (hold power → Options) and run Disk Utility First Aid on the
container, then retry.

---

## Step 2 — first boot into Linux (the unfamiliar part)

**This is the step with no automatic recovery if you get it wrong.** The installer prints
the following verbatim before shutting down. Reproduced here because you cannot read it
again once the machine powers off:

```
When the system shuts down, follow these steps:

1. Wait 25 seconds for the system to fully shut down.
2. Press and hold down the power button to power on the system.
   * It is important that the system be fully powered off before this step,
     and that you press and hold down the button once, not multiple times.
     This is required to put the machine into the right mode.
3. Release it once you see 'Loading startup options...' or a spinner.
4. Wait for the volume list to appear.
5. Choose 'Omarchy'.
6. You will briefly see a 'macOS Recovery' dialog.
   * If you are asked to 'Select a volume to recover',
     then choose your normal macOS volume and click Next.
     You may need to authenticate yourself with your macOS credentials.
7. Once the 'Asahi Linux installer' screen appears, follow the prompts.

If you end up in a bootloop or get a message telling you that macOS needs to
be reinstalled, that means you didn't follow the steps above properly.
Fully shut down your system without doing anything, and try again.
If in trouble, hold down the power button to boot, select macOS, run
this installer again, and choose the 'p' option to retry the process.

Press enter to shut down the system.
```

### The three ways people break this

1. **Not fully powered off.** Wait the full 25 seconds. A machine that isn't all the way
   down won't enter 1TR.
2. **Tapping the power button, or pressing it repeatedly.** One single press, held
   continuously, until the spinner appears.
3. **Treating step 6 as an error.** Seeing a "macOS Recovery" dialog is expected — it is
   the stub's recoveryOS. If it asks you to select a volume to recover, pick your normal
   **Macintosh HD** and authenticate.

### If it bootloops or says macOS must be reinstalled

**Do not reinstall anything.** That message means 1TR wasn't entered correctly, not that
anything is damaged. Recovery:

1. Fully shut down without touching anything else.
2. Hold the power button to boot, select **macOS**.
3. Re-run the installer:

   ```bash
   curl https://asahi-alarm.org/installer-bootstrap.sh | sh
   ```

4. Choose the **`p`** option to retry the boot-policy step.

Once the Asahi Linux installer screen appears and you follow its prompts, it sets
Permissive Security on that volume only, reboots into Linux, and drops you at a
**root console**.

### Booting between the two OSes from now on

- **Hold the power button from a full shutdown** → startup options picker → macOS or Omarchy.
- A normal restart boots straight into whichever is currently default.

---

## Step 3 — log in

Asahi Alarm drops you at a console login, not a shell. Defaults:

| user | password |
|---|---|
| `root` | `root` |
| `alarm` | `alarm` |

Log in as **`root` / `root`**. Change both immediately:

```bash
passwd            # root
passwd alarm
```

---

## Step 4 — get networking up

First thing at the root console:

```bash
nmtui
```

Choose *Activate a connection* and join Wi-Fi.

If `nmtui` throws an error immediately after activating, **reboot and try again** — known quirk.

If it still won't cooperate:

```bash
nmcli device status
nmcli device wifi list ifname wlan0
nmcli device wifi connect "SSID_NAME" password "PASSWORD" ifname wlan0
systemctl restart NetworkManager
journalctl -u NetworkManager -b
```

> **No `sudo` yet.** The minimal image may not ship `sudo` at all, and you're logged in as
> root anyway — drop the `sudo` prefix from any command you copy in at this stage or you'll
> get `command not found`. Step 5a installs it when you create your user.

---

## Step 5 — install Omarchy with `malik-na/omarchy-mac`

This machine runs **[malik-na/omarchy-mac](https://github.com/malik-na/omarchy-mac)** (GitHub,
branch `quattro`, Omarchy 4.0.3), cloned into `~/.local/share/omarchy` and installed as a
regular user.

The full write-up, with the reasoning and every error along the way:
[Up and Running with Omarchy on Apple Silicon](https://github.com/lossless-group/lossless-content/blob/78c04039d0f3368cc935b60d37a084db56e53dd5/lost-in-public/up-and-running/Up%20and%20Running%20with%20Omarchy%20on%20Apple%20Silicon.md).

### 5a — create your user (root console)

This port expects you to create the user yourself. Still at the Asahi root console:

```bash
pacman -S --needed sudo git base-devel
useradd -m -G wheel -s /bin/bash <username>
passwd <username>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -c
```

The last command must print `parsed OK`. Then verify from a **fresh login** — a shell opened
before the group change carries stale group membership:

```bash
su - <username>
id            # must list wheel
sudo -v       # password, then silence = working
```

From here on, everything runs **as your user, with `sudo`** — not as root. Omarchy writes
`~/.config/hypr`, `~/.local/share/omarchy` and systemd `--user` units; run as root and all of
it lands in `/root`.

### 5b — pre-empt the two known blockers

Both stop the installer partway if you skip them.

Refresh the package databases. A stale `extra` is what produces
`target not found: hyprland-guiutils`:

```bash
sudo pacman -Syy
pacman -Si hyprland-guiutils        # expect: Repository : extra
```

Allow the repo key's SHA-1 self-signature, which GnuPG 2.4+ rejects by default:

```bash
echo 'allow-weak-key-signatures' | sudo tee -a /etc/pacman.d/gnupg/gpg.conf
```

This has to go in gpg's config. The installer takes no flags, so passing
`--allow-weak-key-signatures` to it does nothing.

If an earlier attempt with another port left a cached `omarchy.db` behind (this machine had
one), clear it:

```bash
sudo rm -f /var/lib/pacman/sync/omarchy.db /var/lib/pacman/sync/omarchy.db.sig
sudo pacman -Syy
```

### 5c — install

```bash
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
bash install.sh
```

- **No flags.** The installer ignores its arguments.
- **yay is handled for you.** If `yay` is missing, the installer clones it from the AUR and
  builds it.
- **Package repositories are added for you.** The installer appends `[omarchy-aarch64]`
  (`omarchy-mac/omarchy-pkgs-aarch64`, prebuilt aarch64 packages), and Omarchy's system setup
  adds `[omarchy]` (`pkgs.omarchy.org`).

This machine built yay by hand before running the installer. Not necessary, but this is what
ran — yay from source needs Go, so `go-bin` came first:

```bash
git clone https://aur.archlinux.org/go-bin.git
cd go-bin
makepkg
cd ..
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -sri
cd ..
```

Two prompts to expect:

- `hyprland is in IgnorePkg/IgnoreGroup. Install anyway?` → **y**. That's the installer managing
  repo overlap deliberately.
- `No aarch64 build is known for: obs-studio dotnet-runtime pinta obsidian … Try building them
  anyway?` → **n**. On 8 GB these are long compiles with a real chance of OOM, and one failure
  can take the whole run with it. OBS Studio installs fine afterwards from `[omarchy-aarch64]`
  (see *Extra software* near the top).

The Omarchy setup itself takes under a minute and ends by installing 1Password. Its log is
`/var/log/omarchy-install.log`.

### 5d — reboot

```bash
sudo reboot
```

That reboot brings up Hyprland. Two things after the first login:

- `~/.local/state/omarchy/first-run.log` may show `Failed: enable user systemd units`. First-run
  retries failed steps at the next login.
- The hostname is still Arch Linux ARM's default, `alarm`. Rename it:

```bash
sudo hostnamectl set-hostname m2omarchy
```

### Troubleshooting

#### `third party key signatures using SHA1 are rejected`

GnuPG 2.4+ rejects the repo key's SHA-1 self-signature. Allow it in gpg's config (5b):

```bash
echo 'allow-weak-key-signatures' | sudo tee -a /etc/pacman.d/gnupg/gpg.conf
```

#### `signature ... is invalid` / `database omarchy is not valid`

A cached `omarchy.db` from an earlier attempt with another port. Clear it (5b):

```bash
sudo rm -f /var/lib/pacman/sync/omarchy.db /var/lib/pacman/sync/omarchy.db.sig
sudo pacman -Syy
```

#### `target not found: hyprland-guiutils`

A stale local database, not a missing package:

```bash
sudo pacman -Syy
```

If it's still missing, your mirror is lagging. Point pacman at the main Arch Linux ARM mirror:

```bash
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo 'Server = http://mirror.archlinuxarm.org/$arch/$repo' | sudo tee /etc/pacman.d/mirrorlist
sudo pacman -Syy
```

A package appearing in two repos is normal. pacman takes the **first repository in
`pacman.conf` order** that carries it; version is not the tiebreaker across repos.

#### `No aarch64 build is known for …`

Answer **n** and add those packages individually later, where each can fail on its own.

#### `makepkg` refuses to run as root

By design: a PKGBUILD runs arbitrary build code. Build as your user. A package you build still
installs system-wide.

#### `<user> is not in the sudoers file`

The sudoers drop-in is missing, has the wrong mode, or the shell predates the group change.
`sudo` ignores `/etc/sudoers.d/` files that aren't mode `0440` or whose names contain a `.`.
Redo 5a at the root console, then log in fresh.

#### A download writes no file and prints no error

curl's `-f` flag exits silently on a 404. Drop `-f` while debugging.

#### Globs for built packages match nothing

Arch Linux ARM ships `.pkg.tar.xz`, not mainline Arch's `.pkg.tar.zst`.

---

## Hardware support on this exact model

From the [Asahi M2 feature table](https://asahilinux.org/docs/platform/feature-support/m2/)
for MacBook Air 13" M2:

**Working** — display, GPU (Vulkan via Mesa), keyboard, keyboard backlight, trackpad,
brightness, Wi-Fi, Bluetooth, speakers, 3.5mm jack, microphones, webcam, battery info, suspend

**Not working**
- **Touch ID** — TBA, no active development
- **External displays / DisplayPort alt-mode** — WIP at the SoC level. USB2 and USB3 over
  the Type-C ports do work.

HDMI / SD card / Ethernet show as unsupported only because the Air doesn't have them.

8 GB RAM is fine for Hyprland, tight with a browser plus a compile running.

---

## Keeping it alive

This is Arch ARM plus `linux-asahi`, which must stay in lockstep with Mesa and the Asahi
firmware, plus a third-party Omarchy layer on top. Leaving it untouched for a month and
then running a full upgrade is the classic way to break it.

 - Update deliberately, not after long gaps.
 - If installed on BTRFS, snapshot before updating.

---

## Uninstalling

No automated uninstaller. From macOS, **after setting macOS as the default boot OS again**:

```bash
diskutil apfs deleteContainer diskN        # the 2.5 GB stub
diskutil eraseVolume free free disk0sX     # the EFI partition
diskutil eraseVolume free free disk0sY     # the Linux root
diskutil apfs resizeContainer disk0s2 0    # return the space to macOS
```

Substitute your real identifiers — they differ per machine. The final command can freeze
Terminal for several minutes; that's normal.

**Never touch `disk0s3` (`Apple_APFS_Recovery`).**

---

## References

- Asahi Linux FAQ — https://asahilinux.org/docs/project/faq/
- M2 feature support — https://asahilinux.org/docs/platform/feature-support/m2/
- Partitioning cheatsheet — https://asahilinux.org/docs/sw/partitioning-cheatsheet/
- Asahi Alarm — https://asahi-alarm.org/
- malik-na/omarchy-mac (used on this machine) — https://github.com/malik-na/omarchy-mac
- Up and Running with Omarchy on Apple Silicon — https://github.com/lossless-group/lossless-content/blob/78c04039d0f3368cc935b60d37a084db56e53dd5/lost-in-public/up-and-running/Up%20and%20Running%20with%20Omarchy%20on%20Apple%20Silicon.md
- Omarchy Manual, "Omarchy on…" — https://learn.omacom.io/2/the-omarchy-manual/79/omarchy-on
