# User-level instructions

## Agent skills — single source of truth

My, my team's, and The Lossless Group's agent skills live in one repo:
`lossless-agent-skills` (https://github.com/lossless-group/lossless-agent-skills),
checked out as the submodule `~/code/lossless-monorepo/context-v/agent-skills`.

- **Edit skills only there.** On this Linux machine, `~/.claude/skills/<name>` entries for
  these skills are GNU Stow symlinks into that repo; never write real files into
  `~/.claude/skills/` for them.
  `stow -R -d ~/code/lossless-monorepo/context-v -t ~/.claude/skills agent-skills`
- **Git discipline for every change:** check the branch and `git status`, pull first, make
  focused commits per the repo's `git-conventions` skill, add a `changelog/` entry when
  `changelog-conventions` calls for one, then push (see below). Never commit inside its
  vendored submodules (`archify`, `chroma-agent-skills`).

## Lossless monorepo instructions apply everywhere

The canonical agent instructions, including the "Changelog → commit → push" rule,
live in the monorepo's `AGENTS.md` (`CLAUDE.md` there is a symlink to it). Load them in
every session, even outside the monorepo:

@~/code/lossless-monorepo/AGENTS.md
