#!/usr/bin/env bash
# volta-update-all.sh - update every Volta-managed tool
#
# Flags:
#   --dry-run         Show what would change, make no installs
#   --self-update     Re-run the Volta installer first
#   --exclude a,b,c   Comma-separated list of tool names to skip
#   -h, --help        Display the help message
#
# Works with POSIX sh - no Bash-only features.

set -euo pipefail

IFS='
' # newline

# ─── CONFIG ────────────────────────────────────────────────────────────────────
NODE_CHANNEL=lts       # change to "latest" if you prefer cutting-edge Node
DEFAULT_CHANNEL=latest # all other tools follow this channel

# ─── HELPERS ──────────────────────────────────────────────────────────────────
usage() {
  sed -n '2,10p' "$0"
  exit 1
}

contains() { # $1 needle   $2 newline-separated haystack
  for _x in $2; do
    [ "$_x" = "$1" ] && return 0
  done
  return 1
}

current_version() { # $1 tool-name → prints "22.16.0", or "" if absent
  volta list --format=plain |
    awk -v t="$1" '
      {
        # The last "@" starts the version; a scoped name also begins with "@".
        i = match($2, /@[^@]*$/)
        if (i > 1 && substr($2, 1, i - 1) == t) { print substr($2, i + 1); exit }
      }'
}

# ─── FLAG PARSE ───────────────────────────────────────────────────────────────
DRY=0
SELF=0
EXCL=""
while [ $# -gt 0 ]; do
  case $1 in
  --dry-run) DRY=1 ;;
  --self-update) SELF=1 ;;
  --exclude)
    shift
    if [ $# -eq 0 ] || [ -z "$1" ] || expr "$1" : '-\{1,2\}' >/dev/null; then
      echo "error: --exclude requires an argument." >&2
      usage
    fi
    EXCL=$1
    ;;
  -h | --help) usage ;;
  *)
    echo "unknown flag: $1" >&2
    usage
    ;;
  esac
  shift
done

command -v volta >/dev/null ||
  {
    echo "Volta not found in PATH" >&2
    exit 1
  }

[ "${VOLTA_FEATURE_PNPM:-0}" = 1 ] ||
  echo "⚠️  VOLTA_FEATURE_PNPM=1 not set; pnpm will be skipped."

# ─── SELF-UPDATE VOLTA (OPTIONAL) ─────────────────────────────────────────────
if [ $SELF -eq 1 ]; then
  echo "🔄 Updating Volta itself …"
  curl -fsSL https://get.volta.sh | bash
fi

# ─── BUILD EXCLUDE LIST ───────────────────────────────────────────
EXCLUDES=$(printf '%s\n' "$EXCL" | tr ',' '\n')

# ─── COLLECT INSTALLED TOOL NAMES ─────────────────────────────────────────────
# Note: `volta list all` finds every tool Volta has registered, even if not
# installed. The loop logic correctly handles this by treating tools with no
# current version as a new installation.
TOOLS=$(volta list all --format=plain |
  awk 'NF>=2 { sub(/@[^@]*$/, "", $2); print $2 }' | sort -u)

# ─── UPGRADE LOOP ─────────────────────────────────────────────────────────────
for T in $TOOLS; do
  contains "$T" "$EXCLUDES" && {
    echo "⏩  Skipping $T"
    continue
  }

  CHAN=$DEFAULT_CHANNEL
  [ "$T" = node ] && CHAN=$NODE_CHANNEL

  BEFORE=$(current_version "$T")

  if [ $DRY -eq 1 ]; then
    echo "would run: volta install --quiet ${T}@${CHAN}"
    continue
  fi

  volta install --quiet "${T}@${CHAN}" ||
    {
      echo "❌ Failed to install $T" >&2
      exit 1
    }

  AFTER=$(current_version "$T")

  if [ -z "$BEFORE" ]; then
    echo "➕ Installed $T @ $AFTER"
  elif [ "$BEFORE" = "$AFTER" ]; then
    echo "✅ $T already at $AFTER"
  else
    echo "⬆️  Upgraded $T ${BEFORE} → ${AFTER}"
  fi
done

[ $DRY -eq 1 ] && echo "✅ Dry run complete." || echo "🎉 All done!"
