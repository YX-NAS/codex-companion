#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
"$ROOT/scripts/package_app.sh"
TARGET="$HOME/Applications/Codex Companion.app"
pkill -x CodexCompanion || true
mkdir -p "$HOME/Applications"
rm -rf "$TARGET"
cp -R "$ROOT/dist/CodexCompanion.app" "$TARGET"
open -n "$TARGET"
echo "Installed and launched $TARGET"
