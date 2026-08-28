# dotfiles

Personal machine config, tracked as a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles)
checked out directly against `$HOME` — no symlinks, no extra tooling.

## What's here

- `.zshrc`, `.gitconfig`, `.gitignore_global` — shell and git config
- `.Brewfile` — Homebrew taps/formulae/casks, VS Code extensions, global npm
  packages (generated via `brew bundle dump`)
- `.config/nvim`, `.hammerspoon` — submodules pointing at their own repos
  ([config-nvim](https://github.com/matt-heindel-gl/config-nvim),
  [config-hammerspoon](https://github.com/matt-heindel-gl/config-hammerspoon))

Deliberately **not** tracked, even though present on this machine: `.npmrc`
(has a live registry auth token) and anything under `.ssh/` (private key).
This repo is public — never add secrets to it.

## Bootstrapping a new machine

```bash
# 1. Xcode command line tools (git, etc.)
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Clone this repo as a bare repo directly into $HOME
git clone --bare https://github.com/matt-heindel-gl/dotfiles.git "$HOME/dotfiles.git"
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'

# 4. Back up anything that would collide with tracked files (fresh macOS
#    ships a default .zshrc etc.), then check out
mkdir -p .dotfiles-backup
dotfiles checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | xargs -I{} mv {} .dotfiles-backup/{}
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
dotfiles submodule update --init --recursive

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
