#!/bin/zsh
#
#--------------------------------------------------
#
# Installs Homebrew on a fresh macOS system
# and ensures Xcode Command Line Tools are present
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

check_cmd() {
  command -v "$1" &>/dev/null
}

# --- Preflight checks -------------------------------------------------

echo ""
info "Homebrew installer"
echo ""

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is intended for macOS only."
  exit 1
fi

# --- Xcode Command Line Tools ----------------------------------------

if xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools already installed — skipping."
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install

  # Wait for the installation to complete
  echo "  Waiting for Xcode CLT installation to finish (this may take a few minutes)..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  success "Xcode Command Line Tools installed."
fi

# --- Homebrew ---------------------------------------------------------

if check_cmd brew; then
  warn "Homebrew is already installed at $(command -v brew) — skipping."
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs (default location: /opt/homebrew)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Persist in shell profile if not already present
    ZSHRC="$HOME/.zshrc"
    BREW_SHELLENV='eval "$(/opt/homebrew/bin/brew shellenv)"'
    if ! grep -qF '/opt/homebrew/bin/brew shellenv' "$ZSHRC" 2>/dev/null; then
      echo "" >> "$ZSHRC"
      echo "# Homebrew" >> "$ZSHRC"
      echo "$BREW_SHELLENV" >> "$ZSHRC"
      success "Homebrew PATH added to ~/.zshrc."
    fi
  fi

  if check_cmd brew; then
    success "Homebrew installed ($(brew --version | head -1))."
  else
    error "Homebrew installation failed."
    exit 1
  fi
fi

# --- Verify -----------------------------------------------------------

info "Running brew doctor..."
brew doctor 2>&1 | head -5

# --- Done -------------------------------------------------------------

echo ""
success "Homebrew is ready!"
echo ""
echo "  Run 'brew install <package>' to install packages."
echo "  Run 'brew search <term>' to search for packages."
echo ""
