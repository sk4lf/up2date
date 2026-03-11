#!/bin/zsh
#
#--------------------------------------------------
#
# Installs oh-my-zsh with popular plugins and
# Powerlevel10k theme, and sets zsh as default shell
#
#--------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
ZSHRC="$HOME/.zshrc"

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
info "oh-my-zsh installer"
echo ""

# Check for git
if ! check_cmd git; then
  error "git is required but not installed. Install it via Xcode tools: xcode-select --install"
  exit 1
fi

# Check for curl
if ! check_cmd curl; then
  error "curl is required but not installed."
  exit 1
fi

# --- oh-my-zsh --------------------------------------------------------

if [[ -d "$ZSH_DIR" ]]; then
  warn "oh-my-zsh is already installed at $ZSH_DIR — skipping."
else
  info "Installing oh-my-zsh..."
  # Run unattended (RUNZSH=no prevents the installer from switching shell mid-script)
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  if [[ -d "$ZSH_DIR" ]]; then
    success "oh-my-zsh installed."
  else
    error "oh-my-zsh installation failed."
    exit 1
  fi
fi

# --- Plugins ----------------------------------------------------------

install_plugin() {
  local name="$1"
  local repo="$2"
  local dest="$ZSH_CUSTOM/plugins/$name"

  if [[ -d "$dest" ]]; then
    warn "Plugin '$name' already installed — skipping."
  else
    info "Installing plugin: $name..."
    git clone --depth=1 "$repo" "$dest"
    success "Plugin '$name' installed."
  fi
}

install_plugin "zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions"

install_plugin "zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-syntax-highlighting"

# --- Powerlevel10k theme ----------------------------------------------

P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

if [[ -d "$P10K_DIR" ]]; then
  warn "Powerlevel10k already installed — skipping."
else
  info "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  success "Powerlevel10k installed."
fi

# --- Activate in .zshrc -----------------------------------------------

info "Updating ~/.zshrc..."

# Set theme to powerlevel10k
if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
  sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
  success "ZSH_THEME set to powerlevel10k/powerlevel10k."
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
  success "ZSH_THEME appended to ~/.zshrc."
fi

# Add plugins to plugins=() list
if grep -q '^plugins=' "$ZSHRC" 2>/dev/null; then
  # Insert new plugins before closing parenthesis if not already present
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if ! grep -q "$plugin" "$ZSHRC"; then
      sed -i.bak "s/^plugins=(\(.*\))/plugins=(\1 $plugin)/" "$ZSHRC"
      success "Plugin '$plugin' added to plugins list."
    else
      warn "Plugin '$plugin' already in plugins list — skipping."
    fi
  done
else
  echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
  success "plugins=() block appended to ~/.zshrc."
fi

# --- Default shell ----------------------------------------------------

CURRENT_SHELL="$(dscl . -read ~/ UserShell | awk '{print $2}')"
ZSH_PATH="$(command -v zsh)"

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  warn "Default shell is already zsh — skipping."
else
  info "Changing default shell to zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
  success "Default shell changed to zsh."
fi

# --- Done -------------------------------------------------------------

echo ""
success "All done! Start a new terminal session to apply all changes."
echo ""
echo "  Powerlevel10k will guide you through its configuration wizard on first launch."
echo "  You can re-run the wizard at any time with: p10k configure"
echo ""