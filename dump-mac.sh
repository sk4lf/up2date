#!/bin/zsh
#
#--------------------------------------------------
#
# Dumps the entire macOS environment into a single
# snapshot directory — Homebrew packages, oh-my-zsh
# config, dotfiles, and macOS system preferences.
#
# Restore on a new Mac with: setup-mac.sh
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
SNAPSHOT_DIR="${1:-$SCRIPT_DIR/mac-snapshot}"

# --- Preflight --------------------------------------------------------

echo ""
info "================================================"
info "  macOS full environment dump"
info "================================================"
echo ""

mkdir -p "$SNAPSHOT_DIR"

# Track failures
FAILED=()

# --- 1. Homebrew packages ---------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 1/4  Homebrew packages                      │"
info "└─────────────────────────────────────────────┘"

if command -v brew &>/dev/null; then
  "$SCRIPT_DIR/dump-brew.sh" "$SNAPSHOT_DIR/brew-snapshot.conf"
  if [[ $? -eq 0 ]]; then
    success "Homebrew dump complete."
  else
    error "Homebrew dump failed."
    FAILED+=("Homebrew")
  fi
else
  warn "Homebrew is not installed — skipping."
fi
echo ""

# --- 2. oh-my-zsh configuration --------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 2/4  oh-my-zsh configuration                │"
info "└─────────────────────────────────────────────┘"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  "$SCRIPT_DIR/dump-omz.sh" "$SNAPSHOT_DIR/omz-snapshot.conf"
  if [[ $? -eq 0 ]]; then
    success "oh-my-zsh dump complete."
  else
    error "oh-my-zsh dump failed."
    FAILED+=("oh-my-zsh")
  fi
else
  warn "oh-my-zsh is not installed — skipping."
fi
echo ""

# --- 3. Dotfiles ------------------------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 3/4  Dotfiles & app configurations          │"
info "└─────────────────────────────────────────────┘"

"$SCRIPT_DIR/dump-dotfiles.sh" "$SNAPSHOT_DIR/dotfiles-snapshot"
if [[ $? -eq 0 ]]; then
  success "Dotfiles dump complete."
else
  error "Dotfiles dump failed."
  FAILED+=("Dotfiles")
fi
echo ""

# --- 4. macOS system preferences --------------------------------------

info "┌─────────────────────────────────────────────┐"
info "│ 4/4  macOS system preferences               │"
info "└─────────────────────────────────────────────┘"

MACOS_DIR="$SNAPSHOT_DIR/macos-defaults"
mkdir -p "$MACOS_DIR"

info "Exporting macOS preferences..."

# Dock
defaults read com.apple.dock > "$MACOS_DIR/dock.plist" 2>/dev/null && \
  success "Dock preferences" || warn "Dock preferences — not found."

# Finder
defaults read com.apple.finder > "$MACOS_DIR/finder.plist" 2>/dev/null && \
  success "Finder preferences" || warn "Finder preferences — not found."

# Keyboard
defaults read NSGlobalDomain > "$MACOS_DIR/global-domain.plist" 2>/dev/null && \
  success "Global Domain (keyboard, language, etc.)" || warn "Global Domain — not found."

# Trackpad
defaults read com.apple.AppleMultitouchTrackpad > "$MACOS_DIR/trackpad.plist" 2>/dev/null && \
  success "Trackpad preferences" || warn "Trackpad preferences — not found."

# Mouse
defaults read com.apple.AppleMultitouchMouse > "$MACOS_DIR/mouse.plist" 2>/dev/null && \
  success "Mouse preferences" || warn "Mouse preferences — not found."

# Screenshots
defaults read com.apple.screencapture > "$MACOS_DIR/screencapture.plist" 2>/dev/null && \
  success "Screenshot preferences" || warn "Screenshot preferences — not found."

# Activity Monitor
defaults read com.apple.ActivityMonitor > "$MACOS_DIR/activity-monitor.plist" 2>/dev/null && \
  success "Activity Monitor preferences" || warn "Activity Monitor preferences — not found."

echo ""

# --- Manifest ---------------------------------------------------------

cat > "$SNAPSHOT_DIR/MANIFEST" <<EOF
# macOS full environment snapshot
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Host: $(hostname)
# macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))
#
# Contents:
#   brew-snapshot.conf     — Homebrew taps, formulae, casks
#   omz-snapshot.conf      — oh-my-zsh theme, plugins, custom repos
#   dotfiles-snapshot/     — git, ssh, vim, VS Code, iTerm2 configs
#   macos-defaults/        — macOS system preferences
#
# Restore with: setup-mac.sh $SNAPSHOT_DIR
EOF

# --- Summary ----------------------------------------------------------

echo ""
info "================================================"
if (( ${#FAILED[@]} > 0 )); then
  warn "Snapshot saved with errors: ${FAILED[*]}"
else
  success "Full snapshot saved to: $SNAPSHOT_DIR/"
fi
info "================================================"
echo ""
echo "  Contents:"
ls -1 "$SNAPSHOT_DIR" | sed 's/^/    /'
echo ""
echo "  To restore on a new Mac:"
echo "  ./setup-mac.sh $SNAPSHOT_DIR"
echo ""
