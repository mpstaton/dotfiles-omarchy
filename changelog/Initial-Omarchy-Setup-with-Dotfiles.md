---
date_created: 2026-09-13
date_modified: 2026-09-13
title: "Initial Omarchy Setup with Dotfiles"
lede: "The MacBook Air went from a fresh Omarchy install to a machine whose shell, editors, prompt, window manager and history all live in this repo — linked into place with GNU Stow, safe to publish, and ready to follow me to the next machine."
publish: true
authors:
  - mps
augmented_with:
  - Claude Code on Claude Opus 5 (1M context)
files_changed:
  - .gitignore
  - .stowrc
  - README.md
  - atuin/.config/atuin/config.toml
  - bash/.bashrc
  - changelog/.stow-local-ignore
  - changelog/Initial-Omarchy-Setup-with-Dotfiles.md
  - gh/.config/gh/config.yml
  - git/.config/git/config
  - helix/.config/helix/config.toml
  - hypr/.config/hypr/
  - mise/.config/mise/config.toml
  - nvim/.config/nvim/
  - omarchy/.config/omarchy/
  - starship/.config/starship.toml
  - superfile/.config/superfile/
tags:
  - Omarchy
  - Asahi-Linux
  - Hyprland
  - GNU-Stow
  - Dotfiles
  - Developer-Experience
---

# Initial Omarchy Setup with Dotfiles

## Why Care?

Until now this repo was only the install guide: how to get Omarchy onto a MacBook Air M2
alongside macOS. Once Omarchy was running, every tweak made afterwards lived only on this
laptop — the prompt, the gaps, the editor plugins, the shell history setup.

The point of this change is **jumping machines**. I work across the Mac, the System76 NixOS
box, and now this Omarchy laptop, and I switch between them all day. A config that exists on
one machine is a config I will rebuild by hand, slightly differently, on the next. Now the
configs live here, `~/.config/...` points back into the repo, and a new machine is a clone
and a `stow` away. The repo is public, so it also has to be safe to share with whoever I end
up collaborating with.

## What's New?

- **GNU Stow manages everything.** Each top-level folder is a Stow package mirroring `$HOME`,
  the same convention as `nix-hypr-dotfiles`. `.stowrc` sets `--target=~` because this repo
  lives at `~/code/dotfiles`, and plain `stow */` would otherwise link into `~/code`.
- **Eleven packages:** `atuin`, `bash`, `gh`, `git`, `helix`, `hypr`, `mise`, `nvim`,
  `omarchy`, `starship`, `superfile`.
- **README Step 6** lists the extra software (Stow, Helix, Superfile, OBS Studio, Zen, gh via
  mise) with the aarch64 gotchas for each.
- **README Step 7, core cross-device services** — 1Password (`omarchy install service
  1password`) and Atuin, the two things that make a machine feel like mine immediately.
- **This `changelog/`**, with a `.stow-local-ignore` so `stow */` never links it into `$HOME`.

## The Story

### The prompt that was never running

The first real surprise: the carefully ported Starship prompt didn't show up in Ghostty.
Nothing was wrong with Starship. `~/.bashrc` was still Arch's bare skeleton — a hardcoded
`PS1='[\u@\h \W]\$ '` that never loaded Omarchy's shell setup at all. That also explained
the `mps@alarm` prompt from the first boot ("alarm" is Arch Linux ARM's default hostname,
since renamed to `m2omarchy`). Replacing it with Omarchy's own `bashrc` brought in Starship,
mise, zoxide, fzf and eza in one go.

The prompt itself is the `my-tokyo` design, ported from oh-my-posh on the Mac to Starship on
NixOS and carried over from `nix-hypr-dotfiles`: the `┏ ┣ └─` markers, a git row with the
repo name, branch and status, and the date as `%Y%m%d@%H:%M:%S`. On Omarchy the NixOS
snowflake became the Arch logo and the hardcoded `sys76@` label was dropped. JetBrainsMono
Nerd Font already had every one of its 20 glyphs.

