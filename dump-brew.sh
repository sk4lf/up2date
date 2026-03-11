#!/bin/zsh
#
#--------------------------------------------------
#
# Dumps all installed Homebrew taps, formulae,
# and casks into a portable snapshot file that
# can be restored later with restore-brew.sh
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
DUMP_FILE="${1:-$SCRIPT_DIR/brew-snapshot.conf}"

# --- Preflight checks -------------------------------------------------

echo ""
info "Homebrew configuration dump"
echo ""

if ! command -v brew &>/dev/null; then
  error "Homebrew is not installed."
  exit 1
fi

# --- Collect taps -----------------------------------------------------

TAPS="$(brew tap)"
TAP_COUNT="$(echo "$TAPS" | grep -c .)"
success "Taps: $TAP_COUNT"

# --- Collect formulae -------------------------------------------------

FORMULAE="$(brew list --formula)"
FORMULA_COUNT="$(echo "$FORMULAE" | grep -c .)"
success "Formulae: $FORMULA_COUNT"

# --- Collect casks ----------------------------------------------------

CASKS="$(brew list --cask)"
CASK_COUNT="$(echo "$CASKS" | grep -c .)"
success "Casks: $CASK_COUNT"

# --- Write snapshot file ----------------------------------------------

info "Writing snapshot to $DUMP_FILE..."

cat > "$DUMP_FILE" <<EOF
# Homebrew configuration snapshot
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Host: $(hostname)
# Homebrew: $(brew --version | head -1)
#
# Restore with: restore-brew.sh $DUMP_FILE

# Third-party taps (one per line)
TAPS=(
$(echo "$TAPS" | sed 's/^/  /')
)

# Installed formulae (one per line)
FORMULAE=(
$(echo "$FORMULAE" | sed 's/^/  /')
)

# Installed casks (one per line)
CASKS=(
$(echo "$CASKS" | sed 's/^/  /')
)
EOF

# --- Done -------------------------------------------------------------

echo ""
success "Snapshot saved to: $DUMP_FILE"
echo ""
echo "  $TAP_COUNT taps, $FORMULA_COUNT formulae, $CASK_COUNT casks"
echo ""
echo "  To restore on another machine:"
echo "  ./restore-brew.sh $DUMP_FILE"
echo ""
