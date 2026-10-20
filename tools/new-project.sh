#!/usr/bin/env bash
# Create a new Python project from template/ with a .venv, dev tools, lock file, git repo and a first scorecard.
# Usage: tools/new-project.sh <name> [parent-dir]        Python: $PYTHON, else python3 (3.13+ recommended)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"

name="${1:-}"; parent="${2:-$PWD}"
[[ -n "$name" ]] || { echo "Usage: tools/new-project.sh <name> [parent-dir]"; exit 1; }
pkg="$(echo "${name//-/_}" | tr '[:upper:]' '[:lower:]')"
[[ "$pkg" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "Name must become a valid Python package (got '$pkg')."; exit 1; }
dest="$parent/$name"
[[ ! -e "$dest" ]] || { echo "$dest already exists."; exit 1; }

cp -R "$ROOT/template" "$dest"
cd "$dest"
mv src/app "src/$pkg"
# Rename the placeholder package everywhere it's referenced.
grep -rlw app --include='*.py' --include='*.toml' --include='*.md' . | while read -r f; do
  PKG="$pkg" perl -pi -e 's/\bapp\b/$ENV{PKG}/g' "$f"
done
perl -pi -e "s/^name = \"\Q$pkg\E\"/name = \"$name\"/; s/^\Q$pkg\E = \"\Q$pkg\E\./$name = \"$pkg./" pyproject.toml
perl -pi -e "s/.*/# $name/ if \$. == 1" README.md

echo "Creating .venv and installing dev tools..."
"$PY" -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -e '.[dev]'
.venv/bin/pip freeze --exclude-editable > requirements.lock

git init -q -b main
git add -A
git commit -q -m "Start $name from python-pillars template"

echo; echo "First scorecard:"
scripts/check.sh || true
echo; echo "Project ready at $dest"
