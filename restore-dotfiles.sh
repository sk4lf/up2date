#!/bin/zsh
#
#--------------------------------------------------
#
# Restores dotfiles and app configurations from a
# snapshot directory created by dump-dotfiles.sh
#
# Restored:
#   ~/.gitconfig
#   ~/.ssh/config
#   ~/.vimrc
#   VS Code settings + extensions
#   iTerm2 preferences
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
SNAPSHOT="${1:-$SCRIPT_DIR/dotfiles-snapshot}"

# --- Preflight checks -------------------------------------------------

echo ""
info "Dotfiles configuration restore"
echo ""

if [[ ! -d "$SNAPSHOT" ]]; then
  error "Snapshot directory not found: $SNAPSHOT"
  echo "  Usage: $0 [path/to/dotfiles-snapshot]"
  exit 1
fi

# --- Helper to restore a file -----------------------------------------

restore_file() {
  local src="$SNAPSHOT/$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    warn "$1 — not in snapshot, skipping."
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -f "$dest" ]]; then
    cp "$dest" "${dest}.bak"
    warn "Existing $(basename "$dest") backed up to ${dest}.bak"
  fi

  cp "$src" "$dest"
  success "$1 → $dest"
}

# --- Dotfiles ---------------------------------------------------------

info "Restoring dotfiles..."

restore_file "gitconfig"   "$HOME/.gitconfig"
restore_file "vimrc"       "$HOME/.vimrc"

# SSH config needs restricted permissions
restore_file "ssh_config"  "$HOME/.ssh/config"
if [[ -f "$HOME/.ssh/config" ]]; then
  chmod 600 "$HOME/.ssh/config"
fi

# --- VS Code ----------------------------------------------------------

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

info "Restoring VS Code settings..."

restore_file "vscode/settings.json"    "$VSCODE_USER_DIR/settings.json"
restore_file "vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

# VS Code snippets
if [[ -d "$SNAPSHOT/vscode/snippets" ]] && [[ -n "$(ls -A "$SNAPSHOT/vscode/snippets" 2>/dev/null)" ]]; then
  mkdir -p "$VSCODE_USER_DIR/snippets"
  cp "$SNAPSHOT/vscode/snippets"/*.json "$VSCODE_USER_DIR/snippets/"
  success "vscode/snippets/"
fi

# VS Code extensions
if [[ -f "$SNAPSHOT/vscode/extensions.txt" ]]; then
  if command -v code &>/dev/null; then
    EXISTING_EXTENSIONS="$(code --list-extensions)"
    INSTALL_COUNT=0
    SKIP_COUNT=0

    while IFS= read -r ext; do
      [[ -z "$ext" ]] && continue
      if echo "$EXISTING_EXTENSIONS" | grep -qx "$ext"; then
        (( SKIP_COUNT++ ))
      else
        code --install-extension "$ext" --force 2>/dev/null
        (( INSTALL_COUNT++ ))
      fi
    done < "$SNAPSHOT/vscode/extensions.txt"

    success "VS Code extensions: $INSTALL_COUNT installed, $SKIP_COUNT already present."
  else
    warn "VS Code CLI (code) not found — skipping extensions."
    echo "  Install VS Code and run: cat $SNAPSHOT/vscode/extensions.txt | xargs -L 1 code --install-extension"
  fi
fi

# --- iTerm2 -----------------------------------------------------------

ITERM2_PLIST_DEST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

info "Restoring iTerm2 preferences..."

if [[ -f "$SNAPSHOT/iterm2.plist" ]]; then
  if [[ -f "$ITERM2_PLIST_DEST" ]]; then
    cp "$ITERM2_PLIST_DEST" "${ITERM2_PLIST_DEST}.bak"
    warn "Existing iTerm2 plist backed up."
  fi

  # Import into defaults (handles binary/xml conversion automatically)
  defaults import com.googlecode.iterm2 "$SNAPSHOT/iterm2.plist"
  success "iTerm2 preferences restored (restart iTerm2 to apply)."
else
  warn "iterm2.plist — not in snapshot, skipping."
fi

# --- Done -------------------------------------------------------------

echo ""
success "Dotfiles restored!"
echo ""
