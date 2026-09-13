# This is symlinked from dotfiles and is a public repo: mpstaton/dotfiles-omarchy.
# Don't store secrets in here. Put them in ~/.secrets instead, which is loaded below
# when it exists and is never committed.

# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.

# Secrets (API keys, tokens) live outside the repo
[[ -f ~/.secrets ]] && source ~/.secrets

# Carried over from the macOS zshrc. Omarchy already provides .., ..., bat as
# MANPAGER, and eza for ls/lsa/lt.
alias cat='bat --paging=never'
if command -v eza &> /dev/null; then
  alias ll='eza -l --icons --git'
  alias la='eza -la --icons --git'
  alias l='eza --icons'
fi

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Read from gh's keyring login at shell start, not stored here
if command -v gh &> /dev/null; then
  GITHUB_API_TOKEN=$(gh auth token 2> /dev/null) && export GITHUB_API_TOKEN
fi

# Atuin shell history (bundles bash-preexec). Loaded after Omarchy's rc so it
# takes over Ctrl+R from fzf.
if command -v atuin &> /dev/null; then
  eval "$(atuin init bash)"
fi
