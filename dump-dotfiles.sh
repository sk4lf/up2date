#!/bin/zsh
#
#--------------------------------------------------
#
# Dumps dotfiles and app configurations into a
# portable snapshot directory that can be restored
# later with restore-dotfiles.sh
#
# Captured:
#   ~/.gitconfig
#   ~/.ssh/config
#   ~/.vimrc
#   VS Code settings + extensions list
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
DUMP_DIR="${1:-$SCRIPT_DIR/dotfiles-snapshot}"

# --- Preflight checks -------------------------------------------------

echo ""
info "Dotfiles configuration dump"
echo ""

mkdir -p "$DUMP_DIR"

# --- Helper to copy a file --------------------------------------------

dump_file() {
  local src="$1"
  local dest="$DUMP_DIR/$2"

  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    success "$2"
  else
    warn "$2 — not found, skipping."
  fi
}

# --- Dotfiles ---------------------------------------------------------

info "Copying dotfiles..."

dump_file "$HOME/.gitconfig"  "gitconfig"
dump_file "$HOME/.ssh/config" "ssh_config"
dump_file "$HOME/.vimrc"      "vimrc"

# --- VS Code ----------------------------------------------------------

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

info "Copying VS Code settings..."

dump_file "$VSCODE_USER_DIR/settings.json"    "vscode/settings.json"
dump_file "$VSCODE_USER_DIR/keybindings.json" "vscode/keybindings.json"

# VS Code snippets
if [[ -d "$VSCODE_USER_DIR/snippets" ]] && [[ -n "$(ls -A "$VSCODE_USER_DIR/snippets" 2>/dev/null)" ]]; then
  mkdir -p "$DUMP_DIR/vscode/snippets"
  cp "$VSCODE_USER_DIR/snippets"/*.json "$DUMP_DIR/vscode/snippets/" 2>/dev/null
  success "vscode/snippets/"
fi

# VS Code extensions list
if command -v code &>/dev/null; then
  code --list-extensions > "$DUMP_DIR/vscode/extensions.txt"
  EXT_COUNT="$(wc -l < "$DUMP_DIR/vscode/extensions.txt" | tr -d ' ')"
  success "vscode/extensions.txt ($EXT_COUNT extensions)"
else
  warn "VS Code CLI (code) not found — skipping extensions list."
fi

# --- iTerm2 -----------------------------------------------------------

ITERM2_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

info "Copying iTerm2 preferences..."

if [[ -f "$ITERM2_PLIST" ]]; then
  # Convert binary plist to XML for portability
  plutil -convert xml1 -o "$DUMP_DIR/iterm2.plist" "$ITERM2_PLIST"
  success "iterm2.plist"
else
  warn "iTerm2 preferences not found — skipping."
fi

# --- Manifest ---------------------------------------------------------

cat > "$DUMP_DIR/MANIFEST" <<EOF
# Dotfiles snapshot
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Host: $(hostname)
#
# Restore with: restore-dotfiles.sh $DUMP_DIR
EOF

# --- Done -------------------------------------------------------------

echo ""
success "Snapshot saved to: $DUMP_DIR/"
echo ""
ls -1 "$DUMP_DIR" | sed 's/^/  /'
echo ""
echo "  To restore on another machine:"
echo "  ./restore-dotfiles.sh $DUMP_DIR"
echo ""
