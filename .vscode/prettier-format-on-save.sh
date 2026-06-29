#!/usr/bin/env bash
# Optional: format one file with workspace Prettier (same rules as format-on-save).
set -euo pipefail

file=${1:?usage: format-on-save.sh <file>}
if [[ ! -f "$file" ]]; then
  echo "Not a file: $file" >&2
  exit 1
fi

file_abs="$(realpath "$file")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Skip vendored trees at o19-env root only (not src/dev/focuz-ai/enterprise).
for skip in odoo enterprise design-themes vendor node_modules .venv; do
  if [[ "$file_abs" == "${root}/${skip}" ]] || [[ "$file_abs" == "${root}/${skip}/"* ]]; then
    exit 0
  fi
done

prettier="${root}/node_modules/.bin/prettier"
if [[ ! -x "$prettier" ]]; then
  echo "Run 'npm ci' in ${root} first." >&2
  exit 1
fi

"$prettier" --write --ignore-unknown "$file_abs"
