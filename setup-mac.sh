#!/bin/zsh
#
#--------------------------------------------------
#
# Sets up a fresh Mac from a snapshot created by
# dump-mac.sh — installs Homebrew, restores packages,
# installs oh-my-zsh, restores config, restores
# dotfiles, and applies macOS system preferences.
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

ask_yes() {
  local prompt="$1"
  local answer
  echo -n "${PURPLE}$prompt [Y/n] ${NC}"
  read -r answer
  [[ "$answer" =~ ^[Yy]?$ ]]
}

# --- Configuration ----------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAPSHOT_DIR="${1:-$SCRIPT_DIR/mac-snapshot}"

# --- Preflight --------------------------------------------------------

echo ""
info "================================================"
info "  macOS fresh setup"
info "================================================"
echo ""

if [[ ! -d "$SNAPSHOT_DIR" ]]; then
  error "Snapshot directory not found: $SNAPSHOT_DIR"
  echo ""
  echo "  Usage: $0 [path/to/mac-snapshot]"
  echo ""
  echo "  Create a snapshot first with: ./dump-mac.sh"
  exit 1
fi

if [[ -f "$SNAPSHOT_DIR/MANIFEST" ]]; then
  info "Snapshot manifest:"
  grep '^#' "$SNAPSHOT_DIR/MANIFEST" | sed 's/^# /  /'
  echo ""
fi

# Track results
SUCCEEDED=()
FAILED=()
SKIPPED=()

# --- 1. Homebrew ------------------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 1/5  Homebrew                               │"
info "└─────────────────────────────────────────────┘"

if ask_yes "Install Homebrew and restore packages?"; then
  # Install Homebrew
  if command -v brew &>/dev/null; then
    warn "Homebrew is already installed — skipping install."
  else
    info "Installing Homebrew..."
    "$SCRIPT_DIR/install-brew.sh"
    if [[ $? -ne 0 ]]; then
      error "Homebrew installation failed."
      FAILED+=("Homebrew install")
    fi
  fi

  # Restore packages
  if [[ -f "$SNAPSHOT_DIR/brew-snapshot.conf" ]]; then
    if command -v brew &>/dev/null; then
      info "Restoring Homebrew packages..."
      "$SCRIPT_DIR/restore-brew.sh" "$SNAPSHOT_DIR/brew-snapshot.conf"
      if [[ $? -eq 0 ]]; then
        SUCCEEDED+=("Homebrew packages")
      else
        FAILED+=("Homebrew packages")
      fi
    else
      error "Homebrew not available — cannot restore packages."
      FAILED+=("Homebrew packages")
    fi
  else
    warn "No Homebrew snapshot found — skipping restore."
    SKIPPED+=("Homebrew packages")
  fi
else
  SKIPPED+=("Homebrew")
fi
echo ""

# --- 2. oh-my-zsh ----------------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 2/5  oh-my-zsh                              │"
info "└─────────────────────────────────────────────┘"

if ask_yes "Install oh-my-zsh and restore configuration?"; then
  # Install oh-my-zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "oh-my-zsh is already installed — skipping install."
  else
    info "Installing oh-my-zsh..."
    "$SCRIPT_DIR/install-omz.sh"
    if [[ $? -ne 0 ]]; then
      error "oh-my-zsh installation failed."
      FAILED+=("oh-my-zsh install")
    fi
  fi

  # Restore configuration
  if [[ -f "$SNAPSHOT_DIR/omz-snapshot.conf" ]]; then
    info "Restoring oh-my-zsh configuration..."
    "$SCRIPT_DIR/restore-omz.sh" "$SNAPSHOT_DIR/omz-snapshot.conf"
    if [[ $? -eq 0 ]]; then
      SUCCEEDED+=("oh-my-zsh config")
    else
      FAILED+=("oh-my-zsh config")
    fi
  else
    warn "No oh-my-zsh snapshot found — skipping restore."
    SKIPPED+=("oh-my-zsh config")
  fi
