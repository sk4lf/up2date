#!/bin/zsh
#
#--------------------------------------------------
#
# Restores Homebrew taps, formulae, and casks
# from a snapshot file created by dump-brew.sh
#
#--------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# --- Helpers ----------------------------------------------------------

info()    { echo "${PURPLE}$1${NC}" }
success() { echo "${GREEN}✔ $1${NC}" }
warn()    { echo "${YELLOW}⚠ $1${NC}" }
error()   { echo "${RED}✖ $1${NC}" }

# --- Configuration ----------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAPSHOT="${1:-$SCRIPT_DIR/brew-snapshot.conf}"

# --- Preflight checks -------------------------------------------------

echo ""
info "Homebrew configuration restore"
echo ""

if [[ ! -f "$SNAPSHOT" ]]; then
  error "Snapshot file not found: $SNAPSHOT"
  echo "  Usage: $0 [path/to/brew-snapshot.conf]"
  exit 1
fi

if ! command -v brew &>/dev/null; then
  error "Homebrew is not installed. Run install-brew.sh first."
  exit 1
fi

# --- Load snapshot ----------------------------------------------------

info "Loading snapshot: $SNAPSHOT"
source "$SNAPSHOT"
success "Snapshot loaded: ${#TAPS[@]} taps, ${#FORMULAE[@]} formulae, ${#CASKS[@]} casks"

# --- Restore taps -----------------------------------------------------

if (( ${#TAPS[@]} > 0 )); then
  info "Restoring taps..."
  EXISTING_TAPS="$(brew tap)"
  for tap in "${TAPS[@]}"; do
    if echo "$EXISTING_TAPS" | grep -qx "$tap"; then
      warn "Tap '$tap' already added — skipping."
    else
      info "  Tapping $tap..."
      brew tap "$tap"
      if [[ $? -eq 0 ]]; then
        success "  Tap '$tap' added."
      else
        error "  Failed to tap '$tap'."
      fi
    fi
  done
else
  info "No taps to restore."
fi

# --- Restore formulae -------------------------------------------------

if (( ${#FORMULAE[@]} > 0 )); then
  info "Restoring formulae..."
  EXISTING_FORMULAE="$(brew list --formula)"

  INSTALL_LIST=()
  for formula in "${FORMULAE[@]}"; do
    if echo "$EXISTING_FORMULAE" | grep -qx "$formula"; then
      warn "Formula '$formula' already installed — skipping."
    else
      INSTALL_LIST+=("$formula")
    fi
  done

  if (( ${#INSTALL_LIST[@]} > 0 )); then
    info "  Installing ${#INSTALL_LIST[@]} formulae (this may take a while)..."
    brew install "${INSTALL_LIST[@]}"
    success "  Formulae installation complete."
  else
    warn "All formulae already installed."
  fi
else
  info "No formulae to restore."
fi

# --- Restore casks ----------------------------------------------------

if (( ${#CASKS[@]} > 0 )); then
  info "Restoring casks..."
  EXISTING_CASKS="$(brew list --cask)"

  INSTALL_LIST=()
  for cask in "${CASKS[@]}"; do
    if echo "$EXISTING_CASKS" | grep -qx "$cask"; then
      warn "Cask '$cask' already installed — skipping."
    else
      INSTALL_LIST+=("$cask")
    fi
  done

  if (( ${#INSTALL_LIST[@]} > 0 )); then
    info "  Installing ${#INSTALL_LIST[@]} casks (this may take a while)..."
    brew install --cask "${INSTALL_LIST[@]}"
    success "  Cask installation complete."
  else
    warn "All casks already installed."
  fi
else
  info "No casks to restore."
fi

# --- Done -------------------------------------------------------------

echo ""
success "Homebrew configuration restored!"
echo ""
