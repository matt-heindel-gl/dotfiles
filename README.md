# dotfiles

Personal machine config, tracked as a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles)
checked out directly against `$HOME` — no symlinks, no extra tooling.

**This repo is public.** That's intentional (so it can be forked to a
personal account), but it means the usual rule applies with no exceptions:

- **Never** run `dotfiles add -A`, `dotfiles add .`, or `dotfiles commit -a`.
  Always add files by explicit name. Blanket adds are how secrets end up in
  dotfiles repos — `$HOME` is full of things that must never be tracked.
- **Never** commit: `.npmrc` (registry auth tokens), anything under `.ssh/`
  (private keys), `.aws/`, `.env` files, or anything under `.claude/` besides
  hand-picked config files (it holds session state).
- If something sensitive ever does get committed: **deleting it in a later
  commit is not enough** — it's still in history, and once this is forked,
  rewriting history here won't reach the fork or anyone who already cloned
  it. Rotate/revoke the credential immediately and treat it as burned.

## What's here

- `.zshrc`, `.gitconfig`, `.gitignore_global` — shell and git config
- `.Brewfile` — Homebrew taps/formulae/casks, VS Code extensions, global npm
  packages (generated via `brew bundle dump`)
- `.config/nvim`, `.hammerspoon` — submodules pointing at their own repos
  ([config-nvim](https://github.com/matt-heindel-gl/config-nvim),
  [config-hammerspoon](https://github.com/matt-heindel-gl/config-hammerspoon))

## Bootstrapping a new machine

```bash
# 1. Xcode command line tools (git, etc.)
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Clone this repo as a bare repo directly into $HOME
git clone --bare https://github.com/matt-heindel-gl/dotfiles.git "$HOME/dotfiles.git"
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'

# core.bare must be false with core.worktree set explicitly, or `dotfiles
# submodule ...` refuses to run ("cannot be used without a working tree") —
# git-submodule doesn't honor a plain --work-tree flag the way other
# subcommands do.
dotfiles config --local core.bare false
dotfiles config --local core.worktree "$HOME"
dotfiles config --local status.showUntrackedFiles no

# 4. Back up anything that would collide with tracked files (fresh macOS
#    ships a default .zshrc etc.), then check out
mkdir -p .dotfiles-backup
dotfiles checkout 2>&1 | grep -E "^[[:space:]]+\." | awk '{print $1}' | while read -r f; do
  mkdir -p ".dotfiles-backup/$(dirname "$f")"
  mv "$f" ".dotfiles-backup/$f"
done
dotfiles checkout

# submodule commands specifically need cwd == $HOME and no --work-tree flag
# (see note above) — the plain `dotfiles` alias won't work for this one line
(cd "$HOME" && git --git-dir="$HOME/dotfiles.git" submodule update --init --recursive)

# 5. Install everything Homebrew knows about (formulae, casks, VS Code
#    extensions, global npm packages)
brew bundle install --file="$HOME/.Brewfile"

# 6. Restart the shell to pick up .zshrc (installs oh-my-zsh/nvm on first
#    run if not already present — see .zshrc for what it expects)
exec zsh
```

Then, manually (can't be scripted):

- Open **Hammerspoon** once and grant it Accessibility permissions in
  System Settings → Privacy & Security.
- Open **nvim** and let the plugin manager sync on first launch.
- `gh auth login` for GitHub CLI, and set up SSH keys separately if you want
  SSH remotes instead of HTTPS (keys are intentionally not in this repo).

## Day-to-day usage

The `dotfiles` alias (defined in `.zshrc`) is just `git` scoped to this repo:

```bash
dotfiles status
dotfiles add .some_new_dotfile
dotfiles commit -m "..."
dotfiles push
```
