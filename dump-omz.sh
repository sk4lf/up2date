#!/bin/zsh
#
#--------------------------------------------------
#
# Dumps the current oh-my-zsh configuration into
# a portable snapshot file that can be restored
# later with restore-omz.sh
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

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
ZSHRC="$HOME/.zshrc"
P10K_FILE="$HOME/.p10k.zsh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DUMP_FILE="${1:-$SCRIPT_DIR/omz-snapshot.conf}"

# --- Preflight checks -------------------------------------------------

echo ""
info "oh-my-zsh configuration dump"
echo ""

if [[ ! -d "$ZSH_DIR" ]]; then
  error "oh-my-zsh is not installed at $ZSH_DIR — nothing to dump."
  exit 1
fi

if [[ ! -f "$ZSHRC" ]]; then
  error "~/.zshrc not found."
  exit 1
fi

# --- Extract theme from .zshrc ----------------------------------------

THEME=""
if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
  THEME="$(grep '^ZSH_THEME=' "$ZSHRC" | head -1 | sed 's/^ZSH_THEME="\{0,1\}\(.*\)"\{0,1\}$/\1/' | tr -d '"')"
  success "Theme detected: $THEME"
else
  warn "No ZSH_THEME found in .zshrc."
fi

# --- Extract plugins from .zshrc -------------------------------------

PLUGINS=""
if grep -q '^plugins=' "$ZSHRC" 2>/dev/null; then
  # Handle multi-line plugins=() block
  PLUGINS="$(sed -n '/^plugins=(/,/)/p' "$ZSHRC" | tr '\n' ' ' | sed 's/plugins=(\(.*\))/\1/' | xargs)"
  success "Plugins detected: $PLUGINS"
else
  warn "No plugins=() block found in .zshrc."
fi

# --- Discover custom plugins (git repos) ------------------------------

CUSTOM_PLUGINS=()
if [[ -d "$ZSH_CUSTOM_DIR/plugins" ]]; then
  for plugin_dir in "$ZSH_CUSTOM_DIR/plugins"/*(N/); do
    plugin_name="$(basename "$plugin_dir")"
    [[ "$plugin_name" == "example" ]] && continue
    if [[ -d "$plugin_dir/.git" ]]; then
      remote="$(git -C "$plugin_dir" remote get-url origin 2>/dev/null)"
      if [[ -n "$remote" ]]; then
        CUSTOM_PLUGINS+=("$plugin_name|$remote")
        success "Custom plugin: $plugin_name ($remote)"
      fi
    fi
  done
fi

# --- Discover custom themes (git repos) -------------------------------

CUSTOM_THEMES=()
if [[ -d "$ZSH_CUSTOM_DIR/themes" ]]; then
  for theme_dir in "$ZSH_CUSTOM_DIR/themes"/*(N/); do
    theme_name="$(basename "$theme_dir")"
    [[ "$theme_name" == "example" ]] && continue
    if [[ -d "$theme_dir/.git" ]]; then
      remote="$(git -C "$theme_dir" remote get-url origin 2>/dev/null)"
      if [[ -n "$remote" ]]; then
        CUSTOM_THEMES+=("$theme_name|$remote")
        success "Custom theme: $theme_name ($remote)"
      fi
    fi
  done
fi

# --- Discover custom .zsh files ---------------------------------------

CUSTOM_ZSH_FILES=()
if [[ -d "$ZSH_CUSTOM_DIR" ]]; then
  for zsh_file in "$ZSH_CUSTOM_DIR"/*.zsh(N); do
    fname="$(basename "$zsh_file")"
    [[ "$fname" == "example.zsh" ]] && continue
    CUSTOM_ZSH_FILES+=("$fname")
    success "Custom file: $fname"
  done
fi

# --- Write snapshot file ----------------------------------------------

info "Writing snapshot to $DUMP_FILE..."

cat > "$DUMP_FILE" <<EOF
# oh-my-zsh configuration snapshot
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Host: $(hostname)
#
# Restore with: restore-omz.sh $DUMP_FILE

THEME="$THEME"
PLUGINS="$PLUGINS"
EOF

# Custom plugins
echo "" >> "$DUMP_FILE"
echo "# Custom plugins (name|git_remote_url)" >> "$DUMP_FILE"
echo "CUSTOM_PLUGINS=(" >> "$DUMP_FILE"
for entry in "${CUSTOM_PLUGINS[@]}"; do
  echo "  \"$entry\"" >> "$DUMP_FILE"
done
echo ")" >> "$DUMP_FILE"

# Custom themes
echo "" >> "$DUMP_FILE"
echo "# Custom themes (name|git_remote_url)" >> "$DUMP_FILE"
echo "CUSTOM_THEMES=(" >> "$DUMP_FILE"
for entry in "${CUSTOM_THEMES[@]}"; do
  echo "  \"$entry\"" >> "$DUMP_FILE"
done
echo ")" >> "$DUMP_FILE"

# Custom .zsh files
echo "" >> "$DUMP_FILE"
echo "# Custom .zsh files in \$ZSH_CUSTOM/" >> "$DUMP_FILE"
echo "CUSTOM_ZSH_FILES=(" >> "$DUMP_FILE"
for fname in "${CUSTOM_ZSH_FILES[@]}"; do
  echo "  \"$fname\"" >> "$DUMP_FILE"
done
echo ")" >> "$DUMP_FILE"

# Embed p10k config if it exists
if [[ -f "$P10K_FILE" ]]; then
  echo "" >> "$DUMP_FILE"
  echo "# Powerlevel10k configuration (base64-encoded)" >> "$DUMP_FILE"
  echo "P10K_CONFIG_B64=\"$(base64 < "$P10K_FILE")\"" >> "$DUMP_FILE"
  success "Powerlevel10k config (~/.p10k.zsh) included."
else
  echo "" >> "$DUMP_FILE"
  echo "P10K_CONFIG_B64=\"\"" >> "$DUMP_FILE"
  warn "No ~/.p10k.zsh found — skipping."
fi

# --- Done -------------------------------------------------------------

echo ""
success "Snapshot saved to: $DUMP_FILE"
echo ""
echo "  To restore on another machine (or after a fresh install):"
echo "  ./restore-omz.sh $DUMP_FILE"
echo ""