`bash/.bashrc` now opens with a warning that it lives in a public repo, loads `~/.secrets`
when that file exists, and carries the useful bits of the old zshrc (`cat` → bat,
`ll`/`la`/`l` → eza, fzf defaults, `GITHUB_API_TOKEN` read from gh's keyring at shell start).

### Folder links versus file links

The one decision that shaped every package: link the whole folder, or only the files?

Programs that save by writing a temp file and renaming it over the original silently replace
a single-file symlink with a real file, and from then on changes stop reaching the repo. The
Omarchy shell saves `shell.json` that way, Omarchy's migrations rewrite files with `mv`, and
git and mise rewrite their configs on save. So `hypr`, `omarchy`, `nvim`, `git` and `mise`
link their whole folder.

The exceptions link single files on purpose, because the folder holds things that must stay
local. `~/.config/gh` stays a real folder so gh writes `hosts.yml` there, outside the repo.
`~/.config/superfile/theme` stays real so Superfile's 21 stock themes don't flood the repo,
with only the custom `catppuccin.toml` linked in.

A welcome side effect for someone who likes to control when things change: when an Omarchy
update or `omarchy refresh` edits one of these files, the edit lands in the repo folder and
shows up in `git diff`. Nothing is committed until I decide.

### Omarchy tweaks

- **Gaps as a share of the screen.** Hyprland only accepts pixels, and the default 10px looked
  oversized on a 13" screen. `looknfeel.lua` now computes gaps per monitor from its logical
  short side (0.25% between windows, 0.5% at the edges) and re-runs on monitor hotplug. The
  rules skip special workspaces (`s[false]`) so the Quake-style scratchpad keeps its own
  sizing, and back off while Omarchy's no-gaps toggle is on.
- **Zen tiles.** Zen opened floating, which ignores gaps entirely. Omarchy tiles
  Chromium-based browsers but not Firefox-based ones, so `hyprland.lua` adds the matching
  rule for the `firefox-based-browser` tag.
- **Idle timers** in `shell.json`: screensaver at 15 minutes, lock at 30, instead of 2.5 and 5.
  Switching machines for ten minutes shouldn't mean coming back to a locked screen.

### Neovim: mirror Omarchy, add two things

Omarchy's LazyVim setup moved into the repo as-is, plus two files:

- `multicursor.lua` brings back `vim-visual-multi` from the Mac, so **Shift+Down** adds a
  cursor per line — the fast way to uncomment the file list in a git commit message. Tested
  on a fake `COMMIT_EDITMSG`: three `#` lines uncommented in one keystroke.
- `disable-monokai-pro.lua`, because `gthelding/monokai-pro.nvim` was deleted from GitHub and
  Lazy failed to clone it on every launch. It only served Omarchy 3.8 themes.

`lua/plugins/theme.lua` is the one file that can't be shared. Omarchy makes it a relative
symlink into `~/.local/state/omarchy/current/theme/neovim.lua`, and that relative path breaks
once the folder lives in the repo. It's now an absolute link, ignored by git, and each
machine recreates it with one `ln -s` (the command is in `.gitignore`). Live theme switching
still works, and Omarchy's migrations accept the absolute form.

### Superfile needed a migration, not a copy

The Mac config predated Superfile 1.6.0, and three of its values would have made it exit at
startup: `file_preview_width = 50` (now 2–10), `sidebar_width = 25` (now 5–20) and
`default_sort_type = "Name"` (now a number). The theme setting was a file path where 1.6.0
expects a name. The config was rebuilt from the 1.6.0 default with the personal values
carried across, and the hotkeys file taken from 1.6.0 unchanged — the old bindings matched it
exactly, and the five new actions don't collide with anything.

### Atuin and a key that only half worked

Logging in with the key phrase from the Mac succeeded, and the first sync failed with *"Your
local encryption key cannot decrypt the data on the server."* Deleting everything and making a
new key would have thrown away 18 months of history, so the cleanup ran on a copy of the store
first. The answer was narrower than it looked: the Mac's 26,912 records (March 2025 to today)
decrypted fine, and only 4,544 records from an older host (December 2024 – March 2025) used a
key that no longer exists. Purging those, force-pushing the cleaned store and rebuilding
history fixed sync without a new key, so the Mac needed no change. The System76 box joins by
adopting the same key (the steps are in README Step 7).

### Keeping a public repo clean

- `.gitignore` blocks `**/gh/hosts.yml`, `.secrets`, the per-machine Neovim `theme.lua`, and
  the `*.bak.*` backups made while editing.
- gh stores its token in GNOME Keyring, and git's credential helper now calls plain
  `gh auth git-credential` instead of a path with gh's version number baked into it.
- Every package was scanned for tokens, private keys, `hosts.yml` and the Atuin phrase before
  committing. The Atuin key lives in `~/.local/share/atuin/key` and never enters the repo.

## Also installed on this machine

Not tracked here, but part of getting it usable: Helix, Superfile, OBS Studio (software
x264 encoding — Asahi has no hardware encoder yet), Zen Browser from its official aarch64
build, 1Password with `op`, Atuin, and GNU Stow.
