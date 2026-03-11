#!/bin/zsh
#
#--------------------------------------------------
#
# Installs up2date command by adding the script
# directory to PATH in ~/.zshrc
#
#--------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="${0:A:h}"
ZSHRC="$HOME/.zshrc"
MARKER="# added by up2date installer"
PATH_LINE="export PATH=\"$SCRIPT_DIR:\$PATH\" $MARKER"

echo "${PURPLE}up2date installer${NC}"
echo "Script directory: $SCRIPT_DIR"

# Check up2date.sh exists in the same directory
if [[ ! -f "$SCRIPT_DIR/up2date.sh" ]]; then
  echo "${RED}Error: up2date.sh not found in $SCRIPT_DIR${NC}"
  exit 1
fi

# Ensure up2date.sh is executable
chmod +x "$SCRIPT_DIR/up2date.sh"

# Check if already installed
if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
  echo "${RED}Already installed. Run uninstall.sh first if you want to reinstall.${NC}"
  exit 1
fi

# Add PATH entry to .zshrc
echo "\n$PATH_LINE" >> "$ZSHRC"

echo "${GREEN}Done. Added to $ZSHRC:${NC}"
echo "  $PATH_LINE"
echo ""
echo "Reload your shell or run:"
echo "  source ~/.zshrc"