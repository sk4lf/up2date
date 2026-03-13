# up2date.sh

A personal macOS maintenance script that keeps your system tools up to date with a single command.

## What it does

Runs the following update tasks sequentially:

1. **Homebrew** — `brew update` followed by `brew upgrade`
2. **Homebrew Casks** — upgrades installed casks, including greedy upgrades for casks that self-update
3. **oh-my-zsh** — upgrades the oh-my-zsh framework and its plugins

All output is logged to `~/log/up2date.sh.log` for later review.

## Quick start: full Mac migration

Dump everything on your current Mac, restore on a new one.

**On the old Mac:**

```zsh
./dump-mac.sh                          # saves to mac-snapshot/ in the script directory
./dump-mac.sh ~/backups/my-mac         # or specify a custom path
```

This captures Homebrew packages, oh-my-zsh config, dotfiles, and macOS system preferences in one go.

**On the new Mac:**

```zsh
./setup-mac.sh                          # reads mac-snapshot/ from the script directory
./setup-mac.sh ~/backups/my-mac         # or specify the snapshot path
```

The setup script walks you through each step interactively — Homebrew install + packages, oh-my-zsh install + config, dotfiles, macOS preferences, and up2date itself. Each step can be skipped.

## Requirements

- macOS
- [Homebrew](https://brew.sh/) — see [Installing Homebrew](#installing-homebrew) below
- [oh-my-zsh](https://ohmyz.sh/) — see [Installing oh-my-zsh](#installing-oh-my-zsh) below
- zsh (default shell on macOS since Catalina)

## Installing Homebrew

If you don't have Homebrew yet, run the bundled installer:

```zsh
chmod +x install-brew.sh
./install-brew.sh
```

This will:
- Install Xcode Command Line Tools if not already present (waits for completion)
- Install Homebrew via the official installer
- Add Homebrew to your `PATH` in `~/.zshrc` (Apple Silicon Macs)
- Run `brew doctor` to verify the installation

### Backup & restore Homebrew packages

You can dump all installed taps, formulae, and casks into a snapshot file and restore them on a new machine.

**Dump** the current packages:

```zsh
./dump-brew.sh                         # saves to brew-snapshot.conf in the script directory
./dump-brew.sh ~/backups/brew.conf     # or specify a custom path
```

The snapshot captures:
- Third-party taps
- All installed formulae
- All installed casks

**Restore** from a snapshot:

```zsh
./restore-brew.sh                         # reads brew-snapshot.conf from the script directory
./restore-brew.sh ~/backups/brew.conf     # or specify the snapshot path
```

The restore script will:
- Add all third-party taps
- Install all formulae in a single `brew install` batch (skips already installed)
- Install all casks in a single `brew install --cask` batch (skips already installed)

## Installing oh-my-zsh

If you don't have oh-my-zsh yet, run the bundled installer first:

```zsh
chmod +x install-omz.sh
./install-omz.sh
```

This will:
- Install oh-my-zsh (skips if already installed)
- Install [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) plugins
- Install the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme and activate it in `~/.zshrc`
- Set zsh as your default shell

On first launch after install, Powerlevel10k will walk you through its configuration wizard. You can re-run it anytime with:

```zsh
p10k configure
```

> **Note:** For the best Powerlevel10k experience, install a [Nerd Font](https://www.nerdfonts.com/) and configure your terminal to use it.

### Backup & restore oh-my-zsh configuration

You can dump your current oh-my-zsh setup (theme, plugins, custom repos, Powerlevel10k config) into a portable snapshot file and restore it later — useful when migrating to a new machine or recovering after a fresh install.

**Dump** the current configuration:

```zsh
./dump-omz.sh                        # saves to omz-snapshot.conf in the script directory
./dump-omz.sh ~/backups/omz.conf     # or specify a custom path
```

The snapshot captures:
- `ZSH_THEME` and `plugins=(…)` from `~/.zshrc`
- Git remote URLs for every custom plugin and theme in `$ZSH_CUSTOM`
- Custom `.zsh` files present in `$ZSH_CUSTOM`
- `~/.p10k.zsh` (base64-encoded)

**Restore** from a snapshot:

```zsh
./restore-omz.sh                        # reads omz-snapshot.conf from the script directory
./restore-omz.sh ~/backups/omz.conf     # or specify the snapshot path
```

The restore script will:
- Install oh-my-zsh if it's not already present
- Clone all custom plugins and themes from their original git repos
- Set `ZSH_THEME` and `plugins=(…)` in `~/.zshrc`
- Restore `~/.p10k.zsh` (existing file is backed up to `~/.p10k.zsh.bak`)
- Set zsh as the default shell if needed

## Backup & restore dotfiles

Dump your dotfiles and app configurations into a snapshot directory and restore them on a new machine.

**Dump** the current dotfiles:

```zsh
./dump-dotfiles.sh                              # saves to dotfiles-snapshot/ in the script directory
./dump-dotfiles.sh ~/backups/dotfiles           # or specify a custom path
```

The snapshot captures:
- `~/.gitconfig`
- `~/.ssh/config`
- `~/.vimrc`
- VS Code settings, keybindings, snippets, and extensions list
- iTerm2 preferences (converted to portable XML format)

**Restore** from a snapshot:

```zsh
./restore-dotfiles.sh                              # reads dotfiles-snapshot/ from the script directory
./restore-dotfiles.sh ~/backups/dotfiles           # or specify the snapshot path
```

The restore script will:
- Copy each dotfile to its expected location (existing files are backed up to `.bak`)
- Set correct permissions on `~/.ssh/config`
- Restore VS Code settings, keybindings, and snippets
- Install all VS Code extensions from the saved list (skips already installed)
- Import iTerm2 preferences via `defaults import`

## Installation

Clone or download the repo, then run the installer from the project directory:

```zsh
chmod +x install.sh uninstall.sh
./install.sh
source ~/.zshrc
```

The installer will:
- Auto-detect the script's location
- Add the directory to your `PATH` in `~/.zshrc`
- Make `up2date.sh` executable

Once installed, you can run it from anywhere as:

```zsh
up2date
```

### Uninstallation

```zsh
./uninstall.sh
source ~/.zshrc
```

The uninstaller removes only the `PATH` entry it added. A backup of your `.zshrc` is saved to `.zshrc.bak` before any changes are made.

## Usage

Homebrew cask upgrades may prompt for your `sudo` password when they need to modify `/Applications`. Homebrew intentionally resets the sudo timestamp on every invocation, so the password cannot be pre-cached — you may be prompted once per cask command that requires elevated privileges.

### Running on a schedule

You can automate this with a `launchd` plist or simply add it to your shell's startup, but running it manually when convenient is the intended workflow.

## Logging

Logs are appended to:

```
~/log/up2date.sh.log
```

Each run is separated by a dated header:

```
----------------------------
Wed Mar 11 10:00:00 EET 2026
----------------------------
```

Both stdout and stderr from each tool are captured, so failures are visible in the log.

## Security notes

- Your password is never stored in a variable or written to disk.
- Homebrew intentionally resets the sudo timestamp (`sudo --reset-timestamp`) at the start of every `brew` command, so pre-caching credentials is not possible. The script lets brew handle sudo prompts natively.

## File structure

```
.
├── up2date.sh       # The main update script
├── install.sh       # Adds the script directory to PATH in ~/.zshrc
├── uninstall.sh     # Removes the PATH entry from ~/.zshrc
├── install-brew.sh  # Installs Homebrew and Xcode Command Line Tools
├── dump-brew.sh     # Dumps installed taps, formulae, and casks to a snapshot file
├── restore-brew.sh  # Restores Homebrew packages from a snapshot file
├── install-omz.sh   # Installs oh-my-zsh, plugins, and Powerlevel10k theme
├── dump-omz.sh      # Dumps current oh-my-zsh configuration to a snapshot file
├── restore-omz.sh   # Restores oh-my-zsh configuration from a snapshot file
├── dump-dotfiles.sh    # Dumps dotfiles and app configs to a snapshot directory
├── restore-dotfiles.sh # Restores dotfiles and app configs from a snapshot
├── dump-mac.sh         # Dumps entire Mac environment (runs all dump scripts)
├── setup-mac.sh        # Sets up a fresh Mac from a snapshot (runs all install/restore scripts)
└── README.md           # This file
```