#!/bin/zsh
#
#--------------------------------------------------
#
# Removes up2date PATH entry from ~/.zshrc
#
#--------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

ZSHRC="$HOME/.zshrc"
MARKER="# added by up2date installer"

echo "${PURPLE}up2date uninstaller${NC}"

# Check if installed
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
  echo "${RED}Not installed — no entry found in $ZSHRC${NC}"
  exit 1
fi

# Remove the line containing the marker (backup .zshrc first)
cp "$ZSHRC" "$ZSHRC.bak"
grep -vF "$MARKER" "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

echo "${GREEN}Done. Entry removed from $ZSHRC${NC}"
echo "A backup was saved to $ZSHRC.bak"
echo ""
echo "Reload your shell or run:"
echo "  source ~/.zshrc"