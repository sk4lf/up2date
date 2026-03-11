#!/bin/zsh
#
#--------------------------------------------------
#
# Restores oh-my-zsh configuration from a snapshot
# file created by dump-omz.sh
#
# Installs oh-my-zsh (if needed), custom plugins,
# custom themes, and applies theme/plugin settings
# to ~/.zshrc
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

# --- Configuration ----------------------------------------------------

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
ZSHRC="$HOME/.zshrc"
P10K_FILE="$HOME/.p10k.zsh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAPSHOT="${1:-$SCRIPT_DIR/omz-snapshot.conf}"

# --- Preflight checks -------------------------------------------------

echo ""
info "oh-my-zsh configuration restore"
echo ""

if [[ ! -f "$SNAPSHOT" ]]; then
  error "Snapshot file not found: $SNAPSHOT"
  echo "  Usage: $0 [path/to/omz-snapshot.conf]"
  exit 1
fi

if ! check_cmd git; then
  error "git is required but not installed. Install it via: xcode-select --install"
  exit 1
fi

if ! check_cmd curl; then
  error "curl is required but not installed."
  exit 1
fi

# --- Load snapshot ----------------------------------------------------

info "Loading snapshot: $SNAPSHOT"
source "$SNAPSHOT"
success "Snapshot loaded."

# --- Install oh-my-zsh -----------------------------------------------

if [[ -d "$ZSH_DIR" ]]; then
  warn "oh-my-zsh is already installed at $ZSH_DIR — skipping."
else
  info "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  if [[ -d "$ZSH_DIR" ]]; then
    success "oh-my-zsh installed."
  else
    error "oh-my-zsh installation failed."
    exit 1
  fi
fi

# --- Install custom plugins -------------------------------------------

if (( ${#CUSTOM_PLUGINS[@]} > 0 )); then
  info "Installing custom plugins..."
  for entry in "${CUSTOM_PLUGINS[@]}"; do
    name="${entry%%|*}"
    repo="${entry#*|}"
    dest="$ZSH_CUSTOM_DIR/plugins/$name"

    if [[ -d "$dest" ]]; then
      warn "Plugin '$name' already installed — skipping."
    else
      info "  Cloning plugin: $name..."
      git clone --depth=1 "$repo" "$dest"
      if [[ $? -eq 0 ]]; then
        success "  Plugin '$name' installed."
      else
        error "  Failed to clone plugin '$name' from $repo."
      fi
    fi
  done
else
  info "No custom plugins to install."
fi

# --- Install custom themes --------------------------------------------

if (( ${#CUSTOM_THEMES[@]} > 0 )); then
  info "Installing custom themes..."
  for entry in "${CUSTOM_THEMES[@]}"; do
    name="${entry%%|*}"
    repo="${entry#*|}"
    dest="$ZSH_CUSTOM_DIR/themes/$name"

    if [[ -d "$dest" ]]; then
      warn "Theme '$name' already installed — skipping."
    else
      info "  Cloning theme: $name..."
      git clone --depth=1 "$repo" "$dest"
      if [[ $? -eq 0 ]]; then
        success "  Theme '$name' installed."
      else
        error "  Failed to clone theme '$name' from $repo."
      fi
    fi
  done
else
  info "No custom themes to install."
fi

# --- Restore custom .zsh files ----------------------------------------

if (( ${#CUSTOM_ZSH_FILES[@]} > 0 )); then
  warn "The following custom .zsh files were present in the original setup:"
  for fname in "${CUSTOM_ZSH_FILES[@]}"; do
    if [[ -f "$ZSH_CUSTOM_DIR/$fname" ]]; then
      warn "  $fname (already exists — skipping)"
    else
      warn "  $fname (missing — you may need to restore it manually)"
    fi
  done
fi

# --- Apply theme to .zshrc -------------------------------------------

if [[ -n "$THEME" ]]; then
  info "Setting ZSH_THEME to '$THEME'..."
  if [[ ! -f "$ZSHRC" ]]; then
    warn "~/.zshrc does not exist — creating a minimal one."
    cat > "$ZSHRC" <<'MINZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
MINZSHRC
  fi

  if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
    # Escape forward slashes in theme name for sed
    THEME_ESCAPED="${THEME//\//\\/}"
    sed -i.bak "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME_ESCAPED\"/" "$ZSHRC"
    success "ZSH_THEME set to '$THEME'."
  else
    echo "ZSH_THEME=\"$THEME\"" >> "$ZSHRC"
    success "ZSH_THEME appended to ~/.zshrc."
  fi
fi

# --- Apply plugins to .zshrc -----------------------------------------

if [[ -n "$PLUGINS" ]]; then
  info "Setting plugins..."
  if grep -q '^plugins=' "$ZSHRC" 2>/dev/null; then
    # Replace the entire plugins=(...) block (handles multi-line)
    # First, collapse the block to detect it, then replace
    PLUGINS_LINE="plugins=($PLUGINS)"

    # Use perl for reliable multi-line replacement
    perl -i.bak -0pe "s/^plugins=\(.*?\)/$PLUGINS_LINE/ms" "$ZSHRC"
    success "Plugins set to: $PLUGINS"
  else
    echo "plugins=($PLUGINS)" >> "$ZSHRC"
    success "plugins=() block appended to ~/.zshrc."
  fi
fi

# --- Restore Powerlevel10k config ------------------------------------

if [[ -n "$P10K_CONFIG_B64" ]]; then
  info "Restoring Powerlevel10k configuration..."
  if [[ -f "$P10K_FILE" ]]; then
    cp "$P10K_FILE" "${P10K_FILE}.bak"
    warn "Existing ~/.p10k.zsh backed up to ~/.p10k.zsh.bak"
  fi
  echo "$P10K_CONFIG_B64" | base64 --decode > "$P10K_FILE"
  success "Powerlevel10k config restored to ~/.p10k.zsh"

  # Ensure p10k sourcing line exists in .zshrc
  if ! grep -q 'source.*p10k\.zsh' "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.' >> "$ZSHRC"
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$ZSHRC"
    success "Added p10k source line to ~/.zshrc."
  fi
else
  info "No Powerlevel10k config in snapshot — skipping."
fi

# --- Set default shell to zsh ----------------------------------------

CURRENT_SHELL="$(dscl . -read ~/ UserShell 2>/dev/null | awk '{print $2}')"
ZSH_PATH="$(command -v zsh)"

if [[ -n "$CURRENT_SHELL" && "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  warn "Default shell is already zsh — skipping."
elif [[ -n "$ZSH_PATH" ]]; then
  info "Changing default shell to zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
  success "Default shell changed to zsh."
fi

# --- Cleanup backup files ---------------------------------------------

rm -f "${ZSHRC}.bak"

# --- Done -------------------------------------------------------------

echo ""
success "oh-my-zsh configuration restored!"
echo ""
echo "  Start a new terminal session to apply all changes."
echo ""
