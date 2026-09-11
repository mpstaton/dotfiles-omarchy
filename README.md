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

## Step 3 — get networking up

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
sudo systemctl restart NetworkManager
sudo journalctl -u NetworkManager -b
```

---

## Step 4 — install Omarchy

Primary route: **[maralcbr/omarchy-mx-mac](https://github.com/maralcbr/omarchy-mx-mac)** —
targets Omarchy 4 "Quattro", GPG-signed installers, automated end to end.

```bash
pacman -Syu --needed curl gnupg linux-asahi-headers networkmanager iwd

release=https://github.com/maralcbr/omarchy-pkgs/releases/download/asahi-quattro-channel-25
curl -fLO "$release/install-asahi-quattro"
curl -fLO "$release/install-asahi-quattro.sig"
curl -fLO https://raw.githubusercontent.com/maralcbr/omarchy-mx-mac/main/default/omarchy-release.gpg
gpgv --keyring ./omarchy-release.gpg install-asahi-quattro.sig install-asahi-quattro
bash install-asahi-quattro --fresh
reboot
```

> **Check the channel number.** `asahi-quattro-channel-25` is the only line here that goes
> stale. Confirm the latest at https://github.com/maralcbr/omarchy-pkgs/releases

### If mirrors are slow or failing

```bash
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo nano /etc/pacman.d/mirrorlist
# move a US mirror to the top:
#   Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
sudo pacman -Syyu
```

### Fallback route

**[omacom/omarchy-mac](https://github.com/omacom/omarchy-mac)** (source on Codeberg, lives
under DHH's GitHub org, active Discord). Fully manual — more steps, more people to ask:

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

# yay
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# omarchy
git clone https://codeberg.org/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy && bash install.sh
# if mirrors fail: bash fix-mirrors.sh
```

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
