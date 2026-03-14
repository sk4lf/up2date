#!/bin/zsh
#
#--------------------------------------------------
#
# Displays a dependency tree for Homebrew packages
# in the terminal with color and useful metadata.
#
# Usage:
#   brew-tree.sh              # tree of all top-level packages
#   brew-tree.sh <formula>    # tree for a specific formula
#   brew-tree.sh --all        # tree of every installed formula
#   brew-tree.sh --reverse    # reverse tree (what depends on what)
#
#--------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# --- Helpers ----------------------------------------------------------

info()  { echo "${PURPLE}$1${NC}" }
error() { echo "${RED}✖ $1${NC}" }

# --- Preflight --------------------------------------------------------

if ! command -v brew &>/dev/null; then
  error "Homebrew is not installed."
  exit 1
fi

# --- Parse arguments --------------------------------------------------

MODE="leaves"      # default: show only top-level (leaf) packages
TARGET=""
SHOW_SIZE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)     MODE="all";     shift ;;
    --reverse) MODE="reverse"; shift ;;
    --size)    SHOW_SIZE=true; shift ;;
    --help|-h)
      echo "Usage: $(basename "$0") [options] [formula]"
      echo ""
      echo "Options:"
      echo "  (no args)        Show dependency tree for top-level packages"
      echo "  <formula>        Show dependency tree for a specific formula"
      echo "  --all            Show dependency tree for every installed formula"
      echo "  --reverse        Show reverse dependencies (what depends on what)"
      echo "  --size           Show installed size for each package"
      echo "  -h, --help       Show this help"
      exit 0
      ;;
    -*)
      error "Unknown option: $1"
      exit 1
      ;;
    *)
      TARGET="$1"
      MODE="single"
      shift
      ;;
  esac
done

# --- Cache dependency data --------------------------------------------

# Build a lookup of all installed formulae and their deps (much faster
# than calling `brew deps` per formula).
info "Loading Homebrew dependency data..."

typeset -A DEPS_MAP    # formula -> space-separated direct deps
typeset -A SIZE_MAP    # formula -> human-readable size
typeset -A USES_MAP    # formula -> space-separated reverse deps

ALL_INSTALLED=("${(@f)$(brew list --formula)}")
ALL_CASKS=("${(@f)$(brew list --cask)}")

# Parse dependencies from JSON via a temp file (piping large JSON
# through a shell variable can silently truncate)
TMPFILE="$(mktemp)"
trap "rm -f '$TMPFILE'" EXIT

brew info --json=v2 --installed 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for f in data.get('formulae', []):
    name = f['name']
    deps = f.get('dependencies', [])
    print(f'{name}\t{\" \".join(deps)}')
" > "$TMPFILE" 2>/dev/null

if [[ ! -s "$TMPFILE" ]]; then
  error "Failed to load Homebrew data."
  exit 1
fi

while IFS=$'\t' read -r name deps; do
  DEPS_MAP[$name]="$deps"
done < "$TMPFILE"

# Build reverse dependency map
for name deps in "${(@kv)DEPS_MAP}"; do
  for dep in ${(s: :)deps}; do
    if [[ -n "${USES_MAP[$dep]}" ]]; then
      USES_MAP[$dep]="${USES_MAP[$dep]} $name"
    else
      USES_MAP[$dep]="$name"
    fi
  done
done

# Get sizes if requested
if $SHOW_SIZE; then
  CELLAR="$(brew --cellar)"
  for name in "${ALL_INSTALLED[@]}"; do
    if [[ -d "$CELLAR/$name" ]]; then
      sz="$(du -sh "$CELLAR/$name" 2>/dev/null | cut -f1 | tr -d ' ')"
      SIZE_MAP[$name]="$sz"
    fi
  done
fi

# Find top-level packages (leaves) — installed explicitly, not as dependency
LEAVES=("${(@f)$(brew leaves 2>/dev/null)}")

# --- Tree rendering ---------------------------------------------------

# Track which nodes we've already expanded to avoid infinite loops
typeset -A SEEN

