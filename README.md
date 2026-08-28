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

| Path | What it is |
| --- | --- |
| `.zshrc`, `.gitconfig`, `.gitignore_global` | Shell and git config |
| `.Brewfile` | Homebrew taps/formulae/casks, VS Code extensions, global npm packages (generated via `brew bundle dump`) |
| `.config/nvim`, `.hammerspoon` | Submodules pointing at their own repos ([config-nvim](https://github.com/matt-heindel-gl/config-nvim), [config-hammerspoon](https://github.com/matt-heindel-gl/config-hammerspoon)) |
| `.config/duti/*.duti` | Finder default-app associations, applied with [duti](https://github.com/moretension/duti). `default-editor.duti` routes text/code files to the "Edit in Ghostty" droplet (below); `ghostty-terminal.duti` makes Ghostty the handler for `.command` files and executable shell scripts |
| `.config/edit-in-ghostty/` | Source + build script for "Edit in Ghostty.app", a small AppleScript droplet (not itself trackable here since it installs to `/Applications`, outside `$HOME`) that opens a new Ghostty tab and runs `nvim` on whatever file Finder hands it, reusing the existing window instead of spawning a new one. Re-run `build.sh` any time the `.applescript` source changes |
| `.config/herdr/config.toml` | herdr keybindings (the rest of `.config/herdr/` is session logs/sockets, not tracked) |
| `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/statusline-command.sh` | Claude Code global config — instructions, permissions/model/plugin settings, statusline script. The rest of `~/.claude/` (conversation history, session state, auth caches) is deliberately not tracked |

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

# 6. Build the Finder default-editor droplet and apply file-association
#    defaults (see .config/edit-in-ghostty/ and .config/duti/ above)
"$HOME/.config/edit-in-ghostty/build.sh"

# 7. Restart the shell to pick up .zshrc (installs oh-my-zsh/nvm on first
#    run if not already present — see .zshrc for what it expects)
exec zsh
```

Then, manually (can't be scripted):

- Open **Hammerspoon** once and grant it Accessibility permissions in
  System Settings → Privacy & Security.
- Open **nvim** and let the plugin manager sync on first launch.
- `gh auth login` for GitHub CLI, and set up SSH keys separately if you want
  SSH remotes instead of HTTPS (keys are intentionally not in this repo).
- The first time you open a file via Finder (or `open`), macOS will prompt
  to let "Edit in Ghostty" control Ghostty — approve it, or the droplet
  fails silently instead of opening the file.

## Day-to-day usage

The `dotfiles` alias (defined in `.zshrc`) is just `git` scoped to this repo:

```bash
dotfiles status
dotfiles add .some_new_dotfile
dotfiles commit -m "..."
dotfiles push
```
