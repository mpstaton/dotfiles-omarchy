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

## Changelog → commit → push: just do it, on every primary branch

When I say commit, ship, "let's go", or anything like it, do the whole flow without asking:
write a `changelog/` entry if `changelog-conventions` calls for one, commit per
`git-conventions`, and **push**. Then bring every primary branch the repo has
(`development`, `main`, `master`) to the same commit and push each one. This applies to
every repo, including dotfiles, context-v, and agent-skills.

- By the time I ask for a commit, the tests pass and I have checked the UI in the browser.
  Asking whether to commit or push wastes my time. Report what you pushed in one line.
- Most of my work is context files (`context-v/`, skills, plans, changelogs), so there is
  no risk to stage.
- **The only exception is a hairy build or refactor that is still in progress**, where a
  half-finished change could break things. Then push to `development` only, and promote to
  `main`/`master` once it's stable. Use this only when I've said so or it's obviously
  mid-refactor. Don't assume it.
- Pull or rebase before pushing. Never force-push a primary branch without asking. If a
  branch is protected or has diverged and can't fast-forward, say so in one line and carry
  on with the others.