print_tree() {
  local name="$1"
  local prefix="$2"
  local is_last="$3"
  local depth="$4"

  # Connector
  local connector=""
  if [[ -n "$prefix" || -n "$is_last" ]]; then
    if [[ "$is_last" == "true" ]]; then
      connector="└── "
    else
      connector="├── "
    fi
  fi

  # Format the node
  local label="$name"
  local extra=""

  # Color: top-level = green+bold, dependency = cyan, cask = yellow
  if (( depth == 0 )); then
    label="${BOLD}${GREEN}${name}${NC}"
  else
    label="${CYAN}${name}${NC}"
  fi

  # Size annotation
  if $SHOW_SIZE && [[ -n "${SIZE_MAP[$name]}" ]]; then
    extra="${GREY} (${SIZE_MAP[$name]})${NC}"
  fi

  # Shared dependency marker
  local dep_count=0
  if [[ -n "${USES_MAP[$name]}" ]]; then
    dep_count="${#${(s: :)USES_MAP[$name]}}"
  fi
  if (( depth > 0 && dep_count > 1 )); then
    extra="${extra}${GREY} ← shared by ${dep_count} packages${NC}"
  fi

  # Already visited marker
  if [[ -n "${SEEN[$name]}" ]] && (( depth > 0 )); then
    echo "${prefix}${connector}${label}${extra} ${GREY}(↑ see above)${NC}"
    return
  fi
  SEEN[$name]=1

  echo "${prefix}${connector}${label}${extra}"

  # Get direct dependencies
  local deps_str="${DEPS_MAP[$name]}"
  local deps=("${(@s: :)deps_str}")

  # Filter to only installed deps
  local installed_deps=()
  for dep in "${deps[@]}"; do
    [[ -z "$dep" ]] && continue
    if (( ${ALL_INSTALLED[(Ie)$dep]} )); then
      installed_deps+=("$dep")
    fi
  done

  # Recurse into children
  local child_prefix="$prefix"
  if [[ -n "$connector" ]]; then
    if [[ "$is_last" == "true" ]]; then
      child_prefix="${prefix}    "
    else
      child_prefix="${prefix}│   "
    fi
  fi

  local total=${#installed_deps[@]}
  local i=0
  for dep in "${installed_deps[@]}"; do
    (( i++ ))
    if (( i == total )); then
      print_tree "$dep" "$child_prefix" "true" $(( depth + 1 ))
    else
      print_tree "$dep" "$child_prefix" "false" $(( depth + 1 ))
    fi
  done
}

print_reverse_tree() {
  local name="$1"
  local prefix="$2"
  local is_last="$3"
  local depth="$4"

  local connector=""
  if [[ -n "$prefix" || -n "$is_last" ]]; then
    if [[ "$is_last" == "true" ]]; then
      connector="└── "
    else
      connector="├── "
    fi
  fi

  local label
  if (( depth == 0 )); then
    label="${BOLD}${YELLOW}${name}${NC}"
  else
    label="${GREEN}${name}${NC}"
  fi

  if [[ -n "${SEEN[$name]}" ]] && (( depth > 0 )); then
    echo "${prefix}${connector}${label} ${GREY}(↑ see above)${NC}"
    return
  fi
  SEEN[$name]=1

  echo "${prefix}${connector}${label}"

  # Get reverse deps (who uses this?)
  local uses_str="${USES_MAP[$name]}"
  local uses=("${(@s: :)uses_str}")

  local child_prefix="$prefix"
  if [[ -n "$connector" ]]; then
    if [[ "$is_last" == "true" ]]; then
      child_prefix="${prefix}    "
    else
      child_prefix="${prefix}│   "
    fi
  fi

  local total=${#uses[@]}
  local i=0
  for user in "${uses[@]}"; do
    [[ -z "$user" ]] && continue
    (( i++ ))
    if (( i == total )); then
      print_reverse_tree "$user" "$child_prefix" "true" $(( depth + 1 ))
    else
      print_reverse_tree "$user" "$child_prefix" "false" $(( depth + 1 ))
    fi
  done
}

# --- Output -----------------------------------------------------------

echo ""

case "$MODE" in
  single)
    # Check if formula is installed
    if ! (( ${ALL_INSTALLED[(Ie)$TARGET]} )); then
      error "'$TARGET' is not installed."
      exit 1
    fi
    info "Dependency tree for ${BOLD}$TARGET${NC}"
    echo ""
    SEEN=()
    print_tree "$TARGET" "" "" 0
    ;;

  leaves)
    info "Dependency tree — top-level packages (${#LEAVES[@]} leaves, ${#ALL_INSTALLED[@]} formulae total)"
    echo ""
    for leaf in "${LEAVES[@]}"; do
      SEEN=()
      print_tree "$leaf" "" "" 0
      echo ""
    done

    if (( ${#ALL_CASKS[@]} > 0 )); then
      info "Installed casks (${#ALL_CASKS[@]}):"
      echo ""
      for cask in "${ALL_CASKS[@]}"; do
        echo "  ${YELLOW}${cask}${NC}"
      done
    fi
    ;;

  all)
    info "Dependency tree — all installed formulae (${#ALL_INSTALLED[@]})"
    echo ""
    for formula in "${ALL_INSTALLED[@]}"; do
      SEEN=()
      print_tree "$formula" "" "" 0
      echo ""
    done
    ;;

  reverse)
    # Find packages that are dependencies (not leaves)
    DEPS_ONLY=()
    for formula in "${ALL_INSTALLED[@]}"; do
      if ! (( ${LEAVES[(Ie)$formula]} )); then
        DEPS_ONLY+=("$formula")
      fi
    done

    info "Reverse dependency tree — what depends on what (${#DEPS_ONLY[@]} dependencies)"
    echo ""
    for dep in "${DEPS_ONLY[@]}"; do
      [[ -z "${USES_MAP[$dep]}" ]] && continue
      SEEN=()
      print_reverse_tree "$dep" "" "" 0
      echo ""
    done
    ;;
esac

echo ""
