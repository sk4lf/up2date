# up2date.sh

A personal macOS maintenance script that keeps your system tools up to date with a single command.

## What it does

Runs the following update tasks sequentially:

1. **Homebrew** — `brew update` followed by `brew upgrade`
2. **Homebrew Casks** — upgrades installed casks, including greedy upgrades for casks that self-update
3. **oh-my-zsh** — upgrades the oh-my-zsh framework and its plugins

All output is logged to `~/log/up2date.sh.log` for later review.

## Requirements

- macOS
- [Homebrew](https://brew.sh/)
- [oh-my-zsh](https://ohmyz.sh/) — see [Installing oh-my-zsh](#installing-oh-my-zsh) below
- zsh (default shell on macOS since Catalina)

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

The script will prompt for your `sudo` password once at startup. It keeps the credentials alive in the background for the duration of the run, so you won't be asked again even if the update process takes a long time.

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

- `sudo -v` is used to cache credentials upfront — your password is never stored in a variable or written to disk.
- A background keeper loop refreshes the sudo timestamp every 50 seconds so it doesn't expire mid-run.
- The keeper process is automatically terminated when the script exits (including on error), via `trap`.

## File structure

```
.
├── up2date.sh       # The main update script
├── install.sh       # Adds the script directory to PATH in ~/.zshrc
├── uninstall.sh     # Removes the PATH entry from ~/.zshrc
├── install-omz.sh   # Installs oh-my-zsh, plugins, and Powerlevel10k theme
└── README.md        # This file
```