#!/bin/zsh
#
#--------------------------------------------------
#
# This script is aimed to keep my system up to date
#
#--------------------------------------------------

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
HOMEDIR="$HOME"
ZSHDIR="$HOMEDIR/.oh-my-zsh"
LOGDIR="$HOMEDIR/log"
LOGFILE="up2date.sh.log"
LOG="$LOGDIR/$LOGFILE"

# Prepare log directory and file
mkdir -p "$LOGDIR"
touch "$LOG"

# Print date header
echo "${GREEN}----------------------------${NC}" | tee -a "$LOG"
date | tee -a "$LOG"
echo "${GREEN}----------------------------${NC}" | tee -a "$LOG"

# Cache sudo credentials upfront.
# Note: background keepalive (sudo -n true in a loop) does NOT work on macOS
# with tty_tickets enabled (the default) — the background subshell loses its
# TTY association and refreshes a different timestamp. Instead we refresh
# sudo inline before each step that may need it.
echo "${PURPLE}Sudo authentication${NC}" | tee -a "$LOG"
sudo -v || { echo "${RED}sudo authentication failed, exiting.${NC}" | tee -a "$LOG"; exit 1; }

# Brew
echo "${PURPLE}Brew Update${NC}" | tee -a "$LOG"
brew update 2>&1 | tee -a "$LOG"

echo "${PURPLE}Brew Upgrade${NC}" | tee -a "$LOG"
brew upgrade 2>&1 | tee -a "$LOG"

# Brew Cask
# Cask upgrades often need sudo (e.g. removing apps from /Applications).
# We refresh sudo before each cask command and use process substitution
# ( > >(...) ) instead of a pipe so that brew's stdin stays connected to
# the terminal — allowing brew's internal sudo to prompt if needed.
echo "${PURPLE}Brew Upgrade Cask${NC}" | tee -a "$LOG"
sudo -v
brew upgrade --cask > >(tee -a "$LOG") 2>&1

echo "${PURPLE}Brew Upgrade Cask (greedy)${NC}" | tee -a "$LOG"
sudo -v
brew upgrade --cask --greedy > >(tee -a "$LOG") 2>&1

# oh-my-zsh
echo "${PURPLE}oh-my-zsh${NC}" | tee -a "$LOG"
zsh "$ZSHDIR/tools/upgrade.sh" 2>&1 | tee -a "$LOG"