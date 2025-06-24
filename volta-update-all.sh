#!/usr/bin/env sh
# volta-update-all.sh - update every Volta-managed tool
#
# Flags:
#   --dry-run         Show what would change, make no installs
#   --self-update     Re-run the Volta installer first
#   --exclude a,b,c   Comma-separated list of tool names to skip
#   --help, -h        Display the help message
#
# Works with POSIX sh - no Bash-only features.

set -eu
IFS='
'  # newline

# ─── CONFIG ────────────────────────────────────────────────────────────────────
NODE_CHANNEL=lts       # change to "latest" if you prefer cutting-edge Node
DEFAULT_CHANNEL=latest # all other tools follow this channel

# ─── HELPERS ──────────────────────────────────────────────────────────────────
usage() {
  sed -n '2,10p' "$0"
  exit 1
}

contains() {  # $1 needle   $2 space-separated haystack
  for _x in $2; do
    [ "$_x" = "$1" ] && return 0
  done
  return 1
}

current_version() {  # $1 tool-name → prints "22.16.0", or "" if absent
  volta list --format=plain |
    awk -v t="$1" '
      {
        split($2, a, "@")
        if (a[1] == t) { print a[2]; exit }
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
EXCLUDES=""
OLD_IFS=$IFS
IFS=','
for _x in $EXCL; do
  [ -n "$_x" ] && EXCLUDES="$EXCLUDES $_x"
done
IFS=$OLD_IFS

# ─── COLLECT INSTALLED TOOL NAMES ─────────────────────────────────────────────
TOOLS=$(volta list all --format=plain |
  awk 'NF>=2 {print $2}' | cut -d@ -f1 | sort -u)

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

  volta install --quiet "${T}@${CHAN}"

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
