#!/usr/bin/env bash
set -euo pipefail

# Safe dry-run-by-default rollback helper for Horse and Rider's Companion.
# Nothing is executed against production unless BOTH --execute and
# --confirm-production are explicitly passed by the project owner.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROJECT_ID="horse-and-riders-compani-d2bd4"
SITE_ID="horse-and-riders-compani-d2bd4"
BASELINE_COMMIT="d1d6c77c3bf5d22fb93d91e7bb019835d985558e"
COMPONENT=""
HOSTING_VERSION=""
SOURCE_CHANNEL=""
EXECUTE=false
CONFIRM_PRODUCTION=false

usage() {
  cat <<'EOF'
Usage: rollback_helper.sh --component <rules|functions|hosting|all> [options]

Options:
  --component <name>         Target to roll back: rules, functions, hosting, or all
  --project <id>             Firebase project ID (default: horse-and-riders-compani-d2bd4)
  --site <id>                Firebase Hosting site ID (default: horse-and-riders-compani-d2bd4)
  --baseline-commit <sha>    Git commit for Functions / Hosting source rollback
                             (default: d1d6c77c3bf5d22fb93d91e7bb019835d985558e)
  --hosting-version <id>     Prior Hosting version ID (from Firebase Console or pre-deploy check)
  --source-channel <name>    Alternative: pre-deploy Hosting preview channel to clone to live
  --execute                  Actually run Firebase CLI rollback commands (default: dry-run)
  --confirm-production       Required alongside --execute to confirm production writes
  -h, --help                 Show this help message

Examples (dry-run):
  ./tool/rollback/rollback_helper.sh --component rules
  ./tool/rollback/rollback_helper.sh --component functions
  ./tool/rollback/rollback_helper.sh --component hosting --hosting-version VERSION_ID
  ./tool/rollback/rollback_helper.sh --component all --hosting-version VERSION_ID
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --component) COMPONENT="${2:-}"; shift 2 ;;
    --project) PROJECT_ID="${2:-}"; shift 2 ;;
    --site) SITE_ID="${2:-}"; shift 2 ;;
    --baseline-commit) BASELINE_COMMIT="${2:-}"; shift 2 ;;
    --hosting-version) HOSTING_VERSION="${2:-}"; shift 2 ;;
    --source-channel) SOURCE_CHANNEL="${2:-}"; shift 2 ;;
    --execute) EXECUTE=true; shift ;;
    --confirm-production) CONFIRM_PRODUCTION=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

case "$COMPONENT" in
  rules|functions|hosting|all) ;;
  *) echo "Missing or invalid --component: '$COMPONENT'" >&2; usage; exit 2 ;;
esac

FIREBASE_BIN="firebase"
if ! command -v "$FIREBASE_BIN" >/dev/null 2>&1; then
  if [[ -x "$HOME/.cache/firebase/tools/bin/firebase" ]]; then
    FIREBASE_BIN="$HOME/.cache/firebase/tools/bin/firebase"
  fi
fi

run_or_print() {
  if [[ "$EXECUTE" == true && "$CONFIRM_PRODUCTION" == true ]]; then
    echo "+ $*"
    "$@"
  else
    echo "[DRY-RUN] $*"
  fi
}

rollback_hosting() {
  if [[ -n "$HOSTING_VERSION" ]]; then
    run_or_print "$FIREBASE_BIN" hosting:clone \
      "${SITE_ID}@${HOSTING_VERSION}" "${SITE_ID}:live" --project "$PROJECT_ID"
  elif [[ -n "$SOURCE_CHANNEL" ]]; then
    run_or_print "$FIREBASE_BIN" hosting:clone \
      "${SITE_ID}:${SOURCE_CHANNEL}" "${SITE_ID}:live" --project "$PROJECT_ID"
  else
    echo "Hosting rollback requires --hosting-version <id>, --source-channel <name>," >&2
    echo "or restoring the previous release in Firebase Console -> Hosting -> Release history." >&2
    return 1
  fi
}

rollback_rules() {
  if [[ ! -f "$SCRIPT_DIR/firestore.rules" || ! -f "$SCRIPT_DIR/storage.rules" || ! -f "$SCRIPT_DIR/firebase.rollback.json" ]]; then
    echo "Rollback rules artifacts missing under $SCRIPT_DIR" >&2
    return 1
  fi
  (
    cd "$SCRIPT_DIR"
    run_or_print "$FIREBASE_BIN" deploy \
      -c "firebase.rollback.json" \
      --project "$PROJECT_ID" \
      --only firestore:rules,storage
  )
}

rollback_functions() {
  if ! git -C "$REPO_ROOT" cat-file -e "${BASELINE_COMMIT}^{commit}" 2>/dev/null; then
    echo "Baseline commit not found in git: $BASELINE_COMMIT" >&2
    return 1
  fi
  if [[ "$EXECUTE" != true || "$CONFIRM_PRODUCTION" != true ]]; then
    echo "[DRY-RUN] git -C \"$REPO_ROOT\" worktree add --detach <tmp-worktree> \"$BASELINE_COMMIT\""
    echo "[DRY-RUN] npm --prefix <tmp-worktree>/functions ci"
    echo "[DRY-RUN] \"$FIREBASE_BIN\" deploy --project \"$PROJECT_ID\" --only functions (from <tmp-worktree>)"
    echo "[DRY-RUN] git -C \"$REPO_ROOT\" worktree remove --force <tmp-worktree>"
    return 0
  fi

  local worktree_dir
  worktree_dir="$(mktemp -d "${TMPDIR:-/tmp}/hrc-functions-rollback.XXXXXX")"
  cleanup_worktree() {
    git -C "$REPO_ROOT" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || rm -rf "$worktree_dir"
  }
  trap cleanup_worktree EXIT

  git -C "$REPO_ROOT" worktree add --detach "$worktree_dir" "$BASELINE_COMMIT"
  npm --prefix "$worktree_dir/functions" ci
  (
    cd "$worktree_dir"
    "$FIREBASE_BIN" deploy --project "$PROJECT_ID" --only functions
  )
}

if [[ "$EXECUTE" == true && "$CONFIRM_PRODUCTION" != true ]]; then
  echo "Refusing --execute without --confirm-production." >&2
  exit 2
fi

if [[ "$EXECUTE" == false ]]; then
  echo "Mode: DRY-RUN (pass --execute --confirm-production to modify production '$PROJECT_ID')"
fi

# Note reverse order when rolling back all: Hosting -> Functions -> Rules
case "$COMPONENT" in
  hosting)
    rollback_hosting
    ;;
  functions)
    rollback_functions
    ;;
  rules)
    rollback_rules
    ;;
  all)
    rollback_hosting
    rollback_functions
    rollback_rules
    ;;
esac
