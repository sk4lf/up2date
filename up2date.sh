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

# Force Homebrew to preserve colored output even when piped through tee
export HOMEBREW_COLOR=1

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

# Brew
# Note: Homebrew intentionally runs `sudo --reset-timestamp` at the start of
# every brew command (see brew.sh), wiping any cached sudo credentials.
# There is no way to pre-cache sudo for brew. Instead we use process
# substitution ( > >(...) ) for cask commands so that brew's stdin stays
# connected to the terminal and brew can prompt for sudo when it needs to.
echo "${PURPLE}Brew Update${NC}" | tee -a "$LOG"
brew update 2>&1 | tee -a "$LOG"

echo "${PURPLE}Brew Upgrade${NC}" | tee -a "$LOG"
brew upgrade 2>&1 | tee -a "$LOG"

# Brew Cask — may need sudo for apps in /Applications
echo "${PURPLE}Brew Upgrade Cask${NC}" | tee -a "$LOG"
brew upgrade --cask > >(tee -a "$LOG") 2>&1

echo "${PURPLE}Brew Upgrade Cask (greedy)${NC}" | tee -a "$LOG"
brew upgrade --cask --greedy > >(tee -a "$LOG") 2>&1

# oh-my-zsh
echo "${PURPLE}oh-my-zsh${NC}" | tee -a "$LOG"
zsh "$ZSHDIR/tools/upgrade.sh" 2>&1 | tee -a "$LOG"