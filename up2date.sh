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

# Cache sudo credentials upfront and keep them alive for the duration of the script
echo "${PURPLE}Sudo authentication${NC}" | tee -a "$LOG"
sudo -v || { echo "${RED}sudo authentication failed, exiting.${NC}" | tee -a "$LOG"; exit 1; }
# Refresh sudo timestamp every 50 seconds in the background until the script exits
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPER_PID=$!
trap "kill $SUDO_KEEPER_PID 2>/dev/null" EXIT


# Brew
echo "${PURPLE}Brew Update${NC}" | tee -a "$LOG"
brew update 2>&1 | tee -a "$LOG" &&

echo "${PURPLE}Brew Upgrade${NC}" | tee -a "$LOG"
brew upgrade 2>&1 | tee -a "$LOG"

# Brew Cask
# Cask upgrades often need sudo (e.g. removing apps from /Applications).
# Piping through tee can prevent brew's internal sudo from reading the
# password prompt, so we:
#   1. Refresh the sudo timestamp right before each cask command
#   2. Use process substitution ( > >(...) ) instead of a pipe so that
#      brew's stdin stays connected to the terminal
echo "${PURPLE}Brew Upgrade Cask${NC}" | tee -a "$LOG"
sudo -v
brew upgrade --cask > >(tee -a "$LOG") 2>&1

echo "${PURPLE}Brew Upgrade Cask (greedy)${NC}" | tee -a "$LOG"
sudo -v
brew upgrade --cask --greedy > >(tee -a "$LOG") 2>&1

# oh-my-zsh
echo "${PURPLE}oh-my-zsh${NC}" | tee -a "$LOG"
zsh "$ZSHDIR/tools/upgrade.sh" 2>&1 | tee -a "$LOG"