else
  SKIPPED+=("oh-my-zsh")
fi
echo ""

# --- 3. Dotfiles ------------------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 3/5  Dotfiles & app configurations          │"
info "└─────────────────────────────────────────────┘"

if ask_yes "Restore dotfiles and app configurations?"; then
  if [[ -d "$SNAPSHOT_DIR/dotfiles-snapshot" ]]; then
    info "Restoring dotfiles..."
    "$SCRIPT_DIR/restore-dotfiles.sh" "$SNAPSHOT_DIR/dotfiles-snapshot"
    if [[ $? -eq 0 ]]; then
      SUCCEEDED+=("Dotfiles")
    else
      FAILED+=("Dotfiles")
    fi
  else
    warn "No dotfiles snapshot found — skipping."
    SKIPPED+=("Dotfiles")
  fi
else
  SKIPPED+=("Dotfiles")
fi
echo ""

# --- 4. macOS system preferences --------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 4/5  macOS system preferences               │"
info "└─────────────────────────────────────────────┘"

MACOS_DIR="$SNAPSHOT_DIR/macos-defaults"

if [[ -d "$MACOS_DIR" ]]; then
  if ask_yes "Apply macOS system preferences (Dock, Finder, keyboard, trackpad, etc.)?"; then
    info "Applying macOS preferences..."

    apply_defaults() {
      local domain="$1"
      local file="$2"
      local label="$3"

      if [[ -f "$file" ]]; then
        defaults import "$domain" "$file" 2>/dev/null && \
          success "$label" || error "$label — failed to import."
      fi
    }

    apply_defaults "com.apple.dock"                    "$MACOS_DIR/dock.plist"             "Dock"
    apply_defaults "com.apple.finder"                  "$MACOS_DIR/finder.plist"           "Finder"
    apply_defaults "NSGlobalDomain"                    "$MACOS_DIR/global-domain.plist"    "Global Domain (keyboard, language)"
    apply_defaults "com.apple.AppleMultitouchTrackpad" "$MACOS_DIR/trackpad.plist"         "Trackpad"
    apply_defaults "com.apple.AppleMultitouchMouse"    "$MACOS_DIR/mouse.plist"            "Mouse"
    apply_defaults "com.apple.screencapture"           "$MACOS_DIR/screencapture.plist"    "Screenshots"
    apply_defaults "com.apple.ActivityMonitor"         "$MACOS_DIR/activity-monitor.plist" "Activity Monitor"

    # Restart affected services to apply changes
    info "Restarting Dock and Finder to apply changes..."
    killall Dock 2>/dev/null
    killall Finder 2>/dev/null
    success "Dock and Finder restarted."

    SUCCEEDED+=("macOS preferences")
  else
    SKIPPED+=("macOS preferences")
  fi
else
  warn "No macOS defaults snapshot found — skipping."
  SKIPPED+=("macOS preferences")
fi
echo ""

# --- 5. up2date -------------------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 5/5  up2date.sh (system update tool)        │"
info "└─────────────────────────────────────────────┘"

if ask_yes "Install up2date.sh to PATH for easy system updates?"; then
  "$SCRIPT_DIR/install.sh"
  if [[ $? -eq 0 ]]; then
    SUCCEEDED+=("up2date.sh")
  else
    FAILED+=("up2date.sh")
  fi
else
  SKIPPED+=("up2date.sh")
fi
echo ""

# --- Summary ----------------------------------------------------------

echo ""
info "================================================"
info "  Setup complete!"
info "================================================"
echo ""

if (( ${#SUCCEEDED[@]} > 0 )); then
  success "Completed: ${(j:, :)SUCCEEDED}"
fi

if (( ${#SKIPPED[@]} > 0 )); then
  warn "Skipped:   ${(j:, :)SKIPPED}"
fi

if (( ${#FAILED[@]} > 0 )); then
  error "Failed:    ${(j:, :)FAILED}"
fi

echo ""
echo "  Start a new terminal session to apply all changes."
echo ""
