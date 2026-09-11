# dotfiles-omarchy

Installing **Omarchy** (Arch + Hyprland) alongside macOS on a **MacBook Air M2** via Asahi Linux.

Written to be readable from a phone or another machine, because partway through this you
will be sitting at a bare Arch console with no browser and no way back to the terminal
session where these instructions were written.

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
   BTRFS is worth it: snapshots make a bad `pacman -Syu` a rollback, not a reinstall.
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
3. Re-run the installer: `curl https://asahi-alarm.org/installer-bootstrap.sh | sh`
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
> get `command not found`. Install it later if you want it: `pacman -S --needed sudo`.

---

## Step 5 — install Omarchy

Primary route: **[maralcbr/omarchy-mx-mac](https://github.com/maralcbr/omarchy-mx-mac)** —
targets Omarchy 4 "Quattro", GPG-signed installers, automated end to end.

### Read this before you type anything

Three things that are not obvious and will cost you an evening each:

1. **Do not pre-create your user.** The installer creates it (`useradd --create-home
   --groups wheel`) and writes its own `/etc/sudoers.d/10-omarchy-wheel`. It **refuses**
   any account it did not create — `User already exists outside this release
   installation` or `The target user is not owned by this installation`.
2. **Do not install `yay`, and do not build anything from the AUR.** Every package
   Omarchy needs is prebuilt for `aarch64` and published as a signed pacman repo at
   [maralcbr/omarchy-pkgs](https://github.com/maralcbr/omarchy-pkgs/releases) —
   `aether`, `asdcontrol`, `cliamp`, `dotnet-runtime`, `omacut`, `yay` itself, all of
   them. **You must add that repo to `pacman.conf` yourself — the installer does not.**
   A `target not found` list of 20+ package names means the repo isn't configured yet,
   **not** that you need an AUR helper. See "Wire up the `[omarchy]` package repository".
3. **`--fresh` must run as root. Updates must NOT run as root.** The script enforces both
   directions. Fresh install → root console. Every upgrade afterwards → your regular
   Omarchy user.

### Preflight

The installer aborts on any of these, so check first:

```bash
uname -m                    # must be aarch64
pacman-conf --repo-list     # must list: asahi-alarm, core, extra, alarm, aur
```

```bash
pacman -Syu --needed curl gnupg linux-asahi-headers networkmanager iwd grub
```

`linux-asahi`, `networkmanager`, `iwd`, and `grub` must all be installed or it refuses to start.

### Find the current channel

The channel number moves every few days. Check the latest tag matching
`asahi-quattro-channel-NN` at
https://github.com/maralcbr/omarchy-pkgs/releases and substitute it below.
As of 2026-09-11 the current channel is **30**.

### Wire up the `[omarchy]` package repository — the installer does NOT do this

**This is the step that isn't in anyone's documentation, and without it the install fails
partway through with a wall of `target not found`.**

The installer downloads and verifies a six-package bundle, then runs
`pacman -Syu` for ~150 more packages it expects to come from a signed `[omarchy]`
repository. Nothing in `install-asahi-quattro` or `omarchy-install-asahi-fresh` ever
*adds* that repository — both assume it is already in `/etc/pacman.conf`. On a stock
Asahi Arch Minimal image it isn't.

Check:

```bash
grep -A2 omarchy /etc/pacman.conf
```

Empty output means you need everything below.

#### Resolving the right repository tag

The repo tag is pinned per channel, so don't guess it. Three hops:

```bash
# 1. channel pointer -> release_tag
curl -sL https://github.com/maralcbr/omarchy-pkgs/releases/download/asahi-quattro-channel-30/asahi-quattro-channel

# 2. release descriptor -> package_source_commit
curl -sL https://github.com/maralcbr/omarchy-pkgs/releases/download/asahi-quattro-aae25861/asahi-quattro-release

# 3. the repo tag is asahi-packages-stable-<package_source_commit>
```

For **channel 30** (2026-09-11) that resolves to:

| | |
|---|---|
| Release tag | `asahi-quattro-aae25861` |
| Package source commit | `ca4b5ee320a55e8a40025ec2c13c63b0c8115ac7` |
| Repo tag | `asahi-packages-stable-ca4b5ee320a55e8a40025ec2c13c63b0c8115ac7` |

That release carries 138 assets — `omarchy.db`, plus every package prebuilt for aarch64:
`yay-12.6.0-1-aarch64.pkg.tar.xz`, `obsidian-1.13.7-1`, `mise-2026.5.15-1`,
`localsend-1.17.0-3`, `aether`, `asdcontrol`, `cliamp`, `dotnet-runtime`, `omacut`, and
the rest. **Nothing compiles on the machine.**

#### Import the signing key

```bash
cd /root
curl -LO https://raw.githubusercontent.com/maralcbr/omarchy-pkgs/ca4b5ee320a55e8a40025ec2c13c63b0c8115ac7/keys/asahi-repository-signing.asc
pacman-key --init
pacman-key --add /root/asahi-repository-signing.asc
pacman-key --finger C81AC3E2A99556F9B21D5FEA3DD49BC9F8360BDC
```

`--finger` is the checkpoint — it must print a key block before you go on. Substitute the
fingerprint for the commit's own key if you're on a different channel; **type it
carefully**, a single wrong character produces `the fingerprint of a specified key could
not be determined`, which reads like a keyring failure rather than a typo.

```bash
pacman-key --lsign-key C81AC3E2A99556F9B21D5FEA3DD49BC9F8360BDC
```

##### If that fails with "third party key signatures using SHA1 are rejected"

GnuPG 2.4+ rejects SHA-1 key self-signatures, and this key's self-signature is SHA-1.
Relax it for the one operation, then put it back:

```bash
echo 'allow-weak-key-signatures' >> /etc/pacman.d/gnupg/gpg.conf
pacman-key --lsign-key C81AC3E2A99556F9B21D5FEA3DD49BC9F8360BDC
sed -i '/allow-weak-key-signatures/d' /etc/pacman.d/gnupg/gpg.conf
```

Chosen-prefix SHA-1 collisions have been practical since 2020, so the rejection isn't
theater. Signing is a one-time act — don't leave the relaxation in place.

#### Add the repository

```bash
t=asahi-packages-stable-ca4b5ee320a55e8a40025ec2c13c63b0c8115ac7
printf '\n[omarchy]\nSigLevel = Required DatabaseOptional\nServer = https://github.com/maralcbr/omarchy-pkgs/releases/download/%s\n' "$t" >> /etc/pacman.conf
rm -f /var/lib/pacman/sync/omarchy.db /var/lib/pacman/sync/omarchy.db.sig
pacman -Sy
```

Verify before going further — all three must pass:

```bash
grep -A2 omarchy /etc/pacman.conf    # prints the three-line block
pacman-conf --repo-list              # 'omarchy' is now a sixth entry
pacman -Si yay                       # resolves with 'Repository : omarchy'
```

`pacman -Si yay` is the one that matters. Until it returns a record, the installer will
fail the same way again.

> **Last-resort fallback.** If the key will not import at all, replace
> `SigLevel = Required DatabaseOptional` with `SigLevel = Optional TrustAll` in the
> `[omarchy]` block and re-run `pacman -Sy`. This disables package signature verification
> for that repository — strictly weaker than the SHA-1 workaround above, so try that
> first.

### Install

As **root**:

```bash
cd /root
u=https://github.com/maralcbr/omarchy-pkgs/releases/download/asahi-quattro-channel-30
curl -LO $u/install-asahi-quattro
curl -LO $u/install-asahi-quattro.sig
curl -LO https://raw.githubusercontent.com/maralcbr/omarchy-mx-mac/main/default/omarchy-release.gpg
gpgv --keyring ./omarchy-release.gpg install-asahi-quattro.sig install-asahi-quattro
```

`gpgv` must print **`Good signature`**. Stop if it doesn't.

> **Use `-LO`, not `-fLO`.** With `-f`, curl exits silently on a 404 and writes no file —
> you get no error and no download, which looks exactly like the command having worked.

```bash
bash install-asahi-quattro --fresh
```

It prompts for `Omarchy username:` — give it a name that **does not exist yet**. It then
prompts you to set that user's password. It also locks the stock `alarm` account and
removes it from `wheel`; that's intended.

```bash
reboot
```

That reboot is the one that brings up Hyprland.

### Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `target not found: [yay, aether, omacut, …]` | `[omarchy]` is not in `pacman.conf`; the installer never adds it | Wire up the repo first — see that section. Do not install yay. |
| `pacman -Si yay` → `package not found` after adding the repo | The `printf` appending the block never ran, or `pacman -Sy` failed | `grep -A2 omarchy /etc/pacman.conf` — empty means re-append the block |
| `the fingerprint of a specified key could not be determined` | Mistyped fingerprint, or the key was never imported | Re-run `pacman-key --finger <fpr>`; check the `.asc` starts with `BEGIN PGP PUBLIC KEY BLOCK` |
| `third party key signatures using SHA1 are rejected` | GnuPG 2.4+ rejects the key's SHA-1 self-signature | Temporarily add `allow-weak-key-signatures` to `/etc/pacman.d/gnupg/gpg.conf` |
| `Run a fresh installation as root.` | `--fresh` was run as a normal user | Run it as root |
| `Run an update as your regular Omarchy user, not root.` | Update path run as root | Run it as your Omarchy user |
| `User already exists outside this release installation` | You pre-created the account | See "Clearing a pre-created user" below |
| `The target user is not owned by this installation` | Pre-created account **plus** a partial-install checkpoint | See below |
| `Required repository 'aur' is not configured` | `pacman.conf` is missing a repo | Add it to `/etc/pacman.conf`, then re-run |
| `mps is not in the sudoers file` | Only relevant if you pre-created a user — you shouldn't have | Let the installer create the user instead |
| curl downloads nothing, no error | You used `-f` and the URL 404'd | Drop `-f`; check the channel number |

#### Clearing a pre-created user

As root. Replace `mps` with your username:

```bash
ps -u mps -o pid,args              # find live sessions
kill -9 <pid>                      # close any '-bash' login shells for that user
userdel -rf mps
getent passwd mps                  # must print nothing
rm -f /etc/sudoers.d/10-wheel      # if you hand-wrote one
rm -rf /var/lib/omarchy/fresh-install
ls /home                           # must not list the user
```

Then re-run `bash install-asahi-quattro --fresh`.

`userdel` fails while that user has a running process. A leftover `su - <user>` shell on
another virtual console (Ctrl+Alt+F2…F6) is the usual culprit.

### If mirrors are slow or failing

```bash
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
nano /etc/pacman.d/mirrorlist
# move a US mirror to the top:
#   Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
pacman -Syyu
```

### Fallback route — a different installer with different rules

**[omacom/omarchy-mac](https://github.com/omacom/omarchy-mac)** (source on Codeberg, lives
under DHH's GitHub org, active Discord). Fully manual.

> **The rules above do not apply to this route.** This one *does* expect you to create the
> user and install `yay` yourself. Don't mix the two installers' steps.

```bash
# locale
nano /etc/locale.gen          # uncomment en_US.UTF-8
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
reboot

# packages
pacman -S --needed sudo git base-devel chromium

# non-root user
useradd -m -G wheel <username>
passwd <username>
EDITOR=nano visudo             # uncomment: %wheel ALL=(ALL:ALL) ALL
su - <username>

# yay — note the AUR host; makepkg refuses to run as root, by design
git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

# omarchy
git clone https://codeberg.org/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy && bash install.sh
# if mirrors fail: bash fix-mirrors.sh
```

Arch Linux ARM builds packages as `.pkg.tar.xz`, not mainline Arch's `.pkg.tar.zst` — so
if you need to install a built package by hand it's
`pacman -U ~/yay-bin/*.pkg.tar.xz`.

Discord: https://discord.gg/KNQRk7dMzy

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
then running `pacman -Syu` is the classic way to break it.

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
- maralcbr/omarchy-mx-mac — https://github.com/maralcbr/omarchy-mx-mac
- omacom/omarchy-mac — https://github.com/omacom/omarchy-mac
- Omarchy Manual, "Omarchy on…" — https://learn.omacom.io/2/the-omarchy-manual/79/omarchy-on
