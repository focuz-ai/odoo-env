#!/usr/bin/env bash
# Run Prettier on a single saved file (Run on Save hook). Skips vendored trees.
set -euo pipefail

file=${1:?missing file argument}

case "$file" in
  *"/odoo/"* | *"/enterprise/"* | *"/design-themes/"* | *"/vendor/"* | *"/node_modules/"* | *"/.venv/"*)
    exit 0
    ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prettier="${root}/node_modules/.bin/prettier"

if [[ ! -x "$prettier" ]]; then
    echo "Run 'npm ci' in ${root} to enable Prettier format-on-save." >&2
    exit 0
fi

"$prettier" --write --ignore-unknown "$file"